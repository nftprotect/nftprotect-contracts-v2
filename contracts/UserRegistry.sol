/*
This file is part of the NFT Protect project <https://nftprotect.app/>

The UserRegistry Contract is free software: you can redistribute it and/or
modify it under the terms of the GNU lesser General Public License as published
by the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

The UserRegistry Contract is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU lesser General Public License for more details.

You should have received a copy of the GNU lesser General Public License
along with the UserRegistry Contract. If not, see <http://www.gnu.org/licenses/>.

@author Ilya Svirin <is.svirin@gmail.com>
*/
// SPDX-License-Identifier: GNU lesser General Public License


pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./INFTProtect2Core.sol";
import "./IUserRegistry.sol";
import "./ArbitratorRegistry.sol";
import "./IUserDID.sol";
import "./IArbitrableProxy.sol";
import "./Coupons.sol";


contract UserRegistry is Ownable, IUserRegistry
{
    using Address for address payable;

    event Deployed();
    event ArbitratorRegistryChanged(ArbitratorRegistry areg);
    event AffiliatePercentChanged(uint256 percent);
    event AffiliatePayment(address indexed from, address indexed to, uint256 amountWei);
    event ReferrerSet(address indexed user, address indexed referrer);
    event PartnerSet(address indexed partnet, uint256 percent);
    event DIDRegistered(address indexed did, string provider);
    event DIDUnregistered(address indexed did);
    event SuccessorRequested(uint256 indexed requestId, address indexed user, address indexed successor);
    event SuccessorApproved(uint256 indexed requestId);
    event SuccessorRejected(uint256 indexed requestId);
    event ScoreThresholdChanged(uint256 threshold);
    event FeeChanged(Protection indexed pr, uint256 feeWei);
    event RewardedCouponsChanged(uint256);

    modifier onlyCore()
    {
        require(_msgSender() == address(_core));
        _;
    }

    mapping(Protection=>uint256) public   _feeWei;
    uint256                      public   _scoreThreshold;
    string                       public   _metaEvidenceURI;
    INFTProtect2Core             public   _core;
    Coupons                      public   _coupons;
    uint256                      public   _rewardedCoupons;
    address                      public   _metaEvidenceLoader;
    ArbitratorRegistry           public   _arbitratorRegistry;
    IUserDID[]                   public   _dids;
    uint256                      public   _affiliatePercent;
    uint256                      constant _numberOfRulingOptions = 2; // Notice that option 0 is reserved for RefusedToArbitrate

    mapping(address => address)         public _successors;
    mapping(address => address payable) public _referrers;
    mapping(address => uint256)         public _partners;

    struct SuccessorRequest
    {
        address          user;
        address          successor;
        IArbitrableProxy arbitrator;
        uint256          externalDisputeId;
        uint256          localDisputeId;
    }
    mapping(uint256 => SuccessorRequest) public _requests;
    uint256                              public _requestsCounter;

    constructor(address areg, IUserDID did, INFTProtect2Core core)
    {
        emit Deployed();
        _core=core;
        _metaEvidenceLoader=_msgSender();
        setAffiliatePercent(10);
        setArbitratorRegistry(areg);
        registerDID(did);
        setFee(Protection.Basic, 0);
        setFee(Protection.Ultra, 0);
        setScoreThreshold(0);
        _coupons=new Coupons();
        _coupons.transferOwnership(_msgSender());
    }
    
    function setArbitratorRegistry(address areg) public onlyOwner
    {
        _arbitratorRegistry=ArbitratorRegistry(areg);
        emit ArbitratorRegistryChanged(_arbitratorRegistry);
    }

    function setFee(Protection pr, uint256 fw) public onlyOwner
    {
        _feeWei[pr]=fw;
        emit FeeChanged(pr, fw);
    }

    function setRewardedCoupons(uint256 c) public onlyOwner
    {
        _rewardedCoupons=c;
        emit RewardedCouponsChanged(c);
    }

    function setScoreThreshold(uint256 threshold) public onlyOwner
    {
        _scoreThreshold=threshold;
        emit ScoreThresholdChanged(_scoreThreshold);
    }

    function setAffiliatePercent(uint256 percent) public onlyOwner
    {
        _affiliatePercent=percent;
        emit AffiliatePercentChanged(percent);
    }

    function setPartner(address partner, uint256 percent) public onlyOwner
    {
        _partners[partner]=percent;
        emit PartnerSet(partner, percent);
    }

    function processPayment(address user, address payable referrer, Protection pr) public override payable onlyCore
    {
        if (pr!=Protection.Ultra && _coupons.balanceOf(user)>0)
        {
            _coupons.burnFrom(user, 1);
            return;
        }
        uint fee=_feeWei[pr];
        require(msg.value==fee, "wrong payment");
        if (_referrers[user]==address(0) && referrer!=address(0))
        {
            _referrers[user]=referrer;
            emit ReferrerSet(user, referrer);
        }
        referrer=_referrers[user];
        uint256 value=msg.value;
        if (referrer!=address(0))
        {
            require(referrer!=user, "invalid referrer");
            uint256 percent=_partners[referrer]==0?_affiliatePercent:_partners[referrer];
            uint256 reward=value*percent/100;
            if (reward>0)
            {
                value-=reward;
                referrer.sendValue(reward);
                emit AffiliatePayment(user, referrer, reward);
            }
        }
        if (value>0)
        {
            payable(owner()).sendValue(value);
        }
    }

    function registerDID(IUserDID did) public onlyOwner
    {
        _dids.push(did);
        emit DIDRegistered(address(did), did.provider());
    }

    function unregisterDID(IUserDID did) public onlyOwner
    {
        for(uint256 i=0; i<_dids.length; ++i)
        {
            if(_dids[i]==did)
            {
                _dids[i]=_dids[_dids.length-1];
                _dids.pop();
                emit DIDUnregistered(address(did));
                break;
            }
        }
    }

    function isRegistered(address user) public view override returns(bool)
    {
        for(uint256 i=0; i<_dids.length; ++i)
        {
            if(_dids[i].isIdentified(user))
            {
                return true;
            }
        }
        return false;
    }

    function isQualified(address user) public view override returns(bool)
    {
        uint256 scoresMax=0;
        for(uint256 i=0; i<_dids.length; ++i)
        {
            uint256 scoresCur=_dids[i].scores(user);
            if(scoresCur>scoresMax)
            {
                scoresMax=scoresCur;
            }
        }
        return scoresMax>=_scoreThreshold;
    }

    function trueUser(address user) public view override returns(address)
    {
        address tuser=user;
        while(_successors[tuser]!=address(0))
        {
            tuser=_successors[tuser];
        }
        return tuser;
    }

    function giveReward(address user) public onlyCore
    {
        _coupons.mint(user, _rewardedCoupons);
    }

    function setMetaEvidenceLoader(address mel) public override onlyCore
    {
        _metaEvidenceLoader=mel;
    }

    function successorRequest(address user, uint256 arbitratorId, string memory evidence) public payable returns(uint256)
    {
        require(isRegistered(user), "unregistered user");
        IArbitrableProxy arbitrableProxy;
        bytes memory extraData;
        (arbitrableProxy, extraData)=_arbitratorRegistry.arbitrator(arbitratorId);
        uint256 externalDisputeId=arbitrableProxy.createDispute{value: msg.value}(extraData, _metaEvidenceURI, _numberOfRulingOptions);
        uint256 disputeId=arbitrableProxy.externalIDtoLocalID(externalDisputeId);
        _requestsCounter++;
        _requests[_requestsCounter]=SuccessorRequest(user, _msgSender(), arbitrableProxy, disputeId, externalDisputeId);
        emit SuccessorRequested(_requestsCounter, user, _msgSender());
        arbitrableProxy.submitEvidence(disputeId, evidence);
        return _requestsCounter;
    }

    function submitMetaEvidence(string memory evidence) public
    {
        require(_msgSender()==_metaEvidenceLoader, "forbidden");
        _metaEvidenceURI=evidence;
    }

    function fetchRuling(uint256 requestId) external
    {
        SuccessorRequest memory request=_requests[requestId];
        IArbitrableProxy arbitrator=request.arbitrator;
        (, bool isRuled, uint256 ruling,)=arbitrator.disputes(request.localDisputeId);
        require(isRuled, "ruling pending");
        if (ruling==1)
        {
            _successors[request.user]=request.successor;
            emit SuccessorApproved(requestId);
        }
        else
        {
            emit SuccessorRejected(requestId);
        }
        delete _requests[requestId];
    }
}
