// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol"; //to use _setTokenURI function which sets the token URI
import "@openzeppelin/contracts/access/Ownable.sol"; //to use Ownable modifier
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol"; //import for using chainlink VRF => overriding the function fulfillRandomWords
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
//import for using chainlink VRF and using requestRandomWords function using the interface
//by providing it the address of VRFCoordinatorV2 deployed on chain or using the deployed MOCK

//Errors
error RandomIpfsNft__AlreadyInitialized(); //occur when our contract is already updated/initialised with the dogTokenUris
error RandomIpfsNft__NeedMoreETHSent(); //occurs when someone send less ETH than mintfee to mint NFT
error RandomIpfsNft__RangeOutOfBounds(); //occurs when getBreedFromModdedRng function receives a value in I/p out of the range (0 to MAX_CHANCE_VALUE)
error RandomIpfsNft__TransferFailed(); //occurs when money is not transferred to owner of contract

contract RandomIpfsNft is ERC721URIStorage, VRFConsumerBaseV2, Ownable {
    // Types
    enum Breed {
        PUG,
        SHIBA_INU,
        ST_BERNARD
    } //to hold different types of dogs each representing a NFT token

    // Chainlink VRF Variables
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator; //to capture instance of contract which will do random number verification
    uint64 private immutable i_subscriptionId; //The subscription ID that this contract uses for funding requests
    //for localhost it is taken from mock and for testnet we create subscription on chainLink
    bytes32 private immutable i_gasLane; //the maximum gas price we are willing to pay for a request in wei
    uint32 private immutable i_callbackGasLimit; //The limit for how much gas to use for the callback request to our contract’s fulfillRandomWords() function
    uint16 private constant REQUEST_CONFIRMATIONS = 3; //How many confirmations the Chainlink node should wait before responding. The longer the node waits, the more secure the random value is
    uint32 private constant NUM_WORDS = 1; //How many random values to request

    // NFT Variables
    uint256 private immutable i_mintFee; //fee tomint a token
    uint256 private s_tokenCounter; //to identify each NFT token
    uint256 internal constant MAX_CHANCE_VALUE = 100;
    //say [10, 40, MAX_CHANCE_VALUE]; different chance of different dogs
    // Pug = 0 - 9  (10%)
    // Shiba-inu = 10 - 39  (30%)
    // St. Bernard = 40 - 99/MAX_CHANCE_VALUE-1 (60%)
    string[] internal s_dogTokenUris; //array to hold TokenUris of three dogs of different rarity
    bool private s_initialized; //by default it is false and set to true when we update the s_dogTokenUris using _initializeContract(dogTokenUris) function

    // VRF Helpers
    mapping(uint256 => address) public s_requestIdToSender;
    //we use this state so that when requestRandomWords function internally cally fulfillRandomWords
    //then fulfillRandomWords will call _safeMint function so in _safeMint if we pass msg.sender
    //then it will be the address of chainlink coordinator that's why we create a mapping
    //b/w requestId and the one who call the function requestNFT

    // Events
    event NftRequested(uint256 indexed requestId, address requester); //fire when NFT is requestd
    event NftMinted(Breed breed, address minter); //fire when NFT is minted

    constructor(
        address vrfCoordinatorV2, //address of mock(if on localhost) or chainlink vrf contract(if on testnet)
        uint64 subscriptionId,
        bytes32 gasLane, // keyHash
        uint256 mintFee,
        uint32 callbackGasLimit,
        string[3] memory dogTokenUris
    ) VRFConsumerBaseV2(vrfCoordinatorV2) ERC721("Random IPFS NFT", "RIN") {
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinatorV2);
        i_gasLane = gasLane;
        i_subscriptionId = subscriptionId;
        i_mintFee = mintFee;
        i_callbackGasLimit = callbackGasLimit;
        _initializeContract(dogTokenUris);
        s_tokenCounter = 0;
    }

    //function to request a NFT
    function requestNft() public payable returns (uint256 requestId) {
        if (msg.value < i_mintFee) {
            revert RandomIpfsNft__NeedMoreETHSent();
        }
        requestId = i_vrfCoordinator.requestRandomWords(
            i_gasLane,
            i_subscriptionId,
            REQUEST_CONFIRMATIONS,
            i_callbackGasLimit,
            NUM_WORDS
        ); //internally call fulfillRandomWords

        s_requestIdToSender[requestId] = msg.sender; //to map requestId with owner of token
        emit NftRequested(requestId, msg.sender);
    }

    //function to mint NFT based on random no provided by chainlink
    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
        address dogOwner = s_requestIdToSender[requestId]; //to capture token owner
        uint256 newItemId = s_tokenCounter; //to capture token ID
        s_tokenCounter = s_tokenCounter + 1; //updating the counter
        uint256 moddedRng = randomWords[0] % MAX_CHANCE_VALUE; //to geta random no b/w 0 to MAX_CHANCE_VALUE
        Breed dogBreed = getBreedFromModdedRng(moddedRng); //to select a dog based on random no
        _safeMint(dogOwner, newItemId); //miniting token
        _setTokenURI(newItemId, s_dogTokenUris[uint256(dogBreed)]); //setting URI of token
        emit NftMinted(dogBreed, dogOwner); //firing event
    }

    //fuction specifying an array which assigns rarity to differnet dogs
    function getChanceArray() public pure returns (uint256[3] memory) {
        return [10, 40, MAX_CHANCE_VALUE]; //different chance of different dogs
        // Pug = 0 - 9  (10%)
        // Shiba-inu = 10 - 39  (30%)
        // St. Bernard = 40 - 99(MAX_CHANCE_VALUE-1) (60%)
    }

    //function to initialise dogTokenUris
    function _initializeContract(string[3] memory dogTokenUris) private {
        if (s_initialized) {
            revert RandomIpfsNft__AlreadyInitialized();
        }
        s_dogTokenUris = dogTokenUris;
        s_initialized = true;
    }

    //function to pick dog Breed based on random no
    function getBreedFromModdedRng(uint256 moddedRng) public pure returns (Breed) {
        uint256 cumulativeSum = 0;
        uint256[3] memory chanceArray = getChanceArray();
        for (uint256 i = 0; i < chanceArray.length; i++) {
            // Pug = 0 - 9  (10%)
            // Shiba-inu = 10 - 39  (30%)
            // St. Bernard = 40 - 99 (60%)
            if (moddedRng >= cumulativeSum && moddedRng < chanceArray[i]) {
                return Breed(i);
            }
            cumulativeSum = chanceArray[i];
        }
        revert RandomIpfsNft__RangeOutOfBounds();
    }

    //function to withdraw all the funds from the contract
    function withdraw() public onlyOwner {
        uint256 amount = address(this).balance;
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        if (!success) {
            revert RandomIpfsNft__TransferFailed();
        }
    }

    //-------Defining view/pure functions-------------

    function getMintFee() public view returns (uint256) {
        return i_mintFee;
    }

    function getDogTokenUris(uint256 index) public view returns (string memory) {
        return s_dogTokenUris[index];
    }

    function getInitialized() public view returns (bool) {
        return s_initialized;
    }

    function getTokenCounter() public view returns (uint256) {
        return s_tokenCounter;
    }
}
