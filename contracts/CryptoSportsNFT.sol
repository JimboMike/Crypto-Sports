// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/ERC1155.sol)

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/IERC1155MetadataURI.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";


/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract CryptoSportsNFT is ERC1155, AccessControl {

    using Address for address;

    // Setting admin role
    bytes32 public constant RESERVE_ROLE = keccak256("RESERVE_ROLE");

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.jso
    string private _uri;
    string private _baseURI;
    string public name;
    string public symbol;   
    address public _adminwallet;
    bytes32 public merkleRoot;


    /**
     * @dev See {_setURI}.
     */
    constructor(string memory uri_,
                string memory name_,
                string memory symbol_,
                address adminwallet_
                ) ERC1155(uri_) {
                name = name_;
                symbol = symbol_;
                _adminwallet = adminwallet_;
                _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
                }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /**
    * @notice edit the merkle root for early access sale
    *
    * @param _merkleRoot the new merkle root
    */
    function setMerkleRoot(bytes32 _merkleRoot) public onlyRole(RESERVE_ROLE) {
        merkleRoot = _merkleRoot;
    }

    function batchmint(address account, uint256[] memory tokenid, uint256[] memory amount) external virtual onlyRole(RESERVE_ROLE) {
        _mintBatch(account, tokenid, amount, "");
    }

    
    function mint(address account, uint256 tokenid, uint256 amount) external virtual onlyRole(RESERVE_ROLE) {
        _mint(account, tokenid, amount, "");
    }

    //For testing, clean up//
    function burn(address from, uint256 tokenid,uint256 amount) external virtual onlyRole(RESERVE_ROLE) {
        _burn(from, tokenid, amount);
    }

    function canTransferTo(address to, bytes32[] calldata merkleProof)
        public
        view
        returns (bool)
    {
    bytes32 leaf = keccak256(abi.encode(to));

    return (MerkleProof.verify(
            merkleProof,
            merkleRoot,
            leaf
            ));
    }

    function adminTrasfer(address from, address to, uint256 tokenid, uint256 amount, bytes32[] calldata merkleProof) external virtual onlyRole(RESERVE_ROLE) {
        require(canTransferTo(to, merkleProof), "To address not whitelisted");
        _safeTransferFrom(from, to, tokenid, amount, "");
        
        }


    function _setURI(string memory newuri) internal virtual override(ERC1155) {
        _uri = newuri;
    }

    /**
    * @notice edit the base uri for the collection
    *
    * @param baseURI the new URI
    */
    function setURI(string memory baseURI) external onlyRole(RESERVE_ROLE) {
        _setURI(baseURI);
    } 
    
    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function uri(uint256 tokenId) public view virtual override(ERC1155) returns (string memory) {
        return string(abi.encodePacked(_uri, _toString(tokenId)));
        //return _uri;
    }

    function _toString(uint256 value) internal pure virtual returns (string memory str) {
            assembly {
                // The maximum value of a uint256 contains 78 digits (1 byte per digit), but
                // we allocate 0xa0 bytes to keep the free memory pointer 32-byte word aligned.
                // We will need 1 word for the trailing zeros padding, 1 word for the length,
                // and 3 words for a maximum of 78 digits. Total: 5 * 0x20 = 0xa0.
                let m := add(mload(0x40), 0xa0)
                // Update the free memory pointer to allocate.
                mstore(0x40, m)
                // Assign the `str` to the end.
                str := sub(m, 0x20)
                // Zeroize the slot after the string.
                mstore(str, 0)

                // Cache the end of the memory to calculate the length later.
                let end := str

                // We write the string from rightmost digit to leftmost digit.
                // The following is essentially a do-while loop that also handles the zero case.
                // prettier-ignore
                for { let temp := value } 1 {} {
                    str := sub(str, 1)
                    // Write the character to the pointer.
                    // The ASCII index of the '0' character is 48.
                    mstore8(str, add(48, mod(temp, 10)))
                    // Keep dividing `temp` until zero.
                    temp := div(temp, 10)
                    // prettier-ignore
                    if iszero(temp) { break }
                }

                let length := sub(end, str)
                // Move the pointer 32 bytes leftwards to make room for the length.
                str := sub(str, 0x20)
                // Store the length.
                mstore(str, length)
            }
        }

}
