//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract Exchange is Ownable {

    mapping(address => mapping(uint256 => Listing)) public ListingsByTokenAddress;
    struct Listing { address tokenAddress; uint256 id; uint256 price; uint256 expiration; address owner; }

    uint256 public constant FEE = 1;

    // Admin Functions

    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    // Validation Functions

    function isValidListing (Listing memory _listing) internal view returns(bool) {
        return (
            block.timestamp <= _listing.expiration &&
            isOwner(_listing.tokenAddress, _listing.id, _listing.owner)
        );
    }

    function isOwner (address _tokenAddress, uint256 _tokenId, address _sender) internal view returns(bool) {
        IERC721 TokenAddress = IERC721(_tokenAddress);
        address currentOwner = TokenAddress.ownerOf(_tokenId);
        
        return currentOwner == _sender;
    }

    function isApprovalSet (address _tokenAddress, address _sender) internal view returns(bool) {
        IERC721 TokenAddress = IERC721(_tokenAddress);
        
        return TokenAddress.isApprovedForAll(_sender, address(this));
    }

    // Listing Functions

    function completeListing (address _tokenAddress, address _owner, address _receiver, uint256 _tokenId) internal {
        IERC721 TokenAddress = IERC721(_tokenAddress);
        TokenAddress.transferFrom(_owner, _receiver, _tokenId);
        payable(_owner).transfer(msg.value - (msg.value * (FEE / 100)));
    }

    function setListing (address _tokenAddress, uint256 _tokenId, uint256 _price, uint256 _expiration) external {
        require(isOwner(_tokenAddress, _tokenId, msg.sender));
        require(isApprovalSet(_tokenAddress, msg.sender));

        ListingsByTokenAddress[_tokenAddress][_tokenId] = Listing(_tokenAddress, _tokenId, _price, _expiration, msg.sender);
    }

    function buyListing (address _tokenAddress, uint256 _tokenId) external payable {
        Listing memory thisListing = ListingsByTokenAddress[_tokenAddress][_tokenId];
        require(isValidListing(thisListing));
        require(msg.value == thisListing.price, "Amount sent does not match price listed.");

        delete ListingsByTokenAddress[_tokenAddress][_tokenId];
        completeListing(_tokenAddress, thisListing.owner, msg.sender, _tokenId);
    }

}