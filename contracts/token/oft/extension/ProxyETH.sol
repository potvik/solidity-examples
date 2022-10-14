// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../OFTCore.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract ProxyETH is OFTCore {
    using SafeERC20 for IERC20;

    constructor(address _lzEndpoint) OFTCore(_lzEndpoint) {}

    function circulatingSupply() public view virtual override returns (uint) {
        unchecked {
            return address(this).balance;
        }
    }

    function _debitFrom(
        address _from,
        uint16,
        bytes memory,
        uint _amount
    ) internal virtual override {
        require(_from == _msgSender(), "ProxyOFT: owner is not send caller");
        require(msg.value >= _amount, "ProxyOFT: not enough ether sent");
    }

    function _creditTo(
        uint16,
        address _toAddress,
        uint _amount
    ) internal virtual override {
        (bool success, ) = _toAddress.call{value: _amount}("");
        require(success, "ProxyOFT: transfer failed");
    }
}
