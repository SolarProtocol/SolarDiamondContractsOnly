// SPDX-License-Identifier: MIT

//////////////////////////////////////////////solarprotocol.io//////////////////////////////////////////
//_____/\\\\\\\\\\\_________/\\\\\_______/\\\__0xFluffyBeard__/\\\\\\\\\_______/\\\\\\\\\_____        //
// ___/\\\/////////\\\_____/\\\///\\\____\/\\\____vbranden___/\\\\\\\\\\\\\___/\\\///////\\\___       //
//  __\//\\\______\///____/\\\/__\///\\\__\/\\\______________/\\\/////////\\\_\/\\\_____\/\\\___      //
//   ___\////\\\__________/\\\______\//\\\_\/\\\_____________\/\\\_______\/\\\_\/\\\\\\\\\\\/____     //
//    ______\////\\\______\/\\\_______\/\\\_\/\\\_____________\/\\\\\\\\\\\\\\\_\/\\\//////\\\____    //
//     _________\////\\\___\//\\\______/\\\__\/\\\_____________\/\\\/////////\\\_\/\\\____\//\\\___   //
//      __/\\\______\//\\\___\///\\\__/\\\____\/\\\_____________\/\\\_______\/\\\_\/\\\_____\//\\\__  //
//       _\///\\\\\\\\\\\/______\///\\\\\/_____\/\\\\\\\\\\\\\\\_\/\\\_______\/\\\_\/\\\______\//\\\_ //
//        ___\///////////__________\/////_______\///////////////__\///________\///__\///________\///__//
////////////////////////////////////////////////////////////////////////////////////////////////////////

pragma solidity ^0.8.9;

import {LibNft} from "../libraries/LibNft.sol";
import {LibDiamond} from "contracts-starter/contracts/libraries/LibDiamond.sol";

/**
 * @dev Facet with admin functions of LibNft to be used in tests.
 */
contract NftAdminTestFacet {
    function createFungibleToken(string calldata name, string calldata symbol)
        external
        returns (uint256 tokenId)
    {
        LibDiamond.enforceIsContractOwner();

        tokenId = LibNft.createFungibleToken(name, symbol);
    }

    function createFungibleTokens(
        string[] calldata names,
        string[] calldata symbols
    ) external returns (uint256[] memory tokenIds) {
        LibDiamond.enforceIsContractOwner();

        require(
            names.length == symbols.length,
            "Names and Symbols not same size"
        );

        for (uint256 index = 0; index < names.length; index++) {
            tokenIds[index] = LibNft.createFungibleToken(
                names[index],
                symbols[index]
            );
        }
    }

    function updateFungibleToken(
        uint256 tokenId,
        string calldata name,
        string calldata symbol
    ) external {
        LibDiamond.enforceIsContractOwner();

        LibNft.updateFungibleToken(tokenId, name, symbol);
    }

    function updateFungibleTokens(
        uint256[] calldata tokenIds,
        string[] calldata names,
        string[] calldata symbols
    ) external {
        LibDiamond.enforceIsContractOwner();

        require(
            names.length == symbols.length,
            "Names and Symbols not same size"
        );

        for (uint256 index = 0; index < names.length; index++) {
            LibNft.updateFungibleToken(
                tokenIds[index],
                names[index],
                symbols[index]
            );
        }
    }

    function mintFungible(
        address account,
        uint256 tokenId,
        uint256 amount
    ) internal {
        LibDiamond.enforceIsContractOwner();

        LibNft.mintFungible(account, tokenId, amount);
    }

    function mintFungibleBatch(
        address account,
        uint256[] memory tokenIds,
        uint256[] memory amounts
    ) external {
        LibDiamond.enforceIsContractOwner();

        LibNft.mintFungibleBatch(account, tokenIds, amounts);
    }

    function mintNft(address account) external returns (uint256 tokenId) {
        tokenId = LibNft.mintNft(account);
    }

    function mintNftBatch(address account, uint256 amount)
        external
        returns (uint256[] memory tokenIds)
    {
        LibDiamond.enforceIsContractOwner();

        tokenIds = LibNft.mintNftBatch(account, amount);
    }
}
