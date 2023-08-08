/*
This file is part of the NFT Protect project <https://nftprotect.app/>

The IProtector Contract is free software: you can redistribute it and/or
modify it under the terms of the GNU lesser General Public License as published
by the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

The IProtector Contract is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU lesser General Public License for more details.

You should have received a copy of the GNU lesser General Public License
along with the IProtector Contract. If not, see <http://www.gnu.org/licenses/>.

@author Ilya Svirin <is.svirin@gmail.com>
*/
// SPDX-License-Identifier: GNU lesser General Public License

pragma solidity ^0.8.0;

enum Protection
{
    Basic,
    Ultra
}

interface IProtectorFactory
{
    event ProtectorCreated(IProtector indexed p, address original);
    function name() external view returns(string memory);
    function createProtector(address original) external returns(IProtector);
}

interface IProtector
{
    event Protected(uint256 indexed entityId, Protection pr);
    event Unprotected(uint256 indexed entityId);

    /** @dev Calls from core as result of desputing for 'entityId'
     */
    function burnEntity(uint256 entityId, address dst) external;

    /** @dev Calls from core as result of desputing for 'entityId'
     */
    function transferEntity(uint256 entityId, address newowner) external;
}
