// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "usingtellor/contracts/UsingTellor.sol";

contract CallOracle is UsingTellor {
    struct Proposal {
        uint256 btcPrice;
        uint256 timestamp;
        bool executed;
    }
    Proposal[] public proposals;

    event ProposalCreated(uint256 indexed proposalId, uint256 btcPrice, uint256 timestamp);
    event ProposalExecuted(uint256 indexed proposalId);

    constructor(address payable _tellorAddress) UsingTellor(_tellorAddress) {
    }

    function getBtcSpotPrice(uint256 maxTime) external view returns (uint256) {
        bytes memory _queryData = abi.encode(
            "SpotPrice",
            abi.encode("btc", "usd")
        );
        bytes32 _queryId = keccak256(_queryData);

        (bytes memory _value, uint256 _timestampRetrieved) = _getDataBefore(
            _queryId,
            block.timestamp - 20 minutes
        );
        if (_timestampRetrieved == 0) return 0;
        require(
            block.timestamp - _timestampRetrieved < maxTime,
            "Maximum time elapsed"
        );
        return abi.decode(_value, (uint256));
    }
    function createProposal() external returns (uint256) {
        uint256 btcPrice = this.getBtcSpotPrice(10 minutes);
        require(btcPrice > 0, "Invalid Price");

        Proposal memory newProposal = Proposal({
            btcPrice: btcPrice,
            timestamp: block.timestamp,
            executed: false
        });
        
        proposals.push(newProposal);
        
        emit ProposalCreated(proposals.length - 1, btcPrice, block.timestamp);

        uint256 proposalId = proposals.length - 1;
        
        if (proposalId > 0 && proposals[proposalId].btcPrice > proposals[proposalId - 1].btcPrice) {
                proposals[proposalId].executed = true;
                emit ProposalExecuted(proposalId);
        }
        return proposalId;
    }
}