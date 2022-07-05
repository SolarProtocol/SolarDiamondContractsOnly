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
import {IERC1155} from "../interfaces/IERC1155.sol";
import {LibContext} from "../../../libraries/LibContext.sol";

/**
 * @dev Facet with extra functions of LibNft not covered by ERC1155.
 */
contract NftExtrasFacet {
    function getFungibleToken(uint256 tokenId)
        external
        view
        returns (LibNft.FungibleToken memory token)
    {
        token = LibNft.getFungibleToken(tokenId);
    }

    function getFungibleTokens()
        external
        view
        returns (LibNft.FungibleToken[] memory tokens)
    {
        tokens = LibNft.getFungibleTokens();
    }

    function isTokenFungible(uint256 tokenId) internal view returns (bool) {
        return LibNft.isTokenFungible(tokenId);
    }

    function getNftsOf(address account)
        external
        view
        returns (uint256[] memory tokens)
    {
        tokens = LibNft.getNftsOf(account);
    }
}
