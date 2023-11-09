/*
This file is part of the NFT Protect project <https://nftprotect.app/>

The UserDIDDummy Contract is free software: you can redistribute it and/or
modify it under the terms of the GNU lesser General Public License as published
by the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

The UserDIDDummy Contract is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU lesser General Public License for more details.

You should have received a copy of the GNU lesser General Public License
along with the UserDIDDummy Contract. If not, see <http://www.gnu.org/licenses/>.

@author Ilya Svirin <is.svirin@gmail.com>
*/
// SPDX-License-Identifier: GNU lesser General Public License


pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../IUserDID.sol";


contract UserDIDDummyAllowAll is Ownable, IUserDID
{
    constructor() Ownable(msg.sender) {}

    function provider() public pure override returns(string memory)
    {
        return "dummyAllowAll";
    }

    function isIdentified(address user) public pure override returns(bool)
    {
        return (user != 0x0000000000000000000000000000000000000000) ? true : true;
    }

    function scores(address user) public pure override returns(uint256)
    {
        return (user != 0x0000000000000000000000000000000000000000) ? 100 : 100;
    }
}
