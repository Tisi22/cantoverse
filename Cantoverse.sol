// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import { SafeMath } from "./libraries/SafeMath.sol";

contract Cantoverse is ReentrancyGuard {

    using Counters for Counters.Counter;
    Counters.Counter private _nftCount;
    Counters.Counter private _nftsSold;

    address payable private _marketOwner;

    struct NFT {
        address payable seller;
        address payable owner;
        uint256 price;
        bool listed;
    }

    mapping(address => mapping(uint256 => NFT)) private contractNftIdentifier;

    //TODO: Change to private
    mapping(address => uint256[]) public listedNFTPerContract;

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
    function buyNft(address _nftContract, uint256 _tokenId) public payable nonReentrant {
        NFT storage nft = contractNftIdentifier[_nftContract][_tokenId];
        require(msg.value == nft.price, "Send the exact value to cover asking price");

        
        payable(nft.seller).transfer(SafeMath.div(SafeMath.mul(99, nft.price),100));
        _marketOwner.transfer(SafeMath.div(nft.price,100));

        nft.owner = payable(msg.sender);
        nft.listed = false;

        _nftsSold.increment();

        removeSoldElement(_nftContract,  _tokenId);

        IERC721(_nftContract).transferFrom(address(this), msg.sender, _tokenId);
        
    }

    function removeListedNFT(address _nftContract, uint256 _tokenId) public nonReentrant {
        require(contractNftIdentifier[_nftContract][_tokenId].seller == msg.sender; "Caller is not the owner");

        _nftCount.decrement();
        removeSoldElement(_nftContract,  _tokenId);

        contractNftIdentifier[_nftContract][_tokenId].listed = false; 
        contractNftIdentifier[_nftContract][_tokenId].seller = address(0);

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

    function getListedNftsPerContract(address _nftContract) public view returns (uint256[] memory _tokenIds, uint256[] memory _prices) {
        uint256 nftCount = _nftCount.current();
        uint256 unsoldNftsCount = nftCount - _nftsSold.current();

        uint256[] memory tokenIds = new uint256[](unsoldNftsCount);
        uint256[] memory prices = new uint256[](unsoldNftsCount);
        uint nftsIndex = 0;
        for (uint i = 0; i < listedNFTPerContract[_nftContract].length ; i++) {
            if(contractNftIdentifier[_nftContract][listedNFTPerContract[_nftContract][i]].listed) {
                tokenIds[nftsIndex] = listedNFTPerContract[_nftContract][i];
                prices[nftsIndex] = contractNftIdentifier[_nftContract][listedNFTPerContract[_nftContract][i]].price;
                nftsIndex++;
            }
        }
        return (tokenIds, prices);
    }

    function getMyListedNftsPerContract(address _nftContract) public view returns (uint256[] memory _tokenIds, uint256[] memory _prices) {
        uint myListedNftCount = 0;
        for (uint i = 0; i < listedNFTPerContract[_nftContract].length; i++) {
            if (contractNftIdentifier[_nftContract][listedNFTPerContract[_nftContract][i]].seller == msg.sender && contractNftIdentifier[_nftContract][listedNFTPerContract[_nftContract][i]].listed) {
             myListedNftCount++;
            }
        }

        uint256[] memory tokenIds = new uint256[](myListedNftCount);
        uint256[] memory prices = new uint256[](myListedNftCount);
        uint nftsIndex = 0;
        for (uint i = 0; i < listedNFTPerContract[_nftContract].length ; i++) {
            if(contractNftIdentifier[_nftContract][listedNFTPerContract[_nftContract][i]].seller == msg.sender && contractNftIdentifier[_nftContract][listedNFTPerContract[_nftContract][i]].listed) {
                tokenIds[nftsIndex] = listedNFTPerContract[_nftContract][i];
                prices[nftsIndex] = contractNftIdentifier[_nftContract][listedNFTPerContract[_nftContract][i]].price;
                nftsIndex++;
            }
        }
        return (tokenIds, prices);
    }

}