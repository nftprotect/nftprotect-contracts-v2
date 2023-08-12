/*
This file is part of the NFT Protect project <https://nftprotect.app/>

The IRequestsHub Contract is free software: you can redistribute it and/or
modify it under the terms of the GNU lesser General Public License as published
by the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

The IRequestsHub Contract is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU lesser General Public License for more details.

You should have received a copy of the GNU lesser General Public License
along with the IRequestsHub Contract. If not, see <http://www.gnu.org/licenses/>.

@author Ilya Svirin <is.svirin@gmail.com>
*/
// SPDX-License-Identifier: GNU lesser General Public License


pragma solidity ^0.8.0;

import "./IUserRegistry.sol";


interface IRequestHub
{
    event BurnArbitrateAsked(uint256 indexed requestId, address dst);
    event BurnAnswered(uint256 indexed requestId, bool accept);
    event OwnershipAdjusted(address newowner, address oldowner, uint256 indexed entityId);
    event OwnershipAdjustmentAsked(uint256 indexed requestId, address indexed dst);
    event OwnershipAdjustmentAnswered(uint256 indexed requestId, bool accept);
    event OwnershipAdjustmentArbitrateAsked(uint256 indexed requestId, address dst);
    event OwnershipRestoreAsked(uint256 indexed requestId, address newowner);
    event OwnershipRestoreAnswered(uint256 indexed requestId, bool accept);
    event EntityAddedToRequest(uint256 indexed requestId, uint256 indexed entityId, address src, address dst);

    enum MetaEvidenceType
    {
        burn,
        adjustOwnership,
        askOwnershipAdjustment,
        answerOwnershipAdjustment,
        askOwnershipAdjustmentArbitrate,
        askOwnershipRestoreArbitrateMistake,
        askOwnershipRestoreArbitratePhishing,
        askOwnershipRestoreArbitrateProtocolBreach
    }

    function setUserRegistry(IUserRegistry userRegistry) external;
    function hasRequest(uint256 entityId) external view returns(bool);
    function submitMetaEvidence(MetaEvidenceType evidenceType, string memory evidence) external;

    /** @dev Request to burn wrapped entity and send original one to the owner.
     *  The originalOwner and the wrappedOwner must be the same.
     *  If not, need to call askOwnershipAdjustment() first.
     *  If case of Ultra protection start dispute.
     */
    function burn(uint256[] calldata entityies, address dst, uint256 arbitratorId, string memory evidence) external payable;

    /** @dev Transfer ownerhip for `entities` to the wrapperOwner.
     *  Must be called by the originalOwner.
     */
    function adjustOwnership(uint256[] calldata entities, uint256 arbitratorId, string memory evidence) external payable;

    /** @dev Create request for ownership adjustment for `entities`. It requires
     *  when somebody got ownership of wrapped entity. Owner of original entity
     *  must confirm or reject ownership transfer by calling answerOwnershipAdjustment().
     */
    function askOwnershipAdjustment(uint256[] calldata entities, address dst, uint256 arbitratorId) external;
    
    /** @dev Must be called by the owner of the original entity to confirm or reject
     *  ownership transfer to the new owner of the wrapper entity.
     */
    function answerOwnershipAdjustment(uint256 requestId, bool accept, string memory evidence) external payable;

    /** @dev Can be called by the wrappedOwner if originalOwner didn't answer or
     *  rejected ownership transfer. This function creates dispute.
     */
    function askOwnershipAdjustmentArbitrate(uint256 requestId, string memory evidence) external payable;

    /** @dev Create request for restore ownership to `entities`. Can be called
     *  by owriginalOwner if he or she lost access to wrappen entity or it was stolen.
     *  This function create dispute.
     */
    function askOwnershipRestoreArbitrate(uint256[] calldata entities, address dst, uint256 arbitratorId, MetaEvidenceType metaEvidenceType, string memory evidence) external payable;
}
