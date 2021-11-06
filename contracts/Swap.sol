// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

import "hardhat/console.sol";

contract NFTSwap {
    using Counters for Counters.Counter;

    Counters.Counter private _swapRequestId;

    enum SwapRequestStatus {
        ACTIVE,
        INACTIVE,
        COMPLETED
    }

    struct SwapRequest {
        address from;
        address to;
        address nftContract1;
        address nftContract2;
        uint256 tokenId1;
        uint256 tokenId2;
        SwapRequestStatus status;
    }

    mapping(uint256 => SwapRequest) swapRequests;

    event NFTsSwapped(
        address userAddy1,
        address userAddy2,
        address contract1,
        address contract2,
        uint256 tokenId1,
        uint256 tokenId2
    );

    event SwapRequestCreated(
        address userAddy1,
        address userAddy2,
        address contract1,
        address contract2,
        uint256 tokenId1,
        uint256 tokenId2
    );

    event SwapRequestStatusUpdated(uint256 swapId, SwapRequestStatus status);

    function createSwapRequest(
        address to,
        address contractAddy1,
        address contractAddy2,
        uint256 tokenId1,
        uint256 tokenId2
    ) public {
        require(
            IERC721(contractAddy1).isApprovedForAll(msg.sender, address(this)),
            "Please approve this contract in the NFT contract before creating swap request"
        );
        _swapRequestId.increment();
        uint256 swapRequestId = _swapRequestId.current();

        swapRequests[swapRequestId] = SwapRequest(
            msg.sender,
            to,
            contractAddy1,
            contractAddy2,
            tokenId1,
            tokenId2,
            SwapRequestStatus.ACTIVE
        );

        emit SwapRequestCreated(
            msg.sender,
            to,
            contractAddy1,
            contractAddy2,
            tokenId1,
            tokenId2
        );
    }

    function deactivateSwapRequest(uint256 swapId) public {
        require(
            swapRequests[swapId].from != address(0x0),
            "Requested swapId does not exist"
        );
        require(
            swapRequests[swapId].from == msg.sender,
            "The request creator address does not match with msg.sender"
        );
        SwapRequest storage currentSwapRequest = swapRequests[swapId];
        currentSwapRequest.status = SwapRequestStatus.INACTIVE;

        emit SwapRequestStatusUpdated(swapId, SwapRequestStatus.INACTIVE);
    }

    function activateSwapRequest(uint256 swapId) public {
        require(
            swapRequests[swapId].from != address(0x0),
            "Requested swapId does not exist"
        );
        require(
            swapRequests[swapId].from == msg.sender,
            "The request creator address does not match with msg.sender"
        );
        SwapRequest storage currentSwapRequest = swapRequests[swapId];
        currentSwapRequest.status = SwapRequestStatus.ACTIVE;

        emit SwapRequestStatusUpdated(swapId, SwapRequestStatus.ACTIVE);
    }

    function _swapNft(
        address _userAddy1,
        address _userAddy2,
        address _contract1,
        address _contract2,
        uint256 _tokenId1,
        uint256 _tokenId2
    ) internal {
        IERC721(_contract1).safeTransferFrom(_userAddy1, _userAddy2, _tokenId1);
        IERC721(_contract2).safeTransferFrom(_userAddy2, _userAddy1, _tokenId2);

        emit NFTsSwapped(
            _userAddy1,
            _userAddy2,
            _contract1,
            _contract2,
            _tokenId1,
            _tokenId2
        );
    }

    function acceptSwapRequest(uint256 swapId) public {
        SwapRequest storage currentRequest = swapRequests[swapId];
        require(
            currentRequest.from != address(0x0),
            "Requested swapId does not exist"
        );
        require(
            currentRequest.to == msg.sender,
            "Request recepient address does not match with msg.sender"
        );
        require(
            currentRequest.status == SwapRequestStatus.ACTIVE,
            "Request status is not ACTIVE"
        );

        require(
            IERC721(currentRequest.nftContract2).isApprovedForAll(
                msg.sender,
                address(this)
            ),
            "Please approve this contract in the NFT contract before accepting swap request"
        );

        currentRequest.status = SwapRequestStatus.COMPLETED;

        _swapNft(
            currentRequest.from,
            currentRequest.to,
            currentRequest.nftContract1,
            currentRequest.nftContract2,
            currentRequest.tokenId1,
            currentRequest.tokenId2
        );
    }

    function getMyCreatedRequests() public view {}

    function getMyReceivedRequests() public view {}
}
