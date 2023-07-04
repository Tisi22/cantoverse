// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;


interface NftContract {
    function balanceOf(address owner) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function ownerOf(uint256 tokenId) external view returns (address);
}

contract WalletOfOwner {

  NftContract nftContract;

  constructor(address _nftContract){
    nftContract =  NftContract(_nftContract);
  }
    
  function InterfaceWalletOfOwner(address _contract, address _owner, uint256 maxSupply)
  public
  view
  returns (uint256[] memory)

  {
 
    uint256 ownerTokenCount = NftContract(_contract).balanceOf(_owner);
    uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
    uint256 currentTokenId = 1;
    uint256 ownedTokenIndex = 0;

    while (ownedTokenIndex < ownerTokenCount && currentTokenId <= maxSupply) {
      address currentTokenOwner = NftContract(_contract).ownerOf(currentTokenId);

      if (currentTokenOwner == _owner) {
        ownedTokenIds[ownedTokenIndex] = currentTokenId;

        ownedTokenIndex++;
      }

      currentTokenId++;
    }

    return ownedTokenIds;
  }

   
}