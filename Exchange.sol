//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract Exchange is Ownable {

    mapping(uint256 => Listing) public Listings;
    struct Listing {
        address seller;
        address buyer;
        address tokenAddress;
        uint256 tokenId;
        uint256 price;
    }
    
    // Admin Functions

    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    // Internal Validation Functions

    function isOwner (address _tokenAddress, uint256 _tokenId, address _user) internal view returns(bool) {
        IERC721 TokenAddress = IERC721(_tokenAddress);
        return TokenAddress.ownerOf(_tokenId) == _user;
    }

    function isApprovalSet (address _tokenAddress, address _user) internal view returns(bool) {
        IERC721 TokenAddress = IERC721(_tokenAddress);
        return TokenAddress.isApprovedForAll(_user, address(this));
    }

    // Listing Functions

    function generateListingId (Listing memory _listing) internal view returns(uint256) {
        return uint256(keccak256(abi.encodePacked(abi.encodePacked(_listing.seller, _listing.buyer, _listing.tokenAddress, _listing.tokenId, _listing.price))));
    }

    function createListing (address _buyer, address _tokenAddress, uint256 _tokenId, uint256 _price) external returns(uint256) {
        require(isOwner(_tokenAddress, _tokenId, msg.sender));
        require(isApprovalSet(_tokenAddress, msg.sender));

        Listing memory _listing = Listing(
            msg.sender,
            _buyer,
            _tokenAddress,
            _tokenId,
            _price
        );

        uint256 listingId = generateListingId(_listing);

        Listings[listingId] = _listing;

        return listingId;
    }

}