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

import {LibContext} from "../../../libraries/LibContext.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {IERC1155Receiver} from "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

/**
 * @dev Basic ERC1155 library with additional separation of (semi-)fungible tokens.
 * Based on OpenZeppelin's ERC1155 contract.
 * See: https://docs.openzeppelin.com/contracts/4.x/api/token/erc1155
 * See: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC1155/ERC1155.sol
 *
 * ToDo: Make the library compatible for a ERC721 facet.
 */
library LibNft {
    using Address for address;
    using EnumerableSet for EnumerableSet.UintSet;

    error TokenNotFound(uint256 tokenId);
    error TokenNotFungible(uint256 tokenId);

    enum TokenTypes {
        FUNGIBLE,
        NFT
    }

    struct FungibleToken {
        uint256 id;
        string name;
        string symbol;
        uint256 totalSupply;
    }

    struct Storage {
        // Array of fungible token IDs
        uint256[] fungibleTokenIds;
        // Mapping from token ID to fungible token settings
        mapping(uint256 => FungibleToken) fungibleTokens;
        // Mapping from token ID to account balances
        mapping(uint256 => mapping(address => uint256)) balances;
        // Mapping from account to operator approvals
        mapping(address => mapping(address => bool)) operatorApprovals;
        // Mapping from account to owned NFT tokens
        mapping(address => EnumerableSet.UintSet) accountNftTokens;
        // Mapping with last token IDs
        mapping(TokenTypes => uint256) lastTokenIncrements;
    }

    uint256 internal constant FUNGIBLE_RESERVED_IDS = 1000;

    bytes32 internal constant STORAGE_SLOT =
        keccak256("solarprotocol.contracts.nft.LibNft");

    /**
     * @dev Returns the storage.
     */
    function _storage() private pure returns (Storage storage s) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            s.slot := slot
        }
    }

    /**
     * @dev Emitted when a new fungible token was created.
     */
    event FungibleTokenCreated(
        uint256 indexed tokenId,
        string name,
        string symbol
    );

    /**
     * @dev Emitted when fungible token `tokenId` was updated.
     */
    event FungibleTokenUpdated(
        uint256 indexed tokenId,
        string name,
        string symbol
    );

    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 value
    );

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(
        address indexed account,
        address indexed operator,
        bool approved
    );

    /**
     * @dev Creates a new fungible token.
     * @param name Name of the token.
     * @param symbol Symbol of the token.
     */
    function createFungibleToken(string memory name, string memory symbol)
        internal
        returns (uint256 tokenId)
    {
        tokenId = _incrementLastTokenId(TokenTypes.FUNGIBLE);

        FungibleToken memory token = FungibleToken({
            id: tokenId,
            name: name,
            symbol: symbol,
            totalSupply: 0
        });

        _storage().fungibleTokens[tokenId] = token;
        _storage().fungibleTokenIds.push(tokenId);
    }

    /**
     * @dev Updates an existing fungible token.
     * @param tokenId Id of the fungible token.
     * @param name Name of the token.
     * @param symbol Symbol of the token.
     */
    function updateFungibleToken(
        uint256 tokenId,
        string memory name,
        string memory symbol
    ) internal {
        FungibleToken memory token = _storage().fungibleTokens[tokenId];

        if (token.id != tokenId) {
            revert TokenNotFound(tokenId);
        }

        token.name = name;
        token.symbol = symbol;

        _storage().fungibleTokens[tokenId] = token;
    }

    /**
     * Returns the fungible token with id `tokenId`.
     * @param tokenId Id of the fungible token.
     */
    function getFungibleToken(uint256 tokenId)
        internal
        view
        returns (FungibleToken memory token)
    {
        token = _storage().fungibleTokens[tokenId];

        if (token.id != tokenId) {
            revert TokenNotFound(tokenId);
        }
    }

    /**
     * @dev Returns a list of all fungible tokens.
     */
    function getFungibleTokens()
        internal
        view
        returns (FungibleToken[] memory tokens)
    {
        uint256[] memory fungibleTokenIds = _storage().fungibleTokenIds;
        mapping(uint256 => FungibleToken) storage fungibleTokens = _storage()
            .fungibleTokens;

        for (uint256 index = 1; index <= fungibleTokenIds.length; index++) {
            uint256 tokenId = fungibleTokenIds[index];
            tokens[tokenId] = fungibleTokens[tokenId];
        }
    }

    /**
     * @dev Returns `true` if `tokenId` is a fungible token.
     */
    function isTokenFungible(uint256 tokenId) internal view returns (bool) {
        return _storage().fungibleTokens[tokenId].id == tokenId;
    }

    /**
     * @dev Mints `amount` of fungible token `tokenId` to `account`.
     */
    function mintFungible(
        address account,
        uint256 tokenId,
        uint256 amount
    ) internal {
        _mint(account, tokenId, amount, "", true);
    }

    /**
     * @dev Mints a batch `amounts` of fungible tokens `tokenIds` to `account`.
     */
    function mintFungibleBatch(
        address account,
        uint256[] memory tokenIds,
        uint256[] memory amounts
    ) internal {
        _mintBatch(account, tokenIds, amounts, "", true);
    }

    /**
     * @dev Mints one NFT to `account and returns it's `tokenId`.
     */
    function mintNft(address account) internal returns (uint256 tokenId) {
        tokenId = _incrementLastTokenId(TokenTypes.NFT);

        _mint(account, tokenId, 1, "", false);
    }

    /**
     * @dev Mints `amount` of NFTs to `account` and returns their `tokenIds`.
     */
    function mintNftBatch(address account, uint256 amount)
        internal
        returns (uint256[] memory)
    {
        uint256[] memory amounts = new uint256[](amount);
        uint256[] memory tokenIds = new uint256[](amount);

        for (uint256 i = 0; i < amount; ++i) {
            uint256 tokenId = _incrementLastTokenId(TokenTypes.NFT);
            tokenIds[i] = tokenId;
            amounts[i] = 1;
        }

        _mintBatch(account, tokenIds, amounts, "", false);

        return tokenIds;
    }

    /**
     * @dev Returns a list of all NFT `tokenIds` owned by `account`.
     */
    function getNftsOf(address account)
        internal
        view
        returns (uint256[] memory tokens)
    {
        tokens = _storage().accountNftTokens[account].values();
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id)
        internal
        view
        returns (uint256)
    {
        require(
            account != address(0),
            "ERC1155: balance query for the zero address"
        );
        return _storage().balances[id][account];
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal {
        require(owner != operator, "ERC1155: setting approval status for self");
        _storage().operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator)
        internal
        view
        returns (bool)
    {
        return _storage().operatorApprovals[account][operator];
    }

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal {
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = LibContext.msgSender();
        //uint256[] memory ids = _asSingletonArray(id);
        //uint256[] memory amounts = _asSingletonArray(amount);

        //_beforeTokenTransfer(operator, from, to, ids, amounts, data);

        _transferBalance(from, to, id, amount);

        emit TransferSingle(operator, from, to, id, amount);

        //_afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev Batched version of `safeTransferFrom`.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal {
        require(
            ids.length == amounts.length,
            "ERC1155: ids and amounts length mismatch"
        );
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = LibContext.msgSender();

        //_beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            _transferBalance(from, to, id, amount);
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        //_afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(
            operator,
            from,
            to,
            ids,
            amounts,
            data
        );
    }

    /**
     * @dev Updates the balances during a transfer `amount` of token `id` `from` `to`.
     */
    function _transferBalance(
        address from,
        address to,
        uint256 id,
        uint256 amount
    ) private {
        uint256 fromBalance = _storage().balances[id][from];
        require(
            fromBalance >= amount,
            "ERC1155: insufficient balance for transfer"
        );
        unchecked {
            _storage().balances[id][from] = fromBalance - amount;
        }
        _storage().balances[id][to] += amount;

        if (!isTokenFungible(id)) {
            _storage().accountNftTokens[from].remove(id);
            _storage().accountNftTokens[to].add(id);
        }
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data,
        bool enforceFungible
    ) private {
        require(to != address(0), "ERC1155: mint to the zero address");

        address operator = LibContext.msgSender();
        //uint256[] memory ids = _asSingletonArray(id);
        //uint256[] memory amounts = _asSingletonArray(amount);

        //_beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        _storage().balances[id][to] += amount;
        if (!isTokenFungible(id)) {
            if (enforceFungible) {
                revert TokenNotFungible(id);
            }
            _storage().accountNftTokens[to].add(id);
        }

        emit TransferSingle(operator, address(0), to, id, amount);

        //_afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(
            operator,
            address(0),
            to,
            id,
            amount,
            data
        );
    }

    /**
     * @dev Batched version of `_mint`.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data,
        bool enforceFungible
    ) private {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(
            ids.length == amounts.length,
            "ERC1155: ids and amounts length mismatch"
        );

        address operator = LibContext.msgSender();

        //_beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            _storage().balances[ids[i]][to] += amounts[i];

            if (!isTokenFungible(ids[i])) {
                if (enforceFungible) {
                    revert TokenNotFungible(ids[i]);
                }
                _storage().accountNftTokens[to].add(ids[i]);
            }
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        //_afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(
            operator,
            address(0),
            to,
            ids,
            amounts,
            data
        );
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `from`
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `from` must have at least `amount` tokens of token type `id`.
     */
    function burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal {
        require(from != address(0), "ERC1155: burn from the zero address");

        address operator = LibContext.msgSender();
        //uint256[] memory ids = _asSingletonArray(id);
        //uint256[] memory amounts = _asSingletonArray(amount);

        //_beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        uint256 fromBalance = _storage().balances[id][from];
        require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _storage().balances[id][from] = fromBalance - amount;
        }
        _storage().accountNftTokens[from].remove(id);

        emit TransferSingle(operator, from, address(0), id, amount);

        //_afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    /**
     * @dev Batched version of `_burn`.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function burnBatch(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal {
        require(from != address(0), "ERC1155: burn from the zero address");
        require(
            ids.length == amounts.length,
            "ERC1155: ids and amounts length mismatch"
        );

        address operator = LibContext.msgSender();

        //_beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _storage().balances[id][from];
            require(
                fromBalance >= amount,
                "ERC1155: burn amount exceeds balance"
            );
            unchecked {
                _storage().balances[id][from] = fromBalance - amount;
            }
            _storage().accountNftTokens[from].remove(id);
        }

        emit TransferBatch(operator, from, address(0), ids, amounts);

        //_afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try
                IERC1155Receiver(to).onERC1155Received(
                    operator,
                    from,
                    id,
                    amount,
                    data
                )
            returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try
                IERC1155Receiver(to).onERC1155BatchReceived(
                    operator,
                    from,
                    ids,
                    amounts,
                    data
                )
            returns (bytes4 response) {
                if (
                    response != IERC1155Receiver.onERC1155BatchReceived.selector
                ) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element)
        private
        pure
        returns (uint256[] memory)
    {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }

    /**
     * Handles ID incrementation for the 2 token types.
     */
    function _incrementLastTokenId(TokenTypes tokenType)
        private
        returns (uint256 id)
    {
        id = _storage().lastTokenIncrements[tokenType];

        // Switch to NFT ID pool if the fungible tokens reach the limit of the reserved pool
        if (tokenType == TokenTypes.FUNGIBLE && id == FUNGIBLE_RESERVED_IDS) {
            tokenType = TokenTypes.NFT;
            id = _storage().lastTokenIncrements[tokenType];
        }

        // Initialize the NFT id pool to start after the fungible reserved pool
        if (tokenType == TokenTypes.NFT && id == 0) {
            id = FUNGIBLE_RESERVED_IDS;
        }

        _storage().lastTokenIncrements[tokenType] = ++id;
    }
}
