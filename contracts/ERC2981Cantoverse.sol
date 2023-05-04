// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

//import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

abstract contract ERC2981Cantoverse {
    struct RoyaltyInfo {
        address receiver;
        uint96 royaltyFraction;
    }

    mapping(address => RoyaltyInfo) _nftContractRoyaltyInfo;


    /**
     * @dev Returns the royalty for a nft contract.
    */
    function royaltyInfo(address _nftContract, uint256 _salePrice) public view virtual returns (address, uint256) {

        RoyaltyInfo memory royalty = _nftContractRoyaltyInfo[_nftContract];


        uint256 royaltyAmount = (_salePrice * royalty.royaltyFraction) / _feeDenominator();

        return (royalty.receiver, royaltyAmount);
    }

    /**
     * @dev The denominator with which to interpret the fee set in {_setTokenRoyalty} and {_setDefaultRoyalty} as a
     * fraction of the sale price. Defaults to 10000 so fees are expressed in basis points, but may be customized by an
     * override.
    */
    function _feeDenominator() internal pure virtual returns (uint96) {
        return 10000;
    }

    /**
     * @dev Sets the royalty information that all ids in the nft contract.
     *
     * Requirements:
     *
     * - `receiver` cannot be the zero address.
     * - `feeNumerator` cannot be greater than the fee denominator.
    */
    function _setDefaultRoyalty(address _nftContract, address receiver, uint96 feeNumerator) internal virtual {
        require(feeNumerator <= _feeDenominator(), "ERC2981: royalty fee will exceed salePrice");
        require(receiver != address(0), "ERC2981: invalid receiver");

        _nftContractRoyaltyInfo[_nftContract] = RoyaltyInfo (receiver, feeNumerator);
    }
}