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
interface BridgeManager {
    function lockOne(uint256 amount, address recipient) external;
}

contract ProxyONE is OFTCore {
    using SafeERC20 for IERC20;

    address public multisig;
    address public bridgeManager;

    constructor(
        address _lzEndpoint,
        address _multisig,
        address _bridgeManager
    ) OFTCore(_lzEndpoint) {
        multisig = _multisig;
        bridgeManager = _bridgeManager;
    }

    function circulatingSupply() public view virtual override returns (uint) {
        unchecked {
            return bridgeManager.balance;
        }
    }

    function _debitFrom(
        address _from,
        uint16,
        bytes memory,
        uint _amount
    ) internal virtual override {
        require(_from == _msgSender(), "ProxyOFT: owner is not send caller");
        // require(msg.value >= _amount, "ProxyOFT: not enough ONE sent");
        BridgeManager(bridgeManager).lockOne(_amount, _from);

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
                0x1486abd6,
                _amount,
                _toAddress,
                // instead of src chain txn hash, using this as unique receiptId
                keccak256(abi.encodePacked(_amount, _toAddress, blockhash(block.number - 1)))
            )
        );
    }
}
