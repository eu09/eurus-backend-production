pragma solidity >=0.6.0 <0.8.0;

import "../basic/IWEUN.sol";
import "../../utils/maths/SafeMath.sol";

contract WrappedEUN is IWEUN {
    using SafeMath for uint256;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    function name() external pure returns (string memory) {
        return "Wrapped EUN";
    }

    function symbol() external pure returns (string memory) {
        return "WEUN";
    }

    function decimals() external pure returns (uint8) {
        return 18;
    }

    function totalSupply() external view override returns (uint256) {
        return payable(address(this)).balance;
    }

    function balanceOf(address account) external view override returns (uint256) {
        return _balances[account];
    }

    function allowance(address owner, address spender) external view override returns (uint256) {
        return _allowances[owner][spender];
    }

    receive() external payable {
        _balances[msg.sender] += msg.value;
        emit Transfer(address(0), msg.sender, msg.value);
    }

    function deposit() external payable override {
        _balances[msg.sender] += msg.value;
        emit Transfer(address(0), msg.sender, msg.value);
    }

    function depositTo(address recipient) external payable override {
        if (recipient == address(0)) {
            // Treat deposit EUN to 0 = wrap and give it to myself
            _balances[msg.sender] += msg.value;
            emit Transfer(address(0), msg.sender, msg.value);
        } else {
            _balances[recipient] += msg.value;
            emit Transfer(address(0), recipient, msg.value);
        }
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        require(_balances[msg.sender] >= amount, "Amount exceeds balance");

        if (recipient == address(0)) {
            // Transfer token to 0 => burn token => withdraw
            _balances[msg.sender] -= amount;
            (bool success, ) = msg.sender.call{value: amount}("");
            require(success, "Transfer failed");
            emit Transfer(msg.sender, address(0), amount);
        } else {
            _balances[msg.sender] -= amount;
            _balances[recipient] += amount;
            emit Transfer(msg.sender, recipient, amount);
        }

        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        require(_balances[sender] >= amount, "Amount exceeds balance");

        if (sender != msg.sender) {
            uint256 allowed = _allowances[sender][msg.sender];

            // Update allowance if it is not set to no limit
            if (allowed != uint256(-1)) {
                require(allowed >= amount, "Amount exceeds allowance");

                uint256 newAllowed = allowed - amount;
                _allowances[sender][msg.sender] = newAllowed;
                emit Approval(sender, msg.sender, newAllowed);
            }
        }

        if (recipient == address(0)) {
            // Transfer token of sender to 0 => burn token => withdraw to msg.sender
            // This is same as WETH10
            // If sender is msg.sender itself the action should behave same as transfer(address,uint256)
            _balances[sender] -= amount;
            (bool success, ) = msg.sender.call{value: amount}("");
            require(success, "Transfer failed");
            emit Transfer(sender, address(0), amount);
        } else {
            _balances[sender] -= amount;
            _balances[recipient] += amount;
            emit Transfer(sender, recipient, amount);
        }

        return true;
    }

    function withdraw(uint256 amount) external override {
        require(_balances[msg.sender] >= amount, "Amount exceeds balance");

        // Burn token and return EUN to me
        _balances[msg.sender] -= amount;
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");
        emit Transfer(msg.sender, address(0), amount);
    }

    function withdrawTo(address payable recipient, uint256 amount) external override {
        require(_balances[msg.sender] >= amount, "Amount exceeds balance");

        _balances[msg.sender] -= amount;

        if (recipient == address(0)) {
            // Withdraw to 0 => burn token => return EUN to me, same as withdraw(uint256)
            // This is not handled in WETH10, add this to prevent EUN lost permanently
            (bool success, ) = msg.sender.call{value: amount}("");
            require(success, "Transfer failed");
        } else {
            // Withdraw to other address => burn token and give EUN to someone
            (bool success, ) = recipient.call{value: amount}("");
            require(success, "Transfer failed");
        }

        emit Transfer(msg.sender, address(0), amount);
    }

    function withdrawFrom(address sender, address payable recipient, uint256 amount) external override {
        require(_balances[sender] >= amount, "Amount exceeds balance");

        if (sender != msg.sender) {
            uint256 allowed = _allowances[sender][msg.sender];

            // Update allowance if it is not set to no limit
            if (allowed != uint256(-1)) {
                require(allowed >= amount, "Amount exceeds allowance");

                uint256 newAllowed = allowed - amount;
                _allowances[sender][msg.sender] = newAllowed;
                emit Approval(sender, msg.sender, newAllowed);
            }
        }

        _balances[sender] -= amount;

        if (recipient == address(0)) {
            // Withdraw token of sender to 0 => burn token => withdraw to msg.sender
            // If sender is msg.sender itself the action should behave same as withdraw(uint256)
            (bool success, ) = msg.sender.call{value: amount}("");
            require(success, "Transfer failed");
        } else {
            // Withdraw to other address => burn token and give EUN to someone
            (bool success, ) = recipient.call{value: amount}("");
            require(success, "Transfer failed");
        }

        emit Transfer(sender, address(0), amount);
    }

    function approve(address spender, uint256 amount) external override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }
}
