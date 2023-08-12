/*
This file is part of the NFT Protect project <https://nftprotect.app/>

The RequestsHub Contract is free software: you can redistribute it and/or
modify it under the terms of the GNU lesser General Public License as published
by the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

The RequestsHub Contract is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU lesser General Public License for more details.

You should have received a copy of the GNU lesser General Public License
along with the RequestsHub Contract. If not, see <http://www.gnu.org/licenses/>.

@author Ilya Svirin <is.svirin@gmail.com>
*/
// SPDX-License-Identifier: GNU lesser General Public License


pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./INFTProtect2Core.sol";
import "./ArbitratorRegistry.sol";
import "./IUserRegistry.sol";
import "./IRequestHub.sol";


contract RequestsHub is Ownable, IRequestHub, ERC20Rescue
{
    event Deployed();
    event ArbitratorRegistryChanged(ArbitratorRegistry);

    address             public  _metaEvidenceLoader;
    ArbitratorRegistry  public  _arbitratorRegistry;
    INFTProtect2Core    public  _core;
    IUserRegistry       public  _userRegistry;
    uint256             public  _requestsCounter;

    modifier onlyCore()
    {
        require(_msgSender() == address(_core));
        _;
    }

    enum Status
    {
        Initial,
        Accepted,
        Rejected,
        Disputed
    }
    enum ReqType
    {
        OwnershipAdjustment,
        OwnershipRestore,
        Burn
    }
    struct Request
    {
        ReqType          reqtype; 
        uint256[]        entities;
        address          newowner;
        uint256          timeout;
        Status           status;
        uint256          arbitratorId;
        uint256          localDisputeId;
        uint256          externalDisputeId;
        MetaEvidenceType metaevidence;
    }
    mapping(MetaEvidenceType=>string)   public      _metaEvidences;
    uint256                             constant    _duration=2 days;
    uint256                             constant    _numberOfRulingOptions=2; // Notice that option 0 is reserved for RefusedToArbitrate
    mapping(uint256=>Request)           public      _requests;
    mapping(uint256=>uint256)           public      _entityToRequest;
    mapping(uint256=>uint256)           public      _disputeToRequest;

    constructor(address areg, INFTProtect2Core core)
    {
        emit Deployed();    
        _core=core;
        setArbitratorRegistry(areg);
    }

    function setMetaEvidenceLoader(address mel) public onlyCore
    {
        _metaEvidenceLoader=mel;
    }

    function setArbitratorRegistry(address areg) public onlyOwner
    {
        _arbitratorRegistry=ArbitratorRegistry(areg);
        emit ArbitratorRegistryChanged(_arbitratorRegistry);
    }

    function setUserRegistry(IUserRegistry userRegistry) public override onlyCore
    {
        _userRegistry=userRegistry;
    }

    function hasRequest(uint256 entityId) public view override returns(bool)
    {
        uint256 requestId=_entityToRequest[entityId];
        if (requestId!=0)
        {
            Request memory request=_requests[requestId];
            return (request.timeout<block.timestamp &&
                request.status==Status.Initial) ||
                request.status==Status.Disputed;
        }
        return false;
    }

    function burn(uint256[] calldata entities, address dst, uint256 arbitratorId, string memory evidence) public override payable
    {
        if (dst==address(0))
        {
            dst=_msgSender();
        }
        uint256 requestId=++_requestsCounter;
        uint256[] memory foo;
        _requests[requestId]=Request(
            ReqType.Burn,
            foo,
            dst,
            0,
            Status.Disputed,
            arbitratorId,
            0,
            0,
            MetaEvidenceType.burn);
        Request storage request=_requests[requestId];

        for(uint256 i=0; i<entities.length; ++i)
        {
            uint256 entityId=entities[i];
            address originalOwner;
            address wrappedOwner;
            Protection protection;
            (originalOwner, wrappedOwner, protection)=_core.entityInfo(entityId);
            require(!hasRequest(entityId), "have request");
            require(_userRegistry.trueUser(_msgSender())==_userRegistry.trueUser(originalOwner), "not owner");
            if(protection==Protection.Basic)
            {
                _core.applyBurn(entityId, dst);
            }
            else
            {
                require(dst!=_msgSender(), "bad dst");
                if(request.entities.length==0)
                {
                    emit BurnArbitrateAsked(requestId, dst);
                }
                request.entities.push(entityId);
                _entityToRequest[entityId]=requestId;
                emit EntityAddedToRequest(requestId, entityId, originalOwner, dst);
            }
        }

        if(request.entities.length==0)
        {
            delete _requests[requestId];
            --_requestsCounter;
        }
        else
        {
            IArbitrableProxy arbitrableProxy;
            bytes memory extraData;
            (arbitrableProxy, extraData)=_arbitratorRegistry.arbitrator(arbitratorId);
            request.externalDisputeId=arbitrableProxy.createDispute{value: msg.value}(extraData, _metaEvidences[MetaEvidenceType.burn], _numberOfRulingOptions);
            request.localDisputeId=arbitrableProxy.externalIDtoLocalID(request.externalDisputeId);
            arbitrableProxy.submitEvidence(request.localDisputeId, evidence);
            _disputeToRequest[request.localDisputeId]=requestId;
        }
    }

    function adjustOwnership(uint256[] calldata entities, uint256 arbitratorId, string memory evidence) public override payable
    {
        uint256 requestId=++_requestsCounter;
        uint256[] memory foo;
        _requests[requestId]=Request(
            ReqType.OwnershipAdjustment,
            foo,
            address(0),
            0,
            Status.Disputed,
            arbitratorId,
            0,
            0,
            MetaEvidenceType.adjustOwnership);
        Request storage request=_requests[requestId];

        for(uint256 i=0; i<entities.length; ++i)
        {
            uint256 entityId=entities[i];
            address originalOwner;
            address wrappedOwner;
            Protection protection;
            (originalOwner, wrappedOwner, protection)=_core.entityInfo(entityId);
            require(!hasRequest(entityId), "have request");
            require(_userRegistry.trueUser(_msgSender())==_userRegistry.trueUser(originalOwner), "not owner");
            if(protection==Protection.Basic)
            {
                emit OwnershipAdjusted(wrappedOwner, _msgSender(), entityId);
                _core.applyOwnershipAdjustment(entityId, address(0));
            }
            else
            {
                if(request.entities.length==0)
                {
                    emit OwnershipAdjustmentAsked(requestId, _msgSender());
                }
                request.entities.push(entityId);
                _entityToRequest[entityId]=requestId;
                emit EntityAddedToRequest(requestId, entityId, originalOwner, wrappedOwner);
            }
        }

        if(request.entities.length==0)
        {
            delete _requests[requestId];
            --_requestsCounter;
        }
        else
        {
            IArbitrableProxy arbitrableProxy;
            bytes memory extraData;
            (arbitrableProxy, extraData)=_arbitratorRegistry.arbitrator(arbitratorId);
            request.externalDisputeId=arbitrableProxy.createDispute{value: msg.value}(extraData, _metaEvidences[MetaEvidenceType.adjustOwnership], _numberOfRulingOptions);
            request.localDisputeId=arbitrableProxy.externalIDtoLocalID(request.externalDisputeId);
            arbitrableProxy.submitEvidence(request.localDisputeId, evidence);
            _disputeToRequest[request.localDisputeId]=requestId;
        }
    }

    function askOwnershipAdjustment(uint256[] calldata entities, address dst, uint256 arbitratorId) public override 
    {
        if (dst==address(0))
        {
            dst=_msgSender();
        }
        uint256 requestId=++_requestsCounter;
        uint256[] memory foo;
        _requests[requestId]=Request(
            ReqType.OwnershipAdjustment,
            foo,
            dst,
            block.timestamp+_duration,
            Status.Initial,
            arbitratorId,
            0,
            0,
            MetaEvidenceType.answerOwnershipAdjustment);
        Request storage request=_requests[requestId];

        for(uint256 i=0; i<entities.length; ++i)
        {
            uint256 entityId=entities[i];
            address originalOwner;
            address wrappedOwner;
            Protection protection;
            (originalOwner, wrappedOwner, protection)=_core.entityInfo(entityId);
            require(!hasRequest(entityId), "have request");
            require(_userRegistry.trueUser(_msgSender())!=_userRegistry.trueUser(originalOwner), "already owner");
            require(_userRegistry.trueUser(_msgSender())==_userRegistry.trueUser(wrappedOwner), "not owner");
            if(protection==Protection.Ultra)
            {
                require(dst!=_msgSender(), "bad dst");
            }
            if(request.entities.length==0)
            {
                emit OwnershipAdjustmentAsked(requestId, dst);
            }
            request.entities.push(entityId);
            _entityToRequest[entityId]=requestId;
            emit EntityAddedToRequest(requestId, entityId, originalOwner, dst);
        }

        require(request.entities.length>0, "no entities");
        IArbitrableProxy arbitrableProxy;
        (arbitrableProxy, )=_arbitratorRegistry.arbitrator(arbitratorId);
        require(address(arbitrableProxy)!=address(0), "no arbitrator");
    }

    /** @dev Must be called by the owner of the original entity to confirm or reject
     *  ownership transfer to the new owner of the wrapper entity.
     */
    function answerOwnershipAdjustment(uint256 requestId, bool accept, string memory evidence) public override payable
    {
        Request storage request=_requests[requestId];
        require(request.status==Status.Initial || request.status==Status.Rejected, "answered");
        //require(request.timeout>block.timestamp, "timeout");

        bool isUltra=false;
        for(uint256 i=0; i<request.entities.length; ++i)
        {
            uint256 entityId=request.entities[i];
            address originalOwner;
            address wrappedOwner;
            Protection protection;
            (originalOwner, wrappedOwner, protection)=_core.entityInfo(entityId);
            if(protection==Protection.Ultra)
            {
                isUltra=true;
            }
            require(_userRegistry.trueUser(_msgSender())==_userRegistry.trueUser(originalOwner), "not owner");
        }

        if (accept)
        {
            if (!isUltra)
            {
                request.status=Status.Accepted;
                emit OwnershipAdjustmentAnswered(requestId, accept);
                for(uint256 i=0; i<request.entities.length; ++i)
                {
                    uint256 entityId=request.entities[i];
                    _core.applyOwnershipAdjustment(entityId, request.newowner);
                    delete _entityToRequest[entityId];
                }
            }
            else
            {
                IArbitrableProxy arbitrableProxy;
                bytes memory extraData;
                (arbitrableProxy, extraData)=_arbitratorRegistry.arbitrator(request.arbitratorId);
                request.externalDisputeId=arbitrableProxy.createDispute{value: msg.value}(extraData, _metaEvidences[MetaEvidenceType.answerOwnershipAdjustment], _numberOfRulingOptions);
                request.localDisputeId=arbitrableProxy.externalIDtoLocalID(request.externalDisputeId);
                arbitrableProxy.submitEvidence(request.localDisputeId, evidence);
                request.status=Status.Disputed;
                _disputeToRequest[request.localDisputeId]=requestId;
                emit OwnershipAdjustmentArbitrateAsked(requestId, request.newowner);
            }
        }
        else
        {
            request.status=Status.Rejected;
            emit OwnershipAdjustmentAnswered(requestId, accept);
        }
    }

    function askOwnershipAdjustmentArbitrate(uint256 requestId, string memory evidence) public override payable
    {
        Request storage request=_requests[requestId];
        require(request.timeout>0, "unknown request");
        require(request.status==Status.Initial || request.status==Status.Rejected, "wrong status");
        require(request.status==Status.Rejected || request.timeout<=block.timestamp, "wait for answer");
        IArbitrableProxy arbitrableProxy;
        bytes memory extraData;
        (arbitrableProxy, extraData)=_arbitratorRegistry.arbitrator(request.arbitratorId);
        request.externalDisputeId=arbitrableProxy.createDispute{value: msg.value}(extraData, _metaEvidences[MetaEvidenceType.askOwnershipAdjustmentArbitrate], _numberOfRulingOptions);
        request.localDisputeId=arbitrableProxy.externalIDtoLocalID(request.externalDisputeId);
        arbitrableProxy.submitEvidence(request.localDisputeId, evidence);
        request.status=Status.Disputed;
        _disputeToRequest[request.localDisputeId]=requestId;
        emit OwnershipAdjustmentArbitrateAsked(requestId, request.newowner);
    }

    function askOwnershipRestoreArbitrate(uint256[] calldata entities, address dst, uint256 arbitratorId, MetaEvidenceType metaEvidenceType, string memory evidence) public override payable
    {
        require(
            metaEvidenceType==MetaEvidenceType.askOwnershipRestoreArbitrateMistake ||
            metaEvidenceType==MetaEvidenceType.askOwnershipRestoreArbitratePhishing ||
            metaEvidenceType==MetaEvidenceType.askOwnershipRestoreArbitrateProtocolBreach,
            "wrong MetaEvidence");
        if (dst==address(0))
        {
            dst=_msgSender();
        }
        uint256 requestId=++_requestsCounter;
        uint256[] memory foo;
        _requests[requestId]=Request(
            ReqType.OwnershipRestore,
            foo,
            dst,
            0,
            Status.Disputed,
            arbitratorId,
            0,
            0,
            metaEvidenceType);
        Request storage request=_requests[requestId];

        for(uint256 i=0; i<entities.length; ++i)
        {
            uint256 entityId=entities[i];
            address originalOwner;
            address wrappedOwner;
            Protection protection;
            (originalOwner, wrappedOwner, protection)=_core.entityInfo(entityId);
            require(!hasRequest(entityId), "have request");
            require(_userRegistry.trueUser(_msgSender())==_userRegistry.trueUser(originalOwner), "not owner");
            require(_userRegistry.trueUser(_msgSender())!=_userRegistry.trueUser(wrappedOwner), "already owner");
            if(protection==Protection.Ultra)
            {
                require(dst!=_msgSender(), "bad dst");
            }
            if(request.entities.length==0)
            {
                emit OwnershipRestoreAsked(requestId, dst);
            }
            request.entities.push(entityId);
            _entityToRequest[entityId]=requestId;
            emit EntityAddedToRequest(requestId, entityId, originalOwner, dst);
        }

        require(request.entities.length>0, "no entities");
        IArbitrableProxy arbitrableProxy;
        bytes memory extraData;
        (arbitrableProxy, extraData)=_arbitratorRegistry.arbitrator(arbitratorId);
        request.externalDisputeId=arbitrableProxy.createDispute{value: msg.value}(extraData, _metaEvidences[metaEvidenceType], _numberOfRulingOptions);
        request.localDisputeId=arbitrableProxy.externalIDtoLocalID(request.externalDisputeId);
        arbitrableProxy.submitEvidence(request.localDisputeId, evidence);
        _disputeToRequest[request.localDisputeId]=requestId;
    }

    function submitMetaEvidence(MetaEvidenceType evidenceType, string memory evidence) public override
    {
        require(_msgSender()==_metaEvidenceLoader, "forbidden");
        _metaEvidences[evidenceType]=evidence;
    }

    /**
     * @dev Fetch the ruling that is stored in the arbitrable proxy.
     * value is: 0 - RefusedToArbitrate, 1 - Accepted, 2 - Rejected.
     */
    function fetchRuling(uint256 requestId) external
    {
        require(requestId>0, "unknown requestId");
        Request storage request=_requests[requestId];
        require(request.status!=Status.Accepted && request.status!=Status.Rejected, "request over");
        IArbitrableProxy arbitrableProxy;
        (arbitrableProxy, )=_arbitratorRegistry.arbitrator(request.arbitratorId);
        (, bool isRuled, uint256 ruling,)=arbitrableProxy.disputes(request.localDisputeId);
        require(isRuled, "ruling pending");
        bool accept=(ruling==1);
        request.status=accept?Status.Accepted:Status.Rejected;
        if (request.reqtype==ReqType.OwnershipAdjustment)
        {
            emit OwnershipAdjustmentAnswered(requestId, accept);
        }
        else if (request.reqtype==ReqType.OwnershipRestore)
        {
            emit OwnershipRestoreAnswered(requestId, accept);
        }
        else if (request.reqtype==ReqType.Burn)
        {
            emit BurnAnswered(requestId, accept);
        }
        if (accept)
        {
            for(uint256 i=0; i<request.entities.length; ++i)
            {
                uint256 entityId=request.entities[i];
                delete _entityToRequest[entityId];
                if (request.reqtype==ReqType.OwnershipAdjustment)
                {
                    _core.applyOwnershipAdjustment(entityId, request.newowner);
                }
                else if (request.reqtype == ReqType.OwnershipRestore)
                {
                    _core.applyOwnershipRestore(entityId, request.newowner);
                }
                else if (request.reqtype == ReqType.Burn)
                {
                    _core.applyBurn(entityId, request.newowner);
                }
            }
        }
    }
}
