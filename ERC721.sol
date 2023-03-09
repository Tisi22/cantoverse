// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";

interface Turnstile {
    function register(address) external returns (uint256);
}

contract CantoMaze is ERC721, ERC2981, Ownable {
    using Strings for uint256;

    uint256 public maxSupply;
    uint256 tokenId;
    string public uri;
    bool public mintActive;

    mapping(address => bool) private accessWallets;

    mapping(uint256 => address[]) private tokenIdAccessWallets;
    
    mapping(address => bool) public minted;

    // CSR for Canto
    Turnstile turnstile = Turnstile(0xEcf044C5B4b867CFda001101c617eCd347095B44);

    constructor(uint256 _maxSupply) ERC721("CantoMaze", "CTM") {
        turnstile.register(tx.origin);
        maxSupply = _maxSupply;
        tokenId = 1;
        mintActive = false;
    }

    //----- GIVE/REMOVE/CHECK ACCESS TO WALLET ADDRESS -----//

    /**
     * @dev Gives the access to a wallet address
     *
     * Requirements:
     *
     * - Msg.sender needs to be the owner of the token Id
     * - Max access wallets per token Id is 4
     * - Address does not have access before
     */
    function giveAccess(uint256 _tokenId, address addr) public {
        require(ownerOf(_tokenId) == msg.sender, "you are not the owner of the token Id");
        require(tokenIdAccessWallets[_tokenId].length < 4, "You have already given access to the maximum wallets");
        require(accessWallets[addr] == false, "The wallet address has already access");

        tokenIdAccessWallets[_tokenId].push(addr);
        accessWallets[addr] = true;
    }

    /**
     * @dev Removes the access to a wallet address
     *
     * Requirements:
     *
     * - Msg.sender needs to be the owner of the token Id
     * - The token Id needs to have given access to the wallet address before
     */
    function remmoveAccess(uint256 _tokenId, address addr) public {
        require(ownerOf(_tokenId) == msg.sender, "you are not the owner of the token Id");
        require(checkAddressPerTokenId(_tokenId, addr), "You did not give access to this wallet with this token Id");

        accessWallets[addr] = false;
        removeAddress(_tokenId, addr);
    }

    /**
     * @dev Check access to the gallary of the msg.sender
     */
    function checkAccess(uint256 _tokenId) public view returns (bool val){
        if(ownerOf(_tokenId) == msg.sender || accessWallets[msg.sender]){
            return true;
        } 
    }

    /**
     * @dev Check if the token Id gave access to a wallet address
     */
    function checkAddressPerTokenId(uint256 _tokenId, address addr) internal view returns (bool val){
        for (uint256 i = 0; i < tokenIdAccessWallets[_tokenId].length; i++){
            if(tokenIdAccessWallets[_tokenId][i] == addr){
                return true;
            }
        }
    }

    /**
     * @dev Deletes a wallet address from the array of the mapping tokenIdAccessWallets
     */
    function removeAddress(uint256 _tokenId, address addr) internal {
        uint256 index;

        for (uint256 i = 0; i < tokenIdAccessWallets[tokenId].length; i++){
            if(tokenIdAccessWallets[tokenId][i] == addr){
                index = i;
            }
        }
        tokenIdAccessWallets[_tokenId][index] = tokenIdAccessWallets[_tokenId][tokenIdAccessWallets[_tokenId].length-1];
        tokenIdAccessWallets[_tokenId].pop();
    }

    /**
     * @dev Remove the access to all the wallets of the token Id
     *
     * Requirements:
     *
     * - Msg.sender needs to be the owner of the token Id
     */
    function removeAccessForAllOfTokenId(uint256 _tokenId) public {
        require(ownerOf(_tokenId) == msg.sender, "you are not the owner of the token Id");

        for (uint256 i = 0; i < tokenIdAccessWallets[_tokenId].length; i++){
            accessWallets[tokenIdAccessWallets[_tokenId][i]] = false;
        }

        delete tokenIdAccessWallets[_tokenId];
    }

    /**
     * @dev Returns all the wallets with access for one token Id
     *
     * Requirements:
     *
     * - Msg.sender needs to be the owner of the token Id
     */
    function accessAddressPerTokenId(uint256 _tokenId)public view returns (address[] memory addresses){
        require(ownerOf(_tokenId) == msg.sender, "you are not the owner of the token Id");
        return tokenIdAccessWallets[_tokenId];
    }

    //----- END -----//

    //----- MINT FUNCTIONS -----//

    /**
     * @dev Mints an NFT.
     *
     * Requirements:
     *
     * - value sent iqual or more than price
     * - tokenId less or equal totalSupply
     */
    function safeMint() public payable {
        require(tokenId <= maxSupply, "All collection has been minted");
        require(!minted[msg.sender], "Already minted");
        require(mintActive, "Minted is paused");

        minted[msg.sender] = true;
        tokenId++;
        _safeMint(msg.sender, tokenId-1);
    }

    /**
     * @dev Mints 55 NFTs for the team and giveaways.
     */
    function teamMint() public payable onlyOwner {
        require(tokenId + 54 <= maxSupply, "All collection has been minted");
        require(!minted[msg.sender], "Already minted");
        
        minted[msg.sender] = true;
     
        for(int i = 0; i < 55; i++){
            tokenId++;
            _safeMint(msg.sender, tokenId-1);
        }
    }

    //----- END -----//

    //----- VIEW INFO FUNCTIONS -----//

    /**
     * @dev Returns all the tokenIds of a wallet
     */
    function walletOfOwner(address _owner)
    public
    view
    returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
        uint256 currentTokenId = 1;
        uint256 ownedTokenIndex = 0;

        while (ownedTokenIndex < ownerTokenCount && currentTokenId <= totalSupply()) {
            address currentTokenOwner = ownerOf(currentTokenId);

            if (currentTokenOwner == _owner) {
                ownedTokenIds[ownedTokenIndex] = currentTokenId;

                ownedTokenIndex++;
            }

            currentTokenId++;
        }

        return ownedTokenIds;
    }

    /**
     * @dev Total minted supply
     */
    function totalSupply() public view returns (uint256){
        return tokenId;
    }

    //----- END -----//

    //----- SET FUNCTIONS -----//

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

    //----- END -----//

    
    //TODO: Remove this function
    function checkLengh(uint256 _tokenId) public view returns (uint256) {
        return tokenIdAccessWallets[_tokenId].length;
    }

    //----- OVERRIDE FUNCTIONS -----//

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

        return bytes(uri).length > 0 ? string(abi.encodePacked(uri, id.toString(),".json")) : "";
    }

    //----- END -----//

    // Function to receive Canto. msg.data must be empty
    receive() external payable {}

    // Fallback function is called when msg.data is not empty
    fallback() external payable {}

}