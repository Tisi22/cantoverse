// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "./ERC2981Cantoverse.sol";
import { SafeMath } from "../libraries/SafeMath.sol";

interface Turnstile {
    function register(address) external returns (uint256);
}


contract Cantoverse is ERC2981Cantoverse, ReentrancyGuard {

    using Counters for Counters.Counter;
    Counters.Counter private _nftCount;
    Counters.Counter private _nftsSold;

    address payable public _marketOwner;

    uint16 public MarketPlaceFee;

    modifier onlyOwner(){
        require(msg.sender == _marketOwner);
        _;
    }

    struct NFT {
        address payable seller;
        address payable owner;
        uint256 price;
        bool listed;
    }

    mapping(address => mapping(uint256 => NFT)) private contractNftIdentifier;

    mapping(address => uint256[]) private listedNFTPerContract;

    event NFTListed(address nftContract, uint256 tokenId, address seller, address owner, uint256 price);

    event NFTSold(address nftContract, uint256 tokenId, address seller, address owner, uint256 price);

    // CSR for Canto
    Turnstile turnstile = Turnstile(0xEcf044C5B4b867CFda001101c617eCd347095B44);

    constructor() {
        _marketOwner = payable(msg.sender);
        turnstile.register(tx.origin);
    }

    //Before calling this function with unity, need to call setApprovalForAll(address(this), true); from the contract that has the NFT
    // List the NFT on the marketplace
    function listNft(address _nftContract, uint256 _tokenId, uint256 _price) public nonReentrant {
        require(_price > 0, "Price must be at least 1 wei");

        _nftCount.increment();

        listedNFTPerContract[_nftContract].push(_tokenId);

        contractNftIdentifier[_nftContract][_tokenId] = NFT(
            payable(msg.sender),
            payable(address(this)),
            _price,
            true
        );

        IERC721(_nftContract).transferFrom(msg.sender, address(this), _tokenId);

        emit NFTListed(_nftContract, _tokenId, msg.sender, address(this), _price);
    }

    // Buy an NFT
    function buyNft(address _nftContract, uint256 _tokenId) public payable nonReentrant returns (uint256 _feeValue, uint256 _royaltiesValue, uint256 sellerValue) {
        NFT storage nft = contractNftIdentifier[_nftContract][_tokenId];
        require(msg.value >= nft.price, "Not enough value sent");
        require (nft.listed, "Token Id not listed");

        address contractNFTOwner;
        uint256 royaltiesValue;

        bool royaltiesSuccess = false;

        try this.royalties(_nftContract, _tokenId, nft.price) returns (address _owner, uint256 _value) {
            contractNFTOwner = _owner;
            royaltiesValue = _value;
            royaltiesSuccess = true;
        } catch {
            royaltiesSuccess = false;
        }

        if (!royaltiesSuccess) {
            (contractNFTOwner, royaltiesValue) = royaltyInfo(_nftContract, nft.price);
        }

        uint256 feeValue = SafeMath.div(SafeMath.mul(nft.price,MarketPlaceFee), 10000);

        _marketOwner.transfer(feeValue);
        payable(contractNFTOwner).transfer(royaltiesValue);
        (nft.seller).transfer(nft.price - royaltiesValue - feeValue);


        nft.owner = payable(msg.sender);
        nft.listed = false;

        _nftsSold.increment();

        removeSoldElement(_nftContract,  _tokenId);

        IERC721(_nftContract).transferFrom(address(this), msg.sender, _tokenId);

        return(feeValue, royaltiesValue, nft.price - royaltiesValue - feeValue );
        
    }

    //TODO: Change to internal
    function royalties(address _nftContract, uint256 _tokenId, uint256 _price) public view returns (address, uint256){
        return IERC2981(_nftContract).royaltyInfo(_tokenId, _price);
    }

    function setDefaultRoyalty(address _nftContract,address receiver, uint96 feeNumerator)public {
        require(Ownable(_nftContract).owner() == msg.sender);
        _setDefaultRoyalty(_nftContract, receiver, feeNumerator);
    }
 

    function removeListedNFT(address _nftContract, uint256 _tokenId) public nonReentrant {
        require(contractNftIdentifier[_nftContract][_tokenId].seller == msg.sender, "Caller is not the owner");

        _nftCount.decrement();
        removeSoldElement(_nftContract,  _tokenId);

        contractNftIdentifier[_nftContract][_tokenId].listed = false; 

        IERC721(_nftContract).transferFrom(address(this), msg.sender, _tokenId);
    }

    function removeSoldElement(address _nftContract, uint256 _tokenId) private {
        for (uint256 i = 0; i < listedNFTPerContract[_nftContract].length; i++)
        {
            if(listedNFTPerContract[_nftContract][i] == _tokenId)
            {
                listedNFTPerContract[_nftContract][i] = listedNFTPerContract[_nftContract][listedNFTPerContract[_nftContract].length - 1];
                listedNFTPerContract[_nftContract].pop();
            }
        }
    }

    //TODO: Check the size of the tokenIds because it returns all the nfts that are not sold for all the contracts
    function getListedNftsPerContract(address _nftContract) public view returns (uint256[] memory _tokenIds) {
        uint256 nftCount = _nftCount.current();
        uint256 unsoldNftsCount = nftCount - _nftsSold.current();

        uint256[] memory tokenIds = new uint256[](unsoldNftsCount);
        uint nftsIndex = 0;
        for (uint i = 0; i < listedNFTPerContract[_nftContract].length ; i++) {
            if(contractNftIdentifier[_nftContract][listedNFTPerContract[_nftContract][i]].listed) {
                tokenIds[nftsIndex] = listedNFTPerContract[_nftContract][i];
                nftsIndex++;
            }
        }
        return tokenIds;
    }

    function getMyListedNftsPerContract(address _nftContract) public view returns (uint256[] memory _tokenIds) {
        uint myListedNftCount = 0;
        for (uint i = 0; i < listedNFTPerContract[_nftContract].length; i++) {
            if (contractNftIdentifier[_nftContract][listedNFTPerContract[_nftContract][i]].seller == msg.sender && contractNftIdentifier[_nftContract][listedNFTPerContract[_nftContract][i]].listed) {
             myListedNftCount++;
            }
        }

        uint256[] memory tokenIds = new uint256[](myListedNftCount);
        uint nftsIndex = 0;
        for (uint i = 0; i < listedNFTPerContract[_nftContract].length ; i++) {
            if(contractNftIdentifier[_nftContract][listedNFTPerContract[_nftContract][i]].seller == msg.sender && contractNftIdentifier[_nftContract][listedNFTPerContract[_nftContract][i]].listed) {
                tokenIds[nftsIndex] = listedNFTPerContract[_nftContract][i];
                nftsIndex++;
            }
        }
        return (tokenIds);
    }

    function getPrice(address _nftContract, uint256 _tokenId) public view returns (uint256){
        return contractNftIdentifier[_nftContract][_tokenId].price;
    }

    function setMarketPlaceFee (uint16 _MarketPlaceFee) public onlyOwner {
        MarketPlaceFee = _MarketPlaceFee;
    }

    // Function to receive Canto. msg.data must be empty
    receive() external payable override {}

    // Fallback function is called when msg.data is not empty
    fallback() external payable override {}

}