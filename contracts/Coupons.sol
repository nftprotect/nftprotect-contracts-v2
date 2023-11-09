/*
This file is part of the NFT Protect project <https://nftprotect.app/>

The Coupons Contract is free software: you can redistribute it and/or
modify it under the terms of the GNU lesser General Public License as published
by the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

The Coupons Contract is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU lesser General Public License for more details.

You should have received a copy of the GNU lesser General Public License
along with the Coupons Contract. If not, see <http://www.gnu.org/licenses/>.

@author Ilya Svirin <is.svirin@gmail.com>
*/
// SPDX-License-Identifier: GNU lesser General Public License


pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./ERC20Rescue.sol";


contract Coupons is Ownable, ERC20, ERC20Rescue
{
    event Deployed();
    event TransferrableSet(bool state);
    
    bool    public _transferrable;
    address public _controller;

    modifier controllerOrOwner()
    {
        require(_msgSender()==_controller || _msgSender()==owner(), "forbidden");
        _;
    }

    constructor() ERC20("NFT Protect Coupons", "NFTPC")
    {
        emit Deployed();
        setTransferrable(true);
        _controller=_msgSender();
    }

    function decimals() public view virtual override returns (uint8)
    {
        return 0;
    }

    function setController(address controller) public onlyOwner
    {
        _controller=controller;
    }

    function setTransferrable(bool state) public onlyOwner
    {
        _transferrable=state;
        emit TransferrableSet(state);        
    }

    function mint(address account, uint256 amount) public controllerOrOwner
    {
        _mint(account, amount);
    }

    function burnFrom(address account, uint256 amount) public controllerOrOwner
    {
        _burn(account, amount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 /*amount*/) internal view
    {
        require(_transferrable || from==address(0) || to==address(0), "non-transferrable");
    }
}
