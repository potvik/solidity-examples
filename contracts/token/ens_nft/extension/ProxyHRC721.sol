// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ONFT721Core.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";

interface MintableNFT {
    function safeMint(address to, uint256 tokenId) external;
}

// NOTE: this ONFT contract has no public minting logic.
// must implement your own minting logic in child classes
contract ONFT721 is ONFT721Core {
    using ERC165Checker for address;

    IERC721 public immutable token;

    constructor(address _lzEndpoint, address _proxyToken) ONFT721Core(_lzEndpoint) {
        token = IERC721(_proxyToken);
    }

    function _debitFrom(
        address _from,
        uint16,
        bytes memory,
        uint _tokenId
    ) internal virtual override {
        require(_from == _msgSender(), "ProxyOFT: owner is not send caller");
        ERC721Burnable(address(token)).burn(_tokenId);
    }

    function _creditTo(
        uint16,
        address _toAddress,
        uint _tokenId
    ) internal virtual override {
        MintableNFT(address(token)).safeMint(_toAddress, _tokenId);
    }
}
