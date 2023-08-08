// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@kleros/erc-792/contracts/IArbitrator.sol";

/**
 *  @title IArbitrableProxy
 *  A general purpose arbitrable contract. Supports non-binary rulings.
 */
interface IArbitrableProxy
{
    function arbitrator() external view returns (IArbitrator arbitrator);

    function createDispute(
        bytes calldata  arbitratorExtraData,
        string calldata metaevidenceURI,
        uint256         numberOfRulingOptions
    ) external payable returns (uint256 disputeID);

    struct DisputeStruct
    {
        bytes   arbitratorExtraData;
        bool    isRuled;
        uint256 ruling;
        uint256 disputeIDOnArbitratorSide;
    }

    function externalIDtoLocalID(uint256 externalID) external returns (uint256 localID);

    function disputes(uint256 localID) external returns (
            bytes memory extraData,
            bool         isRuled,
            uint256      ruling,
            uint256      disputeIDOnArbitratorSide);

    function submitEvidence(uint256 localDisputeID, string calldata evidenceURI) external;
}
