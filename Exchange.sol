//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract Exchange is Ownable {

    mapping(uint256 => Listing) public Listings;
    mapping(address => uint256) public ListingsByAddress;
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

    function isValidListing (address _seller, address _buyer, address _tokenAddress, uint256 _tokenId) internal view returns(bool) {
        IERC721 TokenAddress = IERC721(_tokenAddress);
        return (
            _seller != address(0) &&
            _buyer != address(0) &&
            TokenAddress.ownerOf(_tokenId) == _seller &&
            TokenAddress.isApprovedForAll(_seller, address(this))
        );
    }

    function isValidPurchase (address _seller, address _buyer, address _tokenAddress, uint256 _tokenId, uint256 _price) internal view returns(bool) {
        IERC721 TokenAddress = IERC721(_tokenAddress);
        return (
            _buyer == msg.sender &&
            _price == msg.value &&
            TokenAddress.ownerOf(_tokenId) == _seller &&
            TokenAddress.isApprovedForAll(_seller, address(this))
        );
    }

    // Internal Listing Functions

    function generateListingId (Listing memory _listing) internal view returns(uint256) {
        return uint256(keccak256(abi.encodePacked(_listing.seller, _listing.buyer, _listing.tokenAddress, _listing.tokenId, _listing.price)));
    }

    function completePurchase (uint256 _listingId, Listing memory _listing) internal {
        delete Listings[_listingId];
        delete ListingsByAddress[_listing.seller];

        IERC721 TokenContract = IERC721(_listing.tokenAddress);
        TokenContract.transferFrom(_listing.seller, _listing.buyer, _listing.tokenId);
        
        payable(_listing.seller).transfer(msg.value - (msg.value / 100));
    }

    // External Listing Functions

    function createListing (address _buyer, address _tokenAddress, uint256 _tokenId, uint256 _price) external returns(uint256) {
        require(isValidListing(msg.sender, _buyer, _tokenAddress, _tokenId));

        Listing memory _listing = Listing(
            msg.sender,
            _buyer,
            _tokenAddress,
            _tokenId,
            _price
        );

        uint256 listingId = generateListingId(_listing);

        if (ListingsByAddress[msg.sender] != 0) {
            delete Listings[ListingsByAddress[msg.sender]];
            delete ListingsByAddress[msg.sender];
        }

        Listings[listingId] = _listing;
        ListingsByAddress[msg.sender] = listingId;

        return listingId;
    }

    function cancelListing (uint256 _listingId) external {
        Listing memory _listing = Listings[_listingId];
        require(msg.sender == _listing.seller);

        delete Listings[_listingId];
        delete ListingsByAddress[msg.sender];
    }

    function purchaseListing (uint256 _listingId) external payable {
        Listing memory _listing = Listings[_listingId];
        require(isValidPurchase(_listing.seller, _listing.buyer, _listing.tokenAddress, _listing.tokenId, _listing.price));

        completePurchase(_listingId, _listing);
    }

}