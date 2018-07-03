pragma solidity ^0.4.19;

import './ToriToken.sol';

contract Crowdsale {
	using SafeMath for uint256;

	MintableToken public token;
	address public wallet;
	uint256 public rate;
	uint256 public weiRaised;

	event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

	function Crowdsale(address _token, address _wallet) public {
		require(_token != address(0));
		require(_wallet != address(0));
		token = MintableToken(_token);		
		require(token.rate() > 0);

		rate 	= token.rate();
		wallet 	= _wallet;
	}

	function () external payable {
		buyTokens(msg.sender);
	}

	function buyTokens(address _beneficiary) public payable {

		uint256 weiAmount = msg.value;
		_preValidatePurchase(_beneficiary, weiAmount);

		uint256 tokenAmount = _getTokenAmount(weiAmount);

		weiRaised = weiRaised.add(weiAmount);

		_processPurchase(_beneficiary, weiAmount, tokenAmount);
		//token.transferFromWallet(wallet, _beneficiary, tokenAmount);
		//token.transferFromWallet.value(msg.value)(wallet, _beneficiary, tokenAmount);
		
		emit TokenPurchase(wallet, _beneficiary, weiAmount, tokenAmount);

		_updatePurchasingState(_beneficiary, weiAmount);

		_forwardFunds();
		_postValidatePurchase(_beneficiary, weiAmount);
	}

	function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal {
		require(_beneficiary != address(0));
		require(_weiAmount != 0);
	}

	function _postValidatePurchase(address _beneficiary, uint256 _weiAmount) internal {

	}

	function _deliverTokens(address _beneficiary, uint256 _weiAmount, uint256 _tokenAmount) internal {
		token.transferFromWallet(wallet, _beneficiary, _weiAmount, _tokenAmount);
	}

	function _processPurchase(address _beneficiary, uint256 _weiAmount, uint256 _tokenAmount) internal {
		_deliverTokens(_beneficiary, _weiAmount, _tokenAmount);
	}

	function _updatePurchasingState(address _beneficiary, uint256 _weiAmount) internal {

	}

	function _getTokenAmount(uint256 _weiAmount) internal view returns (uint256) {
		return _weiAmount.mul(rate);
	}

	function _forwardFunds() internal {
		wallet.transfer(msg.value);
	}
}

contract MintedCrowdsale is Crowdsale {

	function _deliverTokens(address _beneficiary, uint256 _tokenAmount) internal {
		require(MintableToken(token).mint(_beneficiary, _tokenAmount));
	}
}

contract TimedCrowdsale is Crowdsale {
	using SafeMath for uint256;

	uint256 public openingTime;
	uint256 public closingTime;

	modifier onlyWhileOpen {
		require(now >= openingTime && now <= closingTime);
		_;
	}

	function TimedCrowdsale(uint256 _openingTime, uint256 _closingTime) public {
		require(_openingTime >= now);
		require(_closingTime >= _openingTime);

		openingTime = _openingTime;
		closingTime = _closingTime;
	}

	function hasClosed() public view returns (bool) {
		return now > closingTime;
	}

	function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal onlyWhileOpen {
		super._preValidatePurchase(_beneficiary, _weiAmount);
	}
}

contract NCoinCrowdsale is TimedCrowdsale, MintedCrowdsale {
	function NCoinCrowdsale (uint256 _openingTime, uint256 _closingTime, MintableToken _token, address _wallet) public Crowdsale(_token, _wallet) TimedCrowdsale(_openingTime, _closingTime) {

	}
}
