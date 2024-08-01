// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

interface IERC1155Token {
    function mint(address account, uint256 id, uint256 amount) external;
    function batchmint(address account, uint256[] memory id, uint256[] memory amount) external;
}

contract CryptoSportsMintingMgmt is Ownable, PaymentSplitter, ReentrancyGuard, AccessControl {

    bytes32 public constant MGMT_ROLE = keccak256("MGMT_ROLE");
    bytes32 public constant RESERVE_ROLE = keccak256("RESERVE_ROLE");


    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    string public name;

    struct PlayerCards {
        uint256 tokenId;
        uint256 price;
        uint256 maxSupply;
        uint256 totalminted;
    }

    mapping(uint256 => PlayerCards) _addedCards;
    uint256 public _totalCards;

    bool public saleIsActive = false;
    uint256 public MAXPORTIONALLOWEDTOHOLD = 10;
    string private _baseTokenURI;

    address cryptosports1155;

    constructor(
        address[] memory payees, 
        uint256[] memory shares_,
        address _tok1155
        ) 
        PaymentSplitter(payees, shares_){
            cryptosports1155 = _tok1155;
            _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    ///////////////////
    //Admin Functions//
    ///////////////////

    /**
     * Pause sale if active, make active if paused
     */
    function flipSaleState() public onlyRole(MGMT_ROLE) {
        saleIsActive = !saleIsActive;
    }

    /**
     * Change the max proportion allowed to mint
     */
    function changeMaxProp(uint256 _maxpropallowed) public onlyRole(MGMT_ROLE) {
        MAXPORTIONALLOWEDTOHOLD = _maxpropallowed;
    }

    /**
    * Add Tokens
    */
    function _addTokenToSale (uint256 price, uint256 maxSupply) public onlyRole(MGMT_ROLE) {

        _addedCards[_totalCards] = PlayerCards({
            tokenId : uint16(_totalCards),
            price : uint256(price),
            maxSupply : uint256(maxSupply),
            totalminted : uint256(0)
        });

        _totalCards += 1;
    }

    function setPrice(uint256 tokenid, uint256 tokenidprice) public onlyRole(MGMT_ROLE) {
        //require(tokenid < _totalCards, "Token ID does not exist");
        PlayerCards storage _card = _addedCards[tokenid];
        _card.price = tokenidprice;
    }

    function setSupply(uint256 tokenid, uint256 maxsupply) external onlyRole(MGMT_ROLE) {
        //require(tokenid < _totalCards, "Token ID does not exist");
        PlayerCards storage _card = _addedCards[tokenid];
        require(_card.totalminted <= maxsupply, "more has been minted");
        _card.maxSupply = maxsupply;
    } 

    /**
    * Admin extract funds
    */
    function withdrawAll() public onlyRole(MGMT_ROLE) {
        require(payable(owner()).send(address(this).balance));
    }

    /////////////////////
    //Minting Functions//
    /////////////////////

    function mintedAllow(uint256 amount, uint256 tokenid, address to) public view returns(bool) {
        PlayerCards storage _card = _addedCards[tokenid];
        uint256 balancetokenid = IERC1155(cryptosports1155).balanceOf(to, tokenid);
        uint256 totaltokenidsupply = _card.maxSupply;
        bool output = (((balancetokenid + amount) * 100000) <= (totaltokenidsupply * 1000) * MAXPORTIONALLOWEDTOHOLD);

        return output;
    }

    function updateTokenStruct (uint256 tokenid, uint256 amount) internal returns(bool) {

        PlayerCards storage _card = _addedCards[tokenid];
        uint256 totaltokenidsupply = _card.maxSupply;
        uint256 mintedtokenid = _card.totalminted;
        _card.totalminted = mintedtokenid + amount;
        return (mintedtokenid + amount <= totaltokenidsupply);
    }

    function adminMint(uint256 amount, uint256 tokenid, address to) public onlyRole(RESERVE_ROLE) {
        require(saleIsActive, "Sale Not Active");
        updateTokenStruct(tokenid, amount);
        IERC1155Token(cryptosports1155).mint(to, tokenid, amount);
    }

    function adminBatchMint(uint256[] memory amount, uint256[] memory tokenid, address to) public onlyRole(RESERVE_ROLE) {

        require(saleIsActive, "Sale Not Active");

        for (uint256 i = 1; i < tokenid.length; i++) {
            require(updateTokenStruct(tokenid[i], amount[i]), "Mint would exceed max supply of this tokenid");
        }
    
        IERC1155Token(cryptosports1155).batchmint(to, tokenid, amount);
    }

    function publicMint(uint256 amount, uint256 tokenid) public payable {

        PlayerCards storage _card = _addedCards[tokenid];

        uint256 totaltokenidsupply = _card.maxSupply;
        uint256 balancetokenid = IERC1155(cryptosports1155).balanceOf(msg.sender, tokenid);
        uint256 tokenidprice = _card.price;
        uint256 mintedtokenid = _card.totalminted;
        require(saleIsActive, "Sale Not Active");
        require((((balancetokenid + amount)/totaltokenidsupply)*1000) < MAXPORTIONALLOWEDTOHOLD, "Exceded preportion");
        require(tokenidprice * amount <= msg.value, "Not enough coin sent");
        require(mintedtokenid + amount <= totaltokenidsupply, "Mint would exceed max supply of this tokenid");
        
        IERC1155Token(cryptosports1155).mint(msg.sender, tokenid, amount);
        _card.totalminted = _card.totalminted + amount;
    }

    /////////////////////////
    //Public View Functions//
    /////////////////////////

    function getCardStruct(uint256 tokenid) external view returns (
        uint256 tokenId,
        uint256 price,
        uint256 maxSupply,
        uint256 totalminted
    ) {
        PlayerCards storage _card = _addedCards[tokenid];

        tokenId = _card.tokenId;    
        price = _card.price;
        maxSupply = _card.maxSupply;
        totalminted = _card.totalminted;
    }
}