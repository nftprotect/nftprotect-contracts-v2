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

import "@openzeppelin/contracts/access/Ownable.sol";
import "./IUserRegistry.sol";
import "./Coupons.sol";
import "./IProtector.sol";
import "./INFTProtect2Core.sol";

contract NFTProtect2 is Ownable, INFTProtect2Core
{
    event Deployed();
    event TechnicalOwnerChanged(address);
    event ProtectorFactoryRegistered(IProtectorFactory);
    event ProtectorFactoryUnregistered(IProtectorFactory);
    event UserRegistryChanged(IUserRegistry);
    event MetaEvidenceLoaderChanged(address);

    struct Entity
    {
        address    originalOwner;
        address    wrappedOwner;
        Protection protection;
    }

    uint256                             public _entityCounter;
    address                             public _technicalOwner;
    mapping(IProtectorFactory=>uint256) public _factories;
    mapping(IProtector=>address)        public _protectorToOriginal;
    mapping(address=>IProtector)        public _originalToProtector;
    mapping(uint256=>Entity)            public _entities;
    IUserRegistry                       public _userRegistry;
    address                             public _metaEvidenceLoader;

    constructor()
    {
        emit Deployed();
    }

    modifier onlyFactory()
    {
        require(_factories[IProtectorFactory(_msgSender())]==1, "not factory");
        _;
    }

    modifier onlyProtector()
    {
        require(_protectorToOriginal[IProtector(_msgSender())]!=address(0), "not protector");
        _;
    }

    function registerProtectorFactory(IProtectorFactory factory) public onlyOwner()
    {
        _factories[factory]=1;
        emit ProtectorFactoryRegistered(factory);
    }

    function unregisterProtectorFactory(IProtectorFactory factory) public onlyOwner()
    {
        require(_factories[factory]==1, "no factory");
        delete _factories[factory];
        emit ProtectorFactoryUnregistered(factory);
    }

    function protectorCreated(IProtector pr, address original, address creator) external override onlyFactory()
    {
        _userRegistry.giveReward(creator);
        _protectorToOriginal[pr]=original;
        _originalToProtector[original]=pr;
    }

    function protector(address original) external view override returns(IProtector)
    {
        return _originalToProtector[original];
    }

    function technicalOwner() external view override returns(address)
    {
        return _technicalOwner;
    }

    function setTechnicalOwner(address tOwner) public onlyOwner()
    {
        _technicalOwner=tOwner;
        emit TechnicalOwnerChanged(tOwner);
    }

    function setMetaEvidenceLoader(address mel) public onlyOwner
    {
        _metaEvidenceLoader=mel;
        if (address(_userRegistry)!=address(0))
        {
            _userRegistry.setMetaEvidenceLoader(mel);
        }
        emit MetaEvidenceLoaderChanged(mel);
    }

    function setUserRegistry(IUserRegistry userRegistry) public onlyOwner()
    {
        _userRegistry=userRegistry;
        emit UserRegistryChanged(userRegistry);
    }

    function entityCreated(address creator, address referrer, Protection pr) external override payable onlyProtector() returns(uint256)
    {
        require(pr==Protection.Basic || _userRegistry.isQualified(_msgSender()), "not qualified");
        require(_userRegistry.isRegistered(_msgSender()), "unregistered");
        _userRegistry.processPayment{value: msg.value}(_msgSender(), payable(referrer), pr);
        uint256 entityId=++_entityCounter;
        _entities[entityId].originalOwner=creator;
        _entities[entityId].wrappedOwner=creator;
        _entities[entityId].protection=pr;
        return entityId;
    }

    function entityRequestForDelete(uint256 entityId, address from, address dst, uint256 arbitratorId, string memory evidence) public onlyProtector()
    {
        Entity memory entity=_entities[entityId];
        require(entity.originalOwner!=address(0), "no entity");
        if(entity.protection==Protection.Basic &&
            _userRegistry.trueUser(entity.originalOwner)==_userRegistry.trueUser(entity.wrappedOwner) &&
            _userRegistry.trueUser(entity.originalOwner)==_userRegistry.trueUser(from))
        {
            IProtector(_msgSender()).burnEntity(entityId, dst);
        }
        else
        {
            //TODO arbitrate
        }
    }

    function entityWrappedOwnerChanged(uint256 entityId, address owner) external onlyProtector()
    {
        Entity storage entity=_entities[entityId];
        require(entity.originalOwner!=address(0), "no entity");
        require(_userRegistry.isRegistered(owner), "not registered");
        entity.wrappedOwner=owner;
    }

    function entityUnderDisupte(uint256 entityId) external view returns(bool)
    {
        // TODO
        return false;
   }
}
