// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IERC20.sol";
import "../interfaces/IMultisigToken.sol";


/**
 * @dev An implementation of the ERC20 standard for a "Reichman University" Token.
 */
contract RUToken is IERC20, IERC20Metadata {
    /**
     * Maximum number of mintable tokens.
     */
    uint public maxTokens;

    /**
     * Price required to mint a token in ETH.
     */
    uint public tokenPrice;

    /**
     * Total supply of tokens.
     */
    uint private _totalSupply;

    /**
     * Keeping track of all account balances.
     */
    mapping(address => uint) private _balances;

    /**
     * Keeping track of all account allowances.
     */
    mapping(address => mapping(address => uint)) private _allowances;

    constructor(uint _tokenPrice, uint _maxTokens) {
        tokenPrice = _tokenPrice;
        maxTokens = _maxTokens;
    }

    /**
    * @dev Returns the decimals places of the token.
    */
    function decimals() external pure override returns (uint8) {
        return 18;
    }

    function name() public pure override returns (string memory) {
        return "Reichman U Token";
    }

    function symbol() public pure override returns (string memory) {
        return "RUX";
    }


    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }


    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external override returns (bool) {
        // Check if sender has at least 'amount' tokens 
        require(_balances[msg.sender] >= amount, "Insufficient funds");

        // Update account balances
        _balances[msg.sender] -= amount;
        _balances[recipient] += amount;

        emit Transfer(msg.sender, recipient, amount);

        return true;
    }

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external override returns (bool) {
        if (_balances[msg.sender] < amount) {
            return false;
        }
        // require(_balances[msg.sender] >= amount, "Insufficient funds");

        // Update account allowance
        _allowances[msg.sender][spender] = 0;
        _allowances[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        // Check if recipient is allowed to spend at least 'amount' of senders tokens 
        uint recipientAllowance = _allowances[sender][recipient];
        require(recipientAllowance >= amount, "Insufficient funds");

        // Update allowance
        _allowances[sender][recipient] = 0;
        _allowances[sender][recipient] = recipientAllowance - amount;

        // Update account balances
        _balances[sender] -= amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        return true;
    }

    /**
     * @dev Mint a new token. 
     * The total number of tokens minted is the msg value divided by tokenPrice.
     */
    function mint() public payable returns (uint) {
        uint amount = msg.value / tokenPrice;

        // Check if the total supply of tokens won't exceed 'maxToken'
        require(amount + _totalSupply <= maxTokens, "Total amount of tokens exceeds maximum allowed");

        _totalSupply += amount;
        _balances[msg.sender] += amount;

        return amount;

    }

    /**
     * Burn `amount` tokens. The corresponding value (`tokenPrice` for each token) is sent to the caller.
     */
    function burn(uint amount) public {
        // Check if the total supply of tokens won't exceed 'maxToken'
        require(_balances[msg.sender] <= amount, "Insufficient funds");

        uint currency = amount * tokenPrice;

        _totalSupply -= amount;

        payable(msg.sender).transfer(currency);
    }
}