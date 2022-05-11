//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract Exchange is Ownable {

    mapping(address => mapping(uint256 => Listing)) public ListingsByTokenAddress;
    struct Listing { address tokenAddress; uint256 id; uint256 price; uint256 expiration; address owner; }
    
    // Admin Functions

    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    // External Validation Functions
    
    function isValidListing (address _tokenAddress, uint256 _tokenId) external view returns(bool) {
        Listing memory _Listing = ListingsByTokenAddress[_tokenAddress][_tokenId];
        return (
            block.timestamp <= _Listing.expiration &&
            isOwner(_Listing.tokenAddress, _Listing.id, _Listing.owner)
        );
    }

    // Internal Validation Functions

    function isValidPurchaseOrder (Listing memory _listing) internal view returns(bool) {
        return (
            msg.value == _listing.price &&
            block.timestamp <= _listing.expiration &&
            msg.sender != _listing.owner &&
            isOwner(_listing.tokenAddress, _listing.id, _listing.owner)
        );
    }

    function isOwner (address _tokenAddress, uint256 _tokenId, address _user) internal view returns(bool) {
        IERC721 TokenAddress = IERC721(_tokenAddress);
        return TokenAddress.ownerOf(_tokenId) == _user;
    }

    function isApprovalSet (address _tokenAddress, address _user) internal view returns(bool) {
        IERC721 TokenAddress = IERC721(_tokenAddress);
        return TokenAddress.isApprovedForAll(_user, address(this));
    }

    // Listing Functions

    function processPurchaseOrder (address _tokenAddress, address _owner, address _receiver, uint256 _tokenId) internal {
        delete ListingsByTokenAddress[_tokenAddress][_tokenId];
       
        IERC721 TokenAddress = IERC721(_tokenAddress);
        TokenAddress.transferFrom(_owner, _receiver, _tokenId);
        
        payable(_owner).transfer(msg.value - (msg.value / 100));
    }

    function setListing (address _tokenAddress, uint256 _tokenId, uint256 _price, uint256 _expiration) external {
        require(isOwner(_tokenAddress, _tokenId, msg.sender));
        require(isApprovalSet(_tokenAddress, msg.sender));

        ListingsByTokenAddress[_tokenAddress][_tokenId] = Listing(_tokenAddress, _tokenId, _price, _expiration, msg.sender);
    }

    function buyListing (address _tokenAddress, uint256 _tokenId) external payable {
        Listing memory _Listing = ListingsByTokenAddress[_tokenAddress][_tokenId];
        require(isValidPurchaseOrder(_Listing));

        processPurchaseOrder(_tokenAddress, _Listing.owner, msg.sender, _tokenId);
    }

}