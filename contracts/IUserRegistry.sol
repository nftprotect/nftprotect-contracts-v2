/*
This file is part of the NFT Protect project <https://nftprotect.app/>

The IUserRegistry Contract is free software: you can redistribute it and/or
modify it under the terms of the GNU lesser General Public License as published
by the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

The IUserRegistry Contract is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU lesser General Public License for more details.

You should have received a copy of the GNU lesser General Public License
along with the IUserRegistry Contract. If not, see <http://www.gnu.org/licenses/>.

@author Ilya Svirin <is.svirin@gmail.com>
*/
// SPDX-License-Identifier: GNU lesser General Public License

pragma solidity ^0.8.0;

import "./IProtector.sol";

interface IUserRegistry
{
    function isRegistered(address user) external view returns(bool);

    function isQualified(address user) external view returns(bool);

    /** @dev Return the last user in chain from given 'user'
     */
    function trueUser(address user) external view returns(address);

    function processPayment(address user, address payable referrer, Protection pr) external payable;

    function giveReward(address user) external;

    function setMetaEvidenceLoader(address mel) external;
}
