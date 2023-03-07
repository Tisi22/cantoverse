//SPDX-License-Identifier: MIT
pragma solidity ~0.8.17;

import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import { StringUtils } from "../libraries/StringUtils.sol";

contract Metadata {

    string svgPartOne = '<svg xmlns="http://www.w3.org/2000/svg" width="270" height="270" fill="none"> <defs> <pattern id="background" width="100%" height="100%" patternUnits="userSpaceOnUse"> <image href="https://gateway.lighthouse.storage/ipfs/QmQHiSooVvgCxjQPx6RNaSyLhjuKqJKHxSyxFVdNW8EJD6" x="0" y="0" width="100%" height="100%" /> </pattern> </defs> <path fill="url(#background)" d="M0 0h270v270H0z"/> <defs> <filter id="A" color-interpolation-filters="sRGB" filterUnits="userSpaceOnUse" height="270" width="270"> <feDropShadow dx="0" dy="1" stdDeviation="2" flood-opacity=".225" width="200%" height="200%"/> </filter> </defs> <defs> <linearGradient id="B" x1="0" y1="0" x2="270" y2="270" gradientUnits="userSpaceOnUse"> <stop stop-color="#cb5eee"/><stop offset="1" stop-color="#0cd7e4" stop-opacity=".99"/> </linearGradient> </defs> <text x="32.5" y="231" font-size="27" fill="#fff" filter="url(#A)" font-family="Plus Jakarta Sans,DejaVu Sans,Noto Color Emoji,Apple Color Emoji,sans-serif" font-weight="bold">';
    string svgPartTwo = '</text></svg>';

    string public tld;

    constructor(string memory _tld){
    tld = _tld;
    }

    function URI(string memory name) public view returns (string memory){

    // Combine the name passed into the function  with the TLD
    string memory _name = string(abi.encodePacked(name, ".", tld));
    // Create the SVG (image) for the NFT with the name
    string memory finalSvg = string(abi.encodePacked(svgPartOne, _name, svgPartTwo));
    
    uint256 length = StringUtils.strlen(name);
    string memory strLen = Strings.toString(length);

    // Create the JSON metadata of our NFT. We do this by combining strings and encoding as base64
    string memory json = Base64.encode(
      abi.encodePacked(
        '{"name": "',
        _name,
        '", "description": "A domain on Polygon Name Service", "image": "data:image/svg+xml;base64,',
        Base64.encode(bytes(finalSvg)),
        '","length":"',
        strLen,
        '"}'
      )
    );

    string memory finalTokenURI = string( abi.encodePacked("data:application/json;base64,", json));
    
    return finalTokenURI;

    }

}