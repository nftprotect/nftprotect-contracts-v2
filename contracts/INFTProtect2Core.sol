/*
This file is part of the NFT Protect project <https://nftprotect.app/>

The NFTProtect Contract is free software: you can redistribute it and/or
modify it under the terms of the GNU lesser General Public License as published
by the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

The NFTProtect Contract is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU lesser General Public License for more details.

You should have received a copy of the GNU lesser General Public License
along with the NFTProtect Contract. If not, see <http://www.gnu.org/licenses/>.

@author Ilya Svirin <is.svirin@gmail.com>
*/
// SPDX-License-Identifier: GNU lesser General Public License

pragma solidity ^0.8.0;

import "./IProtector.sol";

interface INFTProtect2Core
{
    function protectorCreated(IProtector protector, address original, address creator) external;

    function protector(address original) external returns(IProtector);

    function technicalOwner() external returns(address);

    /** @dev Call from IProtector implementation to notify about
     *       creation of entity and get global ID of entity.
     */
    function entityCreated(address creator, address referrer, Protection pr) external payable returns(uint256);

    function entityRequestForDelete(uint256 entityId, address from, address dst, uint256 arbitratorId, string memory evidence) external;

    function entityWrappedOwnerChanged(uint256 entityId, address newowner) external;

    function entityUnderDisupte(uint256 entityId) external view returns(bool);
}