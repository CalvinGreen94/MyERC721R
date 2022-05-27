//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
/**
.____          ___.                 .__        __  .__    .__                 ____ ___                           .__   
|    |   _____ \_ |__ ___.__._______|__| _____/  |_|  |__ |__| ____   ____   |    |   \___________   ____ _____  |  |  
|    |   \__  \ | __ <   |  |\_  __ \  |/    \   __\  |  \|  |/    \_/ __ \  |    |   /    \_  __ \_/ __ \\__  \ |  |  
|    |___ / __ \| \_\ \___  | |  | \/  |   |  \  | |   Y  \  |   |  \  ___/  |    |  /   |  \  | \/\  ___/ / __ \|  |__//zombie
|_______ (____  /___  / ____| |__|  |__|___|  /__| |___|  /__|___|  /\___  > |______/|___|  /__|    \___  >____  /____/
        \/    \/    \/\/                    \/          \/        \/     \/               \/            \/     \/      
*/
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

// import "@openzeppelin-solidity/contracts/lifecycle/Destructible.sol";


contract MyERC721R_Escrow is ERC721Enumerable, Pausable, Ownable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    
    Counters.Counter private _tokenIds;
    
    uint public constant MAX_SUPPLY = 7110;
    uint public  PRICE = 0.15 ether;
    uint public constant MAX_PER_MINT = 10;
    uint256 public constant refundPeriod = 10 days;
    uint256 public refundEndTime;
    address public refundAddress;

    string public baseTokenURI;

    // mapping(address => bool) whitelistedAddresses;
    // uint256 fee = 0.015 ether;
    constructor(string memory baseURI) ERC721("ERC721R", "ERC721R") {
        setBaseURI(baseURI);
        refundAddress = msg.sender;
        toggleRefundCountdown();
    }
    

    // function UserreserveNFTs() public{
    //     uint totalMinted = _tokenIds.current();
    //     require(msg.value >= PRICE.mul(_count), "Not enough ether to purchase NFTs.");


    //     require(totalMinted.add(225) < MAX_SUPPLY, "Not enough NFTs left to reserve");

    //     for (uint i = 0; i < 15; i++) {
    //         _mintSingleNFT();
    //     }
    // }

    function reserveNFTs() public onlyOwner {
        uint totalMinted = _tokenIds.current();
        

        require(totalMinted.add(225) < MAX_SUPPLY, "Not enough NFTs left to reserve");

        for (uint i = 0; i < 15; i++) {
            _mintSingleNFT();
        }
    }
    
    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }
    
    function setBaseURI(string memory _baseTokenURI) public onlyOwner {
        baseTokenURI = _baseTokenURI;
    }



    function mintNFTs(uint _count) public payable {
        uint totalMinted = _tokenIds.current();
        require(totalMinted.add(_count) <= MAX_SUPPLY, "Not enough NFTs left!");
        require(_count >0 && _count <= MAX_PER_MINT, "Cannot mint specified number of NFTs.");
        require(msg.value >= PRICE.mul(_count), "Not enough ether to purchase NFTs.");
        
        for (uint i = 0; i < _count; i++) {
            _mintSingleNFT();
        }
    }

    function _mintSingleNFT() private {
        uint newTokenID = _tokenIds.current();
        _safeMint(msg.sender, newTokenID);
        _tokenIds.increment();
    }
    

    // //only owner
    // function setCost(uint256 _newCost) public onlyOwner {
    //     cost = _newCost;
    // }

    // function setmaxMintAmount(uint256 newmaxMintAmount) public onlyOwner {
    //     maxMintAmount = newmaxMintAmount;
    // }



    function tokensOfOwner(address _owner) external view returns (uint[] memory) {

        uint tokenCount = balanceOf(_owner);
        uint[] memory tokensId = new uint256[](tokenCount);

        for (uint i = 0; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

    
    function withdraw() public payable onlyOwner {
        (bool hs, ) = payable(0x1e4b765841C75A4380602a19c63b71816DBFeE60).call{value: address(this).balance * 20 / 100}("");
        require(hs);

        uint balance = address(this).balance;
        require(balance > 0, "No ether left to withdraw");

        (bool success, ) = (msg.sender).call{value: balance}("");
        require(success, "Transfer failed.");

    }

    function burn(uint256 tokenId) public{
        _burn(tokenId);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        whenNotPaused
        override
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function isRefundGuaranteeActive() public view returns (bool) {
        return (block.timestamp <= refundEndTime);
    }

    function getRefundGuaranteeEndTime() public view returns (uint256) {
        return refundEndTime;
    }

    function refund(uint256[] calldata tokenIds) external {
        require(isRefundGuaranteeActive(), "Refund expired");

        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            require(msg.sender == ownerOf(tokenId), "Not token owner");
            transferFrom(msg.sender, refundAddress, tokenId);
        }

        uint256 refundAmount = tokenIds.length * PRICE;
        Address.sendValue(payable(msg.sender), refundAmount);
    }

    function toggleRefundCountdown() public onlyOwner {
        refundEndTime = block.timestamp + refundPeriod;
    }

    function setRefundAddress(address _refundAddress) external onlyOwner {
        refundAddress = _refundAddress;
    }

    function setPrice(uint256 newPRICE) public onlyOwner {
        PRICE = newPRICE;
    }
    // function addUser(address _addressToWhitelist) public onlyOwner {
    //     whitelistedAddresses[_addressToWhitelist] = true;
    // }
    
    // function verifyUser(address _whitelistedAddress) public view returns(bool) {
    //     bool userIsWhitelisted = whitelistedAddresses[_whitelistedAddress];
    //     return userIsWhitelisted;
    // }
}
