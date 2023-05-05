// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import { StringUtils } from "../libraries/StringUtils.sol";

interface Turnstile {
    function register(address) external returns (uint256);
}

contract Items is ERC1155, Ownable, ERC1155Supply {

    // CSR for Canto
    Turnstile turnstile = Turnstile(0xEcf044C5B4b867CFda001101c617eCd347095B44);

    constructor() ERC1155("") {
        turnstile.register(tx.origin);
    }

    string private _uri;
    mapping (uint256 => uint256) prices;

    function setURI(string memory newuri) public onlyOwner {
        _uri = newuri;
    }

    //_price in wei
    function setPrices(uint256 _id, uint256 _price) public onlyOwner {
        prices[_id] = _price;
    }

    function mint(uint256 id, uint256 amount) public payable {
        require(msg.value >= amount*(prices[id]), "Not enough value sent");

        _mint(msg.sender, id, amount, "");
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        internal
        override(ERC1155, ERC1155Supply)
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function uri(uint256 tokenId) public view virtual override returns (string memory) {
        string memory token = StringUtils.toString(tokenId);
        return bytes(_uri).length > 0 ? string(abi.encodePacked(_uri, token, ".json")) : "";
    }

    // Function to receive Canto. msg.data must be empty
    receive() external payable {}

    // Fallback function is called when msg.data is not empty
    fallback() external payable {}
}