// SPDX-License-Identifier: MIT

//if the ETH price obtained from chainlink pricefeed is greater than a particular value
//then user get high token(happy face) and if it is lower than a particular value then user get low token(sad face)
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol"; //to use _safeMint function and tokenURI function of ERC721 contract
import "@openzeppelin/contracts/access/Ownable.sol"; //to use Ownable modifier
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol"; //to use priceFeed of chainlink
import "base64-sol/base64.sol"; //package to convert svg to base64 encoded image URI/URL

error ERC721Metadata__URI_QueryFor_NonExistentToken();

contract DynamicSvgNft is ERC721, Ownable {
    //VARIABLES
    uint256 private s_tokenCounter; //to identify each NFT token
    string private s_lowImageURI; //to store URI for low image(sad face)
    string private s_highImageURI; //to store URI for high image(happy face)
    mapping(uint256 => int256) private s_tokenIdToHighValues; //mapping which holds threshold value for each token which decides token is high or low
    AggregatorV3Interface internal immutable i_priceFeed; //to capture instance of contract which will provide pricefeed

    //EVENT
    event CreatedNFT(uint256 indexed tokenId, int256 highValue); //occur when NFT is created

    constructor(
        address priceFeedAddress, //address of mock(if on localhost) or chainlink pricefeed contract(if on testnet)
        string memory lowSvg, //low svg file
        string memory highSvg //low svg file
    ) ERC721("Dynamic SVG NFT", "DSN") {
        s_tokenCounter = 0;
        i_priceFeed = AggregatorV3Interface(priceFeedAddress);
        s_lowImageURI = svgToImageURI(lowSvg);
        s_highImageURI = svgToImageURI(highSvg);
    }

    //function to mint NFT
    function mintNft(int256 highValue) public {
        s_tokenIdToHighValues[s_tokenCounter] = highValue; //ASSIGNING THE THRESHOLD VALUE TO THE TOKEN
        _safeMint(msg.sender, s_tokenCounter); //minting using ERC721 function
        s_tokenCounter = s_tokenCounter + 1; //updating token counter
        emit CreatedNFT(s_tokenCounter, highValue); //firing event
    }

    function svgToImageURI(string memory svg) public pure returns (string memory) {
        string memory baseURL = "data:image/svg+xml;base64,"; //base URI of images
        string memory svgBase64Encoded = Base64.encode(bytes(string(abi.encodePacked(svg)))); //converting svg to base64
        return string(abi.encodePacked(baseURL, svgBase64Encoded)); //concatinating the base URL
    } //this function converts svg to base64 encoded image URI

    //this function returns base URI of the token
    function _baseURI() internal pure override returns (string memory) {
        return "data:application/json;base64,";
    }

    //this function returns the URI of token
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) {
            revert ERC721Metadata__URI_QueryFor_NonExistentToken();
        }
        (, int256 price, , , ) = i_priceFeed.latestRoundData();
        string memory imageURI = s_lowImageURI;
        if (price >= s_tokenIdToHighValues[tokenId]) {
            imageURI = s_highImageURI;
        }
        return
            string(
                abi.encodePacked(
                    _baseURI(),
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"name":"',
                                name(), // ERC721 function returning token name
                                '", "description":"An NFT that changes based on the Chainlink Feed", ',
                                '"attributes": [{"trait_type": "coolness", "value": 100}], "image":"',
                                imageURI,
                                '"}'
                            )
                        )
                    )
                )
            );
    }

    function getLowSVG() public view returns (string memory) {
        return s_lowImageURI;
    }

    function getHighSVG() public view returns (string memory) {
        return s_highImageURI;
    }

    function getPriceFeed() public view returns (AggregatorV3Interface) {
        return i_priceFeed;
    }

    function getTokenCounter() public view returns (uint256) {
        return s_tokenCounter;
    }
}
