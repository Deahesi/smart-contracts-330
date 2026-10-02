pragma solidity ^0.8.0;

contract SaleNFT {
    uint256 public price;
    //    address[]  = new address[];
    mapping(address => mapping(bool => uint256)) nftOwners;
    mapping(address => uint256) balances;
    address public nftCreator;
    address public contract1155;
    uint256 public tokenId;
    uint256 maxQuantity;
    address owner;
    uint8 constant comission = 8;

    bool sellable = false;

    event Bought(address _from, address _to, uint256 _tokenId, uint256 quantity, uint256 price);
    event Deposit(address sender, uint amount, uint balance);

    modifier onlyNftOwner {
        require(nftOwners[msg.sender][false] != 0 || nftOwners[msg.sender][true] != 0);
        _;
    }

    constructor(uint256 _price, address _nftOwner, uint256 _emission, address _contractAddress, uint256 _tokenId) payable {
        contract1155 = _contractAddress;
        price = _price * 1 ether;
        nftOwners[_nftOwner][true] = _emission;
        maxQuantity = _emission;
        owner = msg.sender;
        nftCreator = _nftOwner;
        tokenId = _tokenId;
    }

    fallback() external payable {
        balances[msg.sender] += msg.value;
    }

    function setSelling() public onlyNftOwner {
        sellable = true;
        if (nftOwners[msg.sender][false] == 0) {
            revert();
        } else {
            uint256 tokens = nftOwners[msg.sender][false];
            nftOwners[msg.sender][false] = 0;
            nftOwners[msg.sender][true] += tokens;
        }
    }

    function buyToken(bool _stayService, uint256 _quantity, address payable _seller) public payable returns (bool, uint256) {
        require(balances[msg.sender] * 1 ether >= _quantity * price, "You haven't enough ether");
        require(nftOwners[_seller][true] != 0, "Invalid seller address");
        require(nftOwners[_seller][true] >= _quantity, "You haven't enough tokens");


        if (_stayService) {
            uint256 sellPrice = (_quantity * price) / 100 * 92;
            _seller.transfer(sellPrice);
            balances[msg.sender] -= sellPrice;
            nftOwners[_seller][true] -= _quantity;
            //ПРОВЕРИТЬ
            nftOwners[msg.sender][false] = _quantity;
            emit Bought(_seller, msg.sender, tokenId, _quantity, _quantity * price);
            return (
            true,
            _quantity * price
            );
        }

        return (
            false,
            0
        );
    }

    function getTokenBalance(bool _toSell, address _address) public view returns (uint256) {
        return nftOwners[_address][_toSell];
    }

    function getBalance(address _address) public view returns (uint256) {
        return balances[_address];
    }

    function getTestBalance(address _address) public {
        balances[_address] += 5;
    }
}
