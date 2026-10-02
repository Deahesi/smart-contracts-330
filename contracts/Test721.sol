pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract ReBrand is ERC1155, Ownable {
    struct Listing {
        uint256 price;
        uint256 amount;
        uint256 time;
    }


            //id               //owner
    mapping(uint256 => mapping(address => Listing)) public listings;

    uint8 serviceComission;
    address RED;

    event Listed(address indexed owner, uint nftID, uint price, uint amount);
    event Purchase(address indexed previousOwner, address indexed newOwner, uint nftID, uint price, uint amount);
    event ListingUpdate(address indexed owner, uint nftID, uint oldPrice, uint newPrice, uint oldAmount, uint newAmount);

    constructor(uint8 commission, address _RED) ERC1155("https://cpc-json-storage.s3.us-east-2.amazonaws.com/{id}.json") {
        require(commission >= 0 && commission < 101, "enter valid commission percentage");
        // require(Address.isContract(_RED), "RED token must be contract");
        serviceComission = commission;
        // RED = _RED;
    }

    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    function mint(address account, uint256 id, uint256 amount) public onlyOwner {
        _mint(account, id, amount, "");
    }

    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts) public onlyOwner {
        _mintBatch(to, ids, amounts, "");
    }

    function setServiceCommission(uint8 commission) public onlyOwner {
        require(commission >= 0 && commission < 101, "enter valid commission percentage");
        serviceComission = commission;
    }

    function list(uint256 _price, uint256 _tokenId, uint256 _amount, address _seller) public {
        require(listings[_tokenId][_seller].amount == 0, "token is already listed");
        require(_amount > 0, "invalid amount");
        require(_price > 0, "invalid price");
        require(balanceOf(_seller, _tokenId) >= _amount, "seller must own given token");
        listings[_tokenId][_seller] = Listing(_price, _amount, block.timestamp);
        emit Listed(_seller, _tokenId, _price, _amount);
    }


    function purchase(address payable _seller, uint256 _tokenId, uint256 _amount) public payable {
        Listing memory item = listings[_tokenId][_seller];
        require(item.amount > 0, "No listings found");
        require(msg.value >= item.price * _amount, "insufficient funds sent");
        require(balanceOf(_seller, _tokenId) >= _amount, "seller must own given token");

        _seller.transfer(msg.value / 100 * (100 - serviceComission));
        ERC20 token = ERC20(RED);


        if (block.timestamp - item.time <= 604800) { //1 week
            token.transfer(_seller, (msg.value / 100 * 4));
            token.transfer(msg.sender, (msg.value / 100 * 2));
        } else if (block.timestamp - item.time <= 1209600) { //2 weeks
            token.transfer(_seller, (msg.value / 100 * 3));
            token.transfer(msg.sender, (msg.value / 100 * 1));
        } else if (block.timestamp - item.time <= 1814400) { //3 weeks
            token.transfer(_seller, (msg.value / 100 * 2));
            token.transfer(msg.sender, (msg.value / 100 * 1));
        } else if (block.timestamp - item.time <= 2419200) { //4 weeks
            token.transfer(_seller, (msg.value / 100 * 1));
            token.transfer(msg.sender, (msg.value / 100 * 1));
        }
        

        listings[_tokenId][_seller] = Listing(item.price, item.amount - _amount, item.time);
        payable(owner()).transfer(msg.value / 100 * serviceComission);
        safeTransferFrom(_seller, msg.sender, _tokenId, _amount, "");

        emit Purchase(_seller, msg.sender, msg.value, _tokenId, _amount);
    }

    function uri(uint256 tokenId) override public view returns (string memory) {
        return (string(abi.encodePacked(
                "https://cpc-json-storage.s3.us-east-2.amazonaws.com/",
                Strings.toString(tokenId),
                ".json"
            )));
    }
}