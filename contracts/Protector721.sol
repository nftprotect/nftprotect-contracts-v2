/*
This file is part of the NFT Protect project <https://nftprotect.app/>

The NFTProtect2 Contract is free software: you can redistribute it and/or
modify it under the terms of the GNU lesser General Public License as published
by the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

The NFTProtect2 Contract is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU lesser General Public License for more details.

You should have received a copy of the GNU lesser General Public License
along with the NFTProtect2 Contract. If not, see <http://www.gnu.org/licenses/>.

@author Ilya Svirin <is.svirin@gmail.com>
*/
// SPDX-License-Identifier: GNU lesser General Public License


pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./IProtector.sol";
import "./INFTProtect2Core.sol";
import "./ERC20Rescue.sol";

contract ProtectorFactory721 is IProtectorFactory, Context, ERC20Rescue
{
    INFTProtect2Core public _core;

    constructor(INFTProtect2Core core)
    {
        _core=core;
    }

    function factoryName() public pure override returns(string memory)
    {
        return("ERC721");
    }

    function createProtector(address original, string memory name, string memory symbol) public returns(IProtector)
    {
        Protector721 protector=new Protector721(_core, IERC721(original), name, symbol);
        emit ProtectorCreated(protector, original);
        protector.transferOwnership(_core.technicalOwner());
        _core.onProtectorCreated(protector, original, _msgSender());
        return protector;
    } 

    function createProtector(address original) external returns(IProtector)
    {
        require(_core.protector(original)==IProtector(address(0)), "Already have protector");
        string memory name="NFTP";
        string memory symbol="NFT Protect";
        if(IERC165(original).supportsInterface(type(IERC721Metadata).interfaceId))
        {
            name=string(abi.encodePacked("NFTProtect: ", IERC721Metadata(original).name()));
            symbol=string(abi.encodePacked("NFTP-", IERC721Metadata(original).symbol()));
        }
        return createProtector(original, name, symbol);
    }
}

contract Protector721 is IProtector, ERC721, IERC721Receiver, Ownable
{
    INFTProtect2Core            public   _core;
    IERC721                     public   _original;
    mapping(uint256 => uint256) public   _tokenIdToEntity;
    mapping(uint256 => uint256) public   _entityToTokenId;
    string                      public   _base;
    uint256                     internal _allow;

    modifier onlyCore()
    {
        require(address(_core)==_msgSender(), "forbidden");
        _;
    }

    constructor(
            INFTProtect2Core core,
            IERC721          original,
            string memory    name,
            string memory    symbol) ERC721(name, symbol) Ownable(msg.sender)
    {
        _core=core;
        _original=original;
        setBase("");
    }

    function setBase(string memory b) public onlyOwner
    {
        _base=b;
    }

    function _baseURI() internal view override returns(string memory)
    {
        return _base;
    }

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for original
     * token, protected in `tokenId` token.
     */
    function tokenURI(uint256 tokenId) public view override returns(string memory)
    {
     //   require(_exists(tokenId));
        if(bytes(_base).length==0 && IERC165(_original).supportsInterface(type(IERC721Metadata).interfaceId))
        {
            return IERC721Metadata(address(_original)).tokenURI(tokenId);
        }
        return super.tokenURI(tokenId);
    }

    /**
     * @dev Accept only tokens which internally allowed by `_allow` property
     */
    function onERC721Received(address, address, uint256, bytes calldata) public view override returns (bytes4)
    {
        require(_allow==1);
        return this.onERC721Received.selector;
    }

    /**
     * @dev Protect token. Owner of token must approve 'tokenId' token for Protector721 contract
     * to make it possible to transferFrom this tokens from the owner to Protector721 contract.
     * Mint protected token for the owner.
     * If referrer is given, pay affiliatePercent of user payment to him.
     * Protected token will have the same 'tokenId' as original one.
     */
    function protect(uint256 tokenId, Protection pr, address payable referrer) public payable
    {
        require(_tokenIdToEntity[tokenId]==0, "already protected");
        uint256 entityId=_core.onEntityCreated{value: msg.value}(_msgSender(), referrer, pr);
        _mint(_msgSender(), tokenId);
        _tokenIdToEntity[tokenId]=entityId;
        _entityToTokenId[entityId]=tokenId;
        _allow=1;
        _original.safeTransferFrom(_msgSender(), address(this), tokenId);
        _allow=0;
        emit Protected(entityId, pr);
    }

    function burnEntity(uint256 entityId, address dst) public onlyCore
    {
        uint256 tokenId=_entityToTokenId[entityId];
        super._burn(tokenId);
        _original.safeTransferFrom(address(this), dst, tokenId);
        delete _entityToTokenId[entityId];
        delete _tokenIdToEntity[tokenId];
        emit Unprotected(entityId);
    }

    function transferEntity(uint256 entityId, address newowner) public onlyCore
    {
        uint256 tokenId=_entityToTokenId[entityId];
        _transfer(ownerOf(tokenId), newowner, tokenId);
    }

    function _update(address to, uint256 tokenId, address auth) internal virtual override returns (address)
    {
        address from = super._update(to, tokenId, auth);
        uint256 entityId=_tokenIdToEntity[tokenId];
        require(entityId!=0, "not protected");
        require(!_core.entityUnderDisupte(_tokenIdToEntity[tokenId]), "under dispute");
        _core.onEntityWrappedOwnerChanged(entityId, to);
        return from;
    }
    
}
