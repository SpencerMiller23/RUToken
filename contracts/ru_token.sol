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
     * Price required to mint a token in ETH
     */
    uint public tokenPrice;

    uint private totalSupplys;

    mapping(address => uint256) private accountBalances;
    mapping(address => mapping(address => uint256)) private accountAllowances;

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
        return totalSupplys;
    }

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) public view override returns (uint256) {
        return accountBalances[account];
    }


    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external override returns (bool) {
        address caller = msg.sender;
        bool succeeded = transferHelper(caller, recipient, amount);

        if (succeeded) {
            emit Transfer(caller, recipient, amount);
        }
        return succeeded;
    }

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view override returns (uint256) {
        return accountAllowances[owner][spender];
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
        address caller = msg.sender;
        bool succeeded = true;
        //@TODO do we need to confirm that the caller even has `amount` tokens?


        // as suggested, we first reduce `spender`'s allowance to 0...
        succeeded = setAllowance(caller, spender, 0);
        if (!succeeded) {
            return false;
        }

        // ... and only *now* set the spender's allowance to `amount` of the caller's tokens
        succeeded = setAllowance(caller, spender, amount);
        if (!succeeded) {
            return false;
        }

        emit Approval(caller, spender, amount);
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
        // caller=spender uses sender's=owner's money
        address spender = msg.sender;

        bool allowanceUsageSucceeded = spendAllowance(sender, spender, amount);
        if (!allowanceUsageSucceeded) {
            return false;
        }

        bool approvalSucceeded = this.approve(sender, amount);
        if (!approvalSucceeded) {
            return false;
        }

        emit Transfer(spender, recipient, amount);
        return (allowanceUsageSucceeded && approvalSucceeded);
    }

    /**
     * @dev Mint a new token. 
     * The total number of tokens minted is the msg value divided by tokenPrice.
     */
    function mint() public payable returns (uint) {
        uint amount = msg.value / tokenPrice;
        accountBalances[msg.sender] += 10;
        totalSupplys += 10;
        emit Transfer(address(0), msg.sender, amount);

        return amount;
    }

    /**
     * Burn `amount` tokens. The corresponding value (`tokenPrice` for each token) is sent to the caller.
     */
    function burn(uint amount) public {

        require(accountBalances[msg.sender] >= amount, "ERC20: burn amount exceeds balance");
        // require(this.transfer(address(0), amount), "ERC20: transfer failed");
        accountBalances[msg.sender] = accountBalances[msg.sender] - amount;
        totalSupplys -= amount;
        emit Transfer(msg.sender, address(0), amount);
        
        totalSupplys -= amount;


        uint256 value = amount * tokenPrice;

        // @TODO do we also store eth amounts fo each person then? Doesn't make sense

    }


    /**
    Helper function to transfer `amount` tokens from `from` to `to`
     */
    function transferHelper(address from, address to, uint256 amount) internal returns (bool) {
        //require(from != address(0), "ERC20: transfer from the zero address");
        //require(to != address(0), "ERC20: transfer to the zero address");
        if (from == address(0) || to == address(0)) {
            return false;
        }

        uint256 fromBalance = accountBalances[from];
        //require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        if (fromBalance < amount) {
            return false;
        }
        
        unchecked {
            accountBalances[from] = fromBalance - amount;
            accountBalances[to] += amount;
        }

        return true;
    }
    
    /**
    Helper function which allows spender to use `amount` of owner's tokens
     */
    function setAllowance(address owner, address spender, uint256 amount) private returns (bool) {
        if (owner == address(0) || spender == address(0)) {
            return false;
        }

        accountAllowances[owner][spender] = amount;
        return true;
    }

    /**
    Helper function which uses a `amount` of the spender's allowance to use owner's tokens
     */
    function spendAllowance(address owner, address spender, uint256 amount) private returns (bool) {
        uint256 currentSpenderAllowance = this.allowance(owner, spender);
        if (currentSpenderAllowance < amount) {
            return false;
        }

        setAllowance(owner, spender, currentSpenderAllowance - amount);

        return true;
    }


}