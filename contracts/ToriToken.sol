pragma solidity ^0.4.19;

library SafeMath {
	function mul(uint256 a, uint256 b) internal pure returns (uint256) {
		if (a == 0) {
			return 0;
		}

		uint256 c = a * b;
		require(c / a == b);
		return c;
	}

	function div(uint256 a, uint256 b) internal pure returns (uint256) {
		uint256 c = a / b;
		return c;
	}

	function sub(uint256 a, uint256 b) internal pure returns (uint256) {
		require(b <= a);
		return a - b;
	}

	function add(uint256 a, uint256 b) internal pure returns (uint256) {
		uint256 c = a + b;
		require(c >= a);
		return c;
	}
}

contract ERC20Basic {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract BasicToken is ERC20Basic {
	using SafeMath for uint256;

    string public name;
    string public symbol;
    uint256 public decimals;
    uint256 public rate;
	mapping(address => uint256) balances;
	uint256 totalSupply_;

	function totalSupply() public view returns (uint256) {
		return totalSupply_;
	}

	function transfer(address _to, uint256 _value) public returns (bool) {
		require(_to != address(0));
		require(_value <= balances[msg.sender]);

		balances[msg.sender]    = balances[msg.sender].sub(_value);
		balances[_to]           = balances[_to].add(_value);
		emit Transfer(msg.sender, _to, _value);
		return true;
	}

	function balanceOf(address _owner) public view returns (uint256 balance) {
		return balances[_owner];
	}
}

contract StandardToken is ERC20, BasicToken {
    using SafeMath for uint256;
    
	mapping (address => mapping (address => uint256)) internal allowed;
	
	function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
		require(_to != address(0));
		require(_value <= balances[_from]);
		require(_value <= allowed[_from][msg.sender]);

		balances[_from]               = balances[_from].sub(_value);
		balances[_to]                 = balances[_to].add(_value);
		allowed[_from][msg.sender]    = allowed[_from][msg.sender].sub(_value);
		emit Transfer(_from, _to, _value);
		return true;
	}
	
	function approve(address _spender, uint256 _value) public returns (bool) {
		allowed[msg.sender][_spender] = _value;
		emit Approval(msg.sender, _spender, _value);
		return true;
	}

	function allowance(address _owner, address _spender) public view returns (uint256) {
		return allowed[_owner][_spender];
	}

	function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
		allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
		emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
		return true;
	}

	function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
		uint oldValue = allowed[msg.sender][_spender];

		if (_subtractedValue > oldValue) {
			allowed[msg.sender][_spender] = 0;
		}
		else {
			allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
		}

		emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
		return true;
	}
}

contract UpgradeAgent {
	uint public originalSupply;
  
	function isUpgradeAgent() public pure returns (bool) {
		return true;
	}

	function upgradeFrom(address _from, uint256 _value) public;
}

contract UpgradeableToken is StandardToken {
	using SafeMath for uint256;

	address public upgradeMaster;
	UpgradeAgent public upgradeAgent;
	uint256 public totalUpgraded;

	enum UpgradeState {
		Unknown, 
		NotAllowed, 
		WaitingForAgent, 
		ReadyToUpgrade, 
		Upgrading
	}

	event Upgrade(address indexed _from, address indexed _to, uint256 _value);
	event UpgradeAgentSet(address agent);

	function UpgradeableToken(address _upgradeMaster) public {
		upgradeMaster = _upgradeMaster;
	}

	function upgrade(uint256 value) public {
		UpgradeState state = getUpgradeState();

		if(!(state == UpgradeState.ReadyToUpgrade || state == UpgradeState.Upgrading)) {
			revert();
		}

		if (value == 0) 
			revert();

		balances[msg.sender]  = balances[msg.sender].sub(value);
		totalSupply_          = totalSupply_.sub(value);
		totalUpgraded         = totalUpgraded.add(value);

		upgradeAgent.upgradeFrom(msg.sender, value);
		emit Upgrade(msg.sender, upgradeAgent, value);
	}

	function setUpgradeAgent(address agent) external {
		if(!canUpgrade()) {
			revert();
		}

		if (agent == address(0)) 
			revert();
      
		if (msg.sender != upgradeMaster) 
			revert();
      
		if (getUpgradeState() == UpgradeState.Upgrading) 
			revert();

		upgradeAgent = UpgradeAgent(agent);

		if(!upgradeAgent.isUpgradeAgent()) 
			revert();
      
		if (upgradeAgent.originalSupply() != totalSupply_) 
			revert();

		emit UpgradeAgentSet(upgradeAgent);
	}

	function getUpgradeState() public view returns(UpgradeState) {
		if(!canUpgrade()) 
			return UpgradeState.NotAllowed;
		else if(address(upgradeAgent) == address(0)) 
			return UpgradeState.WaitingForAgent;
		else if(totalUpgraded == 0) 
			return UpgradeState.ReadyToUpgrade;
    
		return UpgradeState.Upgrading;
	}

	function setUpgradeMaster(address master) public {
		if (master == address(0)) 
			revert();
		if (msg.sender != upgradeMaster) 
			revert();

		upgradeMaster = master;
	}

	function canUpgrade() public pure returns (bool) {
		return true;
	}
}

contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function Ownable() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

contract Pausable is Ownable {
	bool private paused_ = false;

	event Pause();
	event Unpause();

	modifier whenNotPaused() {
		require(!paused_);
		_;
	}

	modifier whenPaused() {
		require(paused_);
		_;
	}

	function pause() onlyOwner whenNotPaused public {
		paused_ = true;
		emit Pause();
	}

	function unpause() onlyOwner whenPaused public {
		paused_ = false;
		emit Unpause();
	}
}

contract PausableToken is StandardToken, Pausable {
	function transfer(address _to, uint256 _value) public whenNotPaused returns (bool) {
		return super.transfer(_to, _value);
	}

	function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool) {
		return super.transferFrom(_from, _to, _value);
	}

	function approve(address _spender, uint256 _value) public whenNotPaused returns (bool) {
		return super.approve(_spender, _value);
	}

	function increaseApproval(address _spender, uint _addedValue) public whenNotPaused returns (bool success) {
		return super.increaseApproval(_spender, _addedValue);
	}

	function decreaseApproval(address _spender, uint _subtractedValue) public whenNotPaused returns (bool success) {
		return super.decreaseApproval(_spender, _subtractedValue);
	}
}

contract MintableToken is PausableToken {
    bool public mintingFinished = false;

    event Mint(address indexed to, uint256 amount);
    event MintFinished();

    modifier canMint() {
        require(!mintingFinished);
        _;
    }

    function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
        totalSupply_  = totalSupply_.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Mint(_to, _amount);
        emit Transfer(address(0), _to, _amount);
        return true;
    }
    
    function transferFromWallet(address _fromWallet, address _to, uint256 _weiValue, uint256 _tokenValue) external returns (bool) {
	    require(_fromWallet != address(0));
		require(_to != address(0));
		require(_weiValue > 0);
		require(_tokenValue > 0);
		require(_tokenValue <= balances[_fromWallet]);
		require(_tokenValue == _weiValue.mul(rate));

		balances[_fromWallet]         = balances[_fromWallet].sub(_tokenValue);
		balances[_to]                 = balances[_to].add(_tokenValue);
		emit Transfer(_fromWallet, _to, _tokenValue);
		return true;
	}
	
// 	function transferFromWallet(address _fromWallet, address _to, uint256 _tokenValue) external payable returns (bool) {
// 	    require(_fromWallet != address(0));
// 		require(_to != address(0));
// 		require(msg.value > 0);
// 		require(_tokenValue > 0);
// 		require(_tokenValue <= balances[_fromWallet]);
// 		require(_tokenValue == msg.value.mul(rate));

// 		balances[_fromWallet]         = balances[_fromWallet].sub(_tokenValue);
// 		balances[_to]                 = balances[_to].add(_tokenValue);
// 		emit Transfer(_fromWallet, _to, _tokenValue);
// 		return true;
// 	}

    function finishMinting() onlyOwner canMint public returns (bool) {
        mintingFinished = true;
        emit MintFinished();
        return true;
    }
}

contract ToriToken is MintableToken {

    function ToriToken() public {
        name        = "Tori Token";
        symbol      = "TORI";
        decimals    = 18;
        rate        = 1000;
    }
}
