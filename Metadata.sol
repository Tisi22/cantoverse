//SPDX-License-Identifier: MIT
pragma solidity ~0.8.17;

import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import { StringUtils } from "./libraries/StringUtils.sol";


contract Metadata {
    string svgPartOne = Image;
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

