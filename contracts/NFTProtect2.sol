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
import "./IRequestHub.sol";
import "./INFTProtect2Core.sol";
import "./ERC20Rescue.sol";


contract NFTProtect2 is Ownable, ERC20Rescue, INFTProtect2Core
{
    event Deployed();
    event TechnicalOwnerChanged(address);
    event ProtectorFactoryRegistered(IProtectorFactory);
    event ProtectorFactoryUnregistered(IProtectorFactory);
    event UserRegistryChanged(IUserRegistry);
    event MetaEvidenceLoaderChanged(address);
    event RequestHubChanged(IRequestHub);
    event BurnOnActionChanged(bool boa);

    struct Entity
    {
        address    originalOwner;
        address    wrappedOwner;
        Protection protection;
        IProtector protector;
    }

    uint256                             public _entityCounter;
    address                             public _technicalOwner;
    mapping(IProtectorFactory=>uint256) public _factories;
    mapping(IProtector=>address)        public _protectorToOriginal;
    mapping(address=>IProtector)        public _originalToProtector;
    mapping(uint256=>Entity)            public _entities;
    IUserRegistry                       public _userRegistry;
    IRequestHub                         public _requestHub;
    address                             public _metaEvidenceLoader;
    bool                                public _burnOnAction;

    constructor()
    {
        emit Deployed();
        setBurnOnAction(true);
    }

    function setBurnOnAction(bool boa) public onlyOwner
    {
        _burnOnAction=boa;
        emit BurnOnActionChanged(boa);
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

    modifier onlyRequestHub()
    {
        require(_msgSender()==address(_requestHub), "not request hub");
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

    function protectorCreated(IProtector pr, address original, address creator) public override onlyFactory()
    {
        _userRegistry.giveReward(creator);
        _protectorToOriginal[pr]=original;
        _originalToProtector[original]=pr;
    }

    function protector(address original) public view override returns(IProtector)
    {
        return _originalToProtector[original];
    }

    function technicalOwner() public view override returns(address)
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
        _requestHub.setUserRegistry(_userRegistry);
        emit UserRegistryChanged(userRegistry);
    }

    function setRequestHub(IRequestHub requestHub) public onlyOwner()
    {
        _requestHub=requestHub;
        _requestHub.setUserRegistry(_userRegistry);
        emit RequestHubChanged(requestHub);
    }

    function entityCreated(address creator, address referrer, Protection pr) public override payable onlyProtector() returns(uint256)
    {
        require(pr==Protection.Basic || _userRegistry.isQualified(creator), "not qualified");
        require(_userRegistry.isRegistered(creator), "unregistered");
        _userRegistry.processPayment{value: msg.value}(creator, payable(referrer), pr);
        uint256 entityId=++_entityCounter;
        _entities[entityId].originalOwner=creator;
        _entities[entityId].wrappedOwner=creator;
        _entities[entityId].protection=pr;
        _entities[entityId].protector=IProtector(_msgSender());
        return entityId;
    }

    function entityWrappedOwnerChanged(uint256 entityId, address owner) public override onlyProtector()
    {
        Entity storage entity=_entities[entityId];
        require(entity.originalOwner!=address(0), "no entity");
        require(_userRegistry.isRegistered(owner), "not registered");
        entity.wrappedOwner=owner;
    }

    function entityUnderDisupte(uint256 entityId) public view override returns(bool)
    {
        if(address(_requestHub)!=address(0))
        {
            return _requestHub.hasRequest(entityId);
        }
        return false;
   }

    function entityInfo(uint256 entityId) external view returns(
            address    originalOwner,
            address    wrappedOwner,
            Protection protection)
    {
        Entity memory entity=_entities[entityId];
        return(entity.originalOwner, entity.wrappedOwner, entity.protection);
    }

    function applyBurn(uint256 entityId, address dst) public override onlyRequestHub
    {
        _burnEntity(entityId, dst);
    }

    function applyOwnershipAdjustment(uint256 entityId, address dst) public override onlyRequestHub
    {
        Entity storage entity=_entities[entityId];
        require(entity.originalOwner!=address(0), "no entity");
        if (dst==address(0))
        {
            dst=entity.wrappedOwner;
        }
        entity.originalOwner=dst;
        if (_burnOnAction)
        {
            _burnEntity(entityId, dst);
        }
    }

    function applyOwnershipRestore(uint256 entityId, address dst) public override onlyRequestHub
    {
        Entity storage entity=_entities[entityId];
        require(entity.originalOwner!=address(0), "no entity");
        entity.protector.transferEntity(entityId, dst);
        if (_burnOnAction)
        {
            _burnEntity(entityId, dst);
        }
    }

    function _burnEntity(uint256 entityId, address dst) internal
    {
        Entity storage entity=_entities[entityId];
        require(entity.originalOwner!=address(0), "no entity");
        entity.protector.burnEntity(entityId, dst);
        delete _entities[entityId];
    }
}
