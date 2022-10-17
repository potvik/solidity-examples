// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../OFTCore.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

interface MultisigWallet {
    function submitTransaction(
        address destination,
        uint value,
        bytes memory data
    ) external returns (uint transactionId);
}

interface BurnableToken {
    function burnFrom(
        address from,
        uint256 amount
    ) external;
}

contract ProxyHRC20 is OFTCore {
    using SafeERC20 for IERC20;

    IERC20 public immutable token;

    address public multisig;
    address public bridgeManager;

    constructor(
        address _lzEndpoint,
        address _proxyToken,
        address _multisig,
        address _bridgeManager
    ) OFTCore(_lzEndpoint) {
        token = IERC20(_proxyToken);
        multisig = _multisig;
        bridgeManager = _bridgeManager;
    }

    function circulatingSupply() public view virtual override returns (uint) {
        unchecked {
            return token.totalSupply() - token.balanceOf(address(this));
        }
    }

    function _debitFrom(
        address _from,
        uint16,
        bytes memory,
        uint _amount
    ) internal virtual override {
        require(_from == _msgSender(), "ProxyOFT: owner is not send caller");
        BurnableToken(address(token)).burnFrom(_from, _amount);
    }

    function _creditTo(
        uint16,
        address _toAddress,
        uint _amount
    ) internal virtual override {
        MultisigWallet(multisig).submitTransaction(
            bridgeManager,
            0,
            abi.encodeWithSelector(
                0xf633be1e,
                token,
                _amount,
                _toAddress,
                // instead of src chain txn hash, using this as unique receiptId
                keccak256(abi.encodePacked(_amount, _toAddress, blockhash(block.number - 1)))
            )
        );
    }
}
