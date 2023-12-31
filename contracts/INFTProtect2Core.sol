/*
This file is part of the NFT Protect project <https://nftprotect.app/>

The INFTProtect2Core Contract is free software: you can redistribute it and/or
modify it under the terms of the GNU lesser General Public License as published
by the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

The INFTProtect2Core Contract is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU lesser General Public License for more details.

You should have received a copy of the GNU lesser General Public License
along with the INFTProtect2Core Contract. If not, see <http://www.gnu.org/licenses/>.

@author Ilya Svirin <is.svirin@gmail.com>
*/
// SPDX-License-Identifier: GNU lesser General Public License

pragma solidity ^0.8.0;

import "./IProtector.sol";

interface INFTProtect2Core
{
    function technicalOwner() external returns(address);

    function onProtectorCreated(IProtector protector, address original, address creator) external;
    function protector(address original) external returns(IProtector);

    /** @dev Call from IProtector implementation to notify about
     *       creation of entity and get global ID of entity.
     */
    function onEntityCreated(address creator, address referrer, Protection pr) external payable returns(uint256);
    function onEntityWrappedOwnerChanged(uint256 entityId, address newowner) external;
    function entityUnderDisupte(uint256 entityId) external view returns(bool);
    function entityInfo(uint256 entityId) external view returns(
            address    originalOwner,
            address    wrappedOwner,
            Protection protection);

    /** @dev Call from RequestHub as result of dispute */
    function applyBurn(uint256 entityId, address dst) external;
    function applyOwnershipAdjustment(uint256 entityId, address dst) external;
    function applyOwnershipRestore(uint256 entityId, address dst) external;
}