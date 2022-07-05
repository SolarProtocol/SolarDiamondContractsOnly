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

import {LibDiamondExtras} from "../modules/diamond/LibDiamondExtras.sol";
import {ISimpleBlacklist} from "../modules/blacklist/ISimpleBlacklist.sol";
import {IPausable} from "../modules/pausable/IPausable.sol";
import {IERC1155} from "../modules/nft/interfaces/IERC1155.sol";
import {LibAccessControl} from "../modules/access/LibAccessControl.sol";
import {LibRoles} from "../modules/access/LibRoles.sol";
import {LibSoloToken} from "../modules/solo-token/LibSoloToken.sol";
import {LibDiamond} from "contracts-starter/contracts/libraries/LibDiamond.sol";
import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";

/**
 * @dev TMP contract for diamond initialization.
 * TODO: REPLACE WITH PROPER MIGRATIONS!!!
 */
contract DeployInit {
    function init(
        string calldata tokenName,
        string calldata tokenSymbol,
        address[] calldata vaults_,
        uint256[] calldata vaultMints_
    ) external {
        require(
            vaults_.length == vaultMints_.length,
            "length of _vaults != _mints"
        );

        bytes4[] memory interfaceIds = new bytes4[](4);

        interfaceIds[0] = type(IAccessControl).interfaceId;
        interfaceIds[1] = type(ISimpleBlacklist).interfaceId;
        interfaceIds[2] = type(IPausable).interfaceId;
        interfaceIds[3] = type(IERC1155).interfaceId;

        LibDiamondExtras.setERC165(interfaceIds);

        LibAccessControl.grantRole(
            LibRoles.DEFAULT_ADMIN_ROLE,
            LibDiamond.contractOwner()
        );

        if (LibSoloToken.totalSupply() == 0) {
            LibSoloToken.init(tokenName, tokenSymbol, new address[](0), true);

            for (uint256 index = 0; index < vaults_.length; index++) {
                LibSoloToken.mint(
                    vaults_[index],
                    vaultMints_[index],
                    "",
                    "",
                    false
                );
            }
        }
    }
}
