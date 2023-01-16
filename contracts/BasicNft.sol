// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol"; //to use _safeMint function and tokenURI function of ERC721 contract
import "hardhat/console.sol"; //to use console.logs

contract BasicNft is ERC721 {
    string public constant TOKEN_URI =
        "ipfs://bafybeig37ioir76s7mg5oobetncojcm3c3hxasyd4rvid4jqhy4gkaheg4/?filename=0-PUG.json";
    //we get this token id by uploading token metadata to ipfs(can be pinned on locl IPFS network or pinata)
    //and in that metadata we include the URI(obtained by uploading image on IPFS)
    // of the image
    uint256 private s_tokenCounter; //to identify different tokens(works as tokenId)

    constructor() ERC721("Dogie", "DOG") {
        s_tokenCounter = 0;
    }

    //function to mint an NFT
    function mintNft() public {
        s_tokenCounter = s_tokenCounter + 1; //the initial tokenid is 1 and is updated each time a new token is minted
        _safeMint(msg.sender, s_tokenCounter); //this function is from ERC721 openzeppelin
    }

    function tokenURI(uint256 /*tokenId*/) public pure override returns (string memory) {
        return TOKEN_URI;
    } //this function returns the metadata of NFT and is taken from openzeppelin ERC721

    function getTokenCounter() public view returns (uint256) {
        return s_tokenCounter;
    }
}
