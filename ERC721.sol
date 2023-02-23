// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "./Cantoverse.sol";

contract MyToken is ERC721, ERC2981, Ownable {

    uint256 public price;
    uint256 public totalSupply;
    uint256 tokenId;
    string public uri;
    bool public mintActive;

    constructor(uint256 _totalSupply) ERC721("CantoMaze", "CTM") {
        totalSupply = _totalSupply;
        tokenId = 1;
        mintActive = false;
    }

    /**
     * @dev Mints an NFT.
     *
     * Requirements:
     *
     * - value sent iqual or more than price
     * - tokenId less or equal totalSupply
     */
    function safeMint() public payable {
        require(msg.value >= price , "Not enough value sent");
        require(tokenId <= totalSupply, "All collection has been minted");
        require(mintActive, "Minted is paused");
        tokenId++;
        _safeMint(msg.sender, tokenId-1);
    }

    /**
     * @dev Sets the royalty information that all ids in this contract will default to.
     *
     * Requirements:
     *
     * - `receiver` cannot be the zero address.
     * - `feeNumerator` cannot be greater than the fee denominator, if it is 1000 -> 10%.
     */
    function setFeeNum(address receiver, uint96 feeNumerator) public onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    /**
     * @dev Sets NFT price
     */
    function setPrice(uint256 _price) public onlyOwner {
        price = _price;
    }

    /**
     * @dev Sets URI
     */
    function setURI(string memory _uri) public onlyOwner {
        uri = _uri;
    }

    /**
     * @dev Sets mint state
     */
    function setMintState(bool _mintActive) public onlyOwner {
        mintActive = _mintActive;
    }

    /**
     * @dev Deploy Cantoverse
     */
    function deploy() external onlyOwner returns (address) {
        Cantoverse cantoverse = new Cantoverse();

        return address(cantoverse);
    }

    // The following functions are overrides required by Solidity.

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return uri;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encode(baseURI)) : "";
    }
}