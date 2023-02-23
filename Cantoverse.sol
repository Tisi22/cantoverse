// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import { SafeMath } from "./libraries/SafeMath.sol";


contract Cantoverse is ReentrancyGuard {

    using Counters for Counters.Counter;
    Counters.Counter private _nftCount;
    Counters.Counter private _nftsSold;

    address payable public _marketOwner;
    bytes4 private constant FUNC_SELECTOR = bytes4(keccak256("royaltyInfo(uint256 _tokenId, uint256 _salePrice)"));

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

    constructor() {
        _marketOwner = payable(msg.sender);
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

        (address contractNFTOwner, uint256 royaltiesValue) = royalties(_nftContract, _tokenId, nft.price );

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

    function callDetectRoyaltyInfo(address _nftContract, uint256 _token, uint256 _price) public view returns (bool) {
        bool success;
        bytes memory data = abi.encodeWithSelector(FUNC_SELECTOR, _token, _price);

        assembly {
            success := staticcall(
                gas(),            // gas remaining
                _nftContract,    // destination address
                add(data, 32),  // input buffer (starts after the first 32 bytes in the `data` array)
                mload(data),    // input length (loaded from the first 32 bytes in the `data` array)
                0,              // output buffer
                0               // output length
            )
        }

        return success;
    }

    function call2DetectRoyaltyInfo(address _nftContract, uint256 _tokenId, uint256 _price) public view returns (bool) {
        if(IERC2981(_nftContract).royaltyInfo(_tokenId, _price) != null){
            return true;
        }
        else{
            return false;
        }

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

}