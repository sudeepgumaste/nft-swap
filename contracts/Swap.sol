// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

import "hardhat/console.sol";

contract NFTSwap {
    //? Provides counters that can only be incremented, decremented or reset.
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
        address contractAddy1;
        address contractAddy2;
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
        //* did the user approve the swap contract?
        require(
            IERC721(contractAddy1).isApprovedForAll(msg.sender, address(this)),
            "Please approve this contract in the NFT contract before creating swap request"
        );
         //* is the NFT and it's ID belong to the user
        require(
            IERC721(contractAddy1).ownerOf(tokenId1) == msg.sender,
            "The source NFT id does not belong to the sender"
        );
        require(
            IERC721(contractAddy2).ownerOf(tokenId2) == to,
            "The destination NFT id does not belong to the destination address"
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
//! we're updating the status of the swap request here
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
//* for all front end devs out there, this is state and we're pushing a new request to the array to save it for other uses :)
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
//* This function is called when the swapRequest security measure is completed
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
            IERC721(currentRequest.contractAddy2).isApprovedForAll(
                msg.sender,
                address(this)
            ),
            "Please approve this contract in the NFT contract before accepting swap request"
        );

        currentRequest.status = SwapRequestStatus.COMPLETED;

        _swapNft(
            currentRequest.from,
            currentRequest.to,
            currentRequest.contractAddy1,
            currentRequest.contractAddy2,
            currentRequest.tokenId1,
            currentRequest.tokenId2
        );
    }
//! the rest is Data that users might wanna see displayed
    function getMyCreatedRequests() public view returns (SwapRequest[] memory) {
        uint256 totalRequests = _swapRequestId.current();
        uint256 requestCount = 0;

        for (uint256 i = 0; i < totalRequests; i++) {
            if (swapRequests[i + 1].from == msg.sender) {
                requestCount++;
            }
        }

        SwapRequest[] memory requests = new SwapRequest[](requestCount);

        for (uint256 i = 0; i < requestCount; i++) {
            SwapRequest memory currentRequest = swapRequests[i + 1];
            if (currentRequest.from == msg.sender) {
                SwapRequest memory request = SwapRequest(
                    currentRequest.from,
                    currentRequest.to,
                    currentRequest.contractAddy1,
                    currentRequest.contractAddy2,
                    currentRequest.tokenId1,
                    currentRequest.tokenId2,
                    currentRequest.status
                );

                requests[i] = request;
            }
        }

        return requests;
    }

    function getMyReceivedRequests()
        public
        view
        returns (SwapRequest[] memory)
    {
        uint256 totalRequests = _swapRequestId.current();
        uint256 requestCount = 0;

        for (uint256 i = 0; i < totalRequests; i++) {
            if (swapRequests[i + 1].to == msg.sender) {
                requestCount++;
            }
        }

        SwapRequest[] memory requests = new SwapRequest[](requestCount);

        for (uint256 i = 0; i < requestCount; i++) {
            SwapRequest memory currentRequest = swapRequests[i + 1];
            if (currentRequest.to == msg.sender) {
                SwapRequest memory request = SwapRequest(
                    currentRequest.from,
                    currentRequest.to,
                    currentRequest.contractAddy1,
                    currentRequest.contractAddy2,
                    currentRequest.tokenId1,
                    currentRequest.tokenId2,
                    currentRequest.status
                );

                requests[i] = request;
            }
        }

        return requests;
    }
}
