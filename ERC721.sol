// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";


contract CantoMaze is ERC721, ERC2981, Ownable {

    uint256 public price;
    uint256 public totalSupply;
    uint256 tokenId;
    string public uri;
    bool public mintActive;

    mapping(address => bool) public owners;

    mapping(address => bool) public accessWallets;

    mapping(address => address[]) public ownerAccessWallets;

    mapping(address => bool) public minted;

    constructor(uint256 _totalSupply) ERC721("CantoMaze", "CTM") {
        totalSupply = _totalSupply;
        tokenId = 1;
        mintActive = false;
    }

    function giveAccess(address addr) public {
        require(owners[msg.sender], "you are not an owner");
        require(ownerAccessWallets[msg.sender].length < 5, "You have already given access to the maximum wallets");

        ownerAccessWallets[msg.sender].push(addr);
        accessWallets[addr] = true;
    }

    function remmoveAccess(address addr) public {
        require(owners[msg.sender], "you are not an owner");
        require(ownerAccessWallets[msg.sender].length > 0, "You have no address to remove access");
        require(checkOwnerAndAccessAddres(msg.sender, addr), "You did not give access to this wallet");

        accessWallets[addr] = false;
        removeAddress(msg.sender, addr);
    }

    function checkAccess() public view returns (bool){
        return accessWallets[msg.sender];
    }

    function removeAddress(address owner, address addr) private {
        for (uint256 i = 0; i < ownerAccessWallets[owner].length; i++)
        {
            if(ownerAccessWallets[owner][i] == addr)
            {
                ownerAccessWallets[owner][i] = ownerAccessWallets[owner][ownerAccessWallets[owner].length - 1];
                ownerAccessWallets[owner].pop();
            }
        }
    }

    function checkOwnerAndAccessAddres(address owner, address addr) public view returns (bool val){
        for(uint256 i = 0; i < ownerAccessWallets[owner].length; i++){
            if(ownerAccessWallets[owner][i] == addr){
                return true;
            }
        }

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
        require(!minted[msg.sender], "Already minted");
        require(mintActive, "Minted is paused");
        tokenId++;
        minted[msg.sender] = true;
        owners[msg.sender] = true;
        accessWallets[msg.sender] = true;
        _safeMint(msg.sender, tokenId-1);
    }

    /**
     * @dev Mints 55 NFTs for the team and giveaways.
     */
    function teamMint() public payable onlyOwner {
        require(tokenId + 54 <= totalSupply, "All collection has been minted");
        require(!minted[msg.sender], "Already minted");
        minted[msg.sender] = true;
        owners[msg.sender] = true;
        accessWallets[msg.sender] = true;
        for(int i = 0; i < 55; i++){
            tokenId++;
            _safeMint(msg.sender, tokenId-1);
        }
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

    
    function tokenURI(uint256 id) public view virtual override(ERC721) returns (string memory) {
        _requireMinted(id);

        return bytes(uri).length > 0 ? uri : "";
    }

    /**
     * @dev Override function from ERC721
    */
    function safeTransferFrom(
        address from,
        address to,
        uint256 _tokenId,
        bytes memory data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), _tokenId), "ERC721: caller is not token owner or approved");

        for (uint256 i = 0; i < ownerAccessWallets[from].length; i++){
            accessWallets[ownerAccessWallets[from][i]] = false;
        }

        ownerAccessWallets[from] = new address[](4);

        owners[from] = false;
        accessWallets[from] = false;

        owners[to] = true;
        accessWallets[to] = true;

        _safeTransfer(from, to, tokenId, data);
    }
}