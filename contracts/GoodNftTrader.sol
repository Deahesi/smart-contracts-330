pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract NftTrader is Ownable {
    struct Listing {
        uint256 price;
        uint256 amount;
    }

    //contract         //id               //owner
    mapping(address => mapping(uint256 => mapping(address => Listing)))
        public listings;

    uint8 serviceComission;

    event Listed(
        address indexed contractAddress,
        address indexed owner,
        uint256 nftID,
        uint256 price,
        uint256 amount
    );
    event Purchase(
        address indexed contractAddress,
        address indexed previousOwner,
        address indexed newOwner,
        uint256 nftID,
        uint256 price,
        uint256 amount
    );
    event ListingUpdate(
        address indexed contractAddress,
        address indexed owner,
        uint256 nftID,
        uint256 oldPrice,
        uint256 newPrice,
        uint256 oldAmount,
        uint256 newAmount
    );

    constructor(uint8 commission) public {
        require(
            commission >= 0 && commission < 101,
            "enter valid commission percentage"
        );
        serviceComission = commission;
    }

    function setServiceCommission(uint8 commission) public onlyOwner {
        require(
            commission >= 0 && commission < 101,
            "enter valid commission percentage"
        );
        serviceComission = commission;
    }

    function addListing(
        address _contractAddress,
        uint256 _price,
        uint256 _tokenId,
        uint256 _amount,
        address _seller
    ) public onlyOwner {
        ERC1155 token = ERC1155(_contractAddress);
        require(
            listings[_contractAddress][_tokenId][_seller].amount == 0,
            "token is already listed"
        );
        require(_amount > 0, "seller must own given token");
        require(
            token.balanceOf(_seller, _tokenId) >= _amount,
            "seller must own given token"
        );
        require(
            token.isApprovedForAll(_seller, address(this)),
            "contract must be approved"
        );

        listings[_contractAddress][_tokenId][_seller] = Listing(
            _price,
            _amount
        );
    }

    function updateListing(
        address _contractAddress,
        uint256 _tokenId,
        uint256 _newPrice,
        uint256 _newAmount
    ) public returns (bool) {
        ERC1155 token = ERC1155(_contractAddress);
        Listing memory oldListing = listings[_contractAddress][_tokenId][
            msg.sender
        ];
        require(
            listings[_contractAddress][_tokenId][msg.sender].amount > 0,
            "No listings found"
        );
        require(_newPrice > 0, "Invalid price");
        require(_newAmount > 0, "Invalid amount");
        require(
            token.balanceOf(msg.sender, _tokenId) >= _newAmount,
            "you have not enough tokens"
        );

        listings[_contractAddress][_tokenId][msg.sender].price = _newPrice;
        listings[_contractAddress][_tokenId][msg.sender].amount = _newAmount;

        emit ListingUpdate(
            _contractAddress,
            msg.sender,
            _tokenId,
            oldListing.price,
            _newPrice,
            oldListing.amount,
            _newAmount
        );
        return true;
    }

    function updatePrice(
        address _contractAddress,
        uint256 _tokenId,
        uint256 _newPrice
    ) public returns (bool) {
        Listing memory oldListing = listings[_contractAddress][_tokenId][
            msg.sender
        ];
        require(oldListing.amount > 0, "No listings found");
        require(_newPrice > 0, "Invalid price");

        oldListing.price = _newPrice;

        emit ListingUpdate(
            _contractAddress,
            msg.sender,
            _tokenId,
            oldListing.price,
            _newPrice,
            oldListing.amount,
            oldListing.amount
        );
        return true;
    }

    function updateListingAmount(
        address _contractAddress,
        uint256 _tokenId,
        uint256 _newAmount
    ) public returns (bool) {
        ERC1155 token = ERC1155(_contractAddress);
        Listing memory oldListing = listings[_contractAddress][_tokenId][
            msg.sender
        ];
        require(oldListing.amount > 0, "No listings found");
        require(_newAmount > 0, "Invalid amount");
        require(
            token.balanceOf(msg.sender, _tokenId) >= _newAmount,
            "you have not enough tokens"
        );

        oldListing.amount = _newAmount;

        emit ListingUpdate(
            _contractAddress,
            msg.sender,
            _tokenId,
            oldListing.price,
            oldListing.price,
            oldListing.amount,
            oldListing.amount
        );
        return true;
    }

    // function addListingBatch(uint256[] memory prices, uint256[] memory tokenIds, address seller, bool[] memory mintedes, uint8[] memory _royalties) public onlyOwner {
    //     ERC1155 token = ERC1155(nftContractAddress);
    //     require((prices.length == tokenIds.length) && (tokenIds.length == mintedes.length) && (mintedes.length == _royalties.length), "prices, ids, mints, royalties length must be same");
    //     address[] memory accounts;
    //     for (uint256 i = 0; i < tokenIds.length; i++) {
    //         accounts[i] = seller;
    //     }
    //     uint256[] memory balances = token.balanceOfBatch(accounts, tokenIds);

    //     for (uint256 i = 0; i < balances.length; i++) {
    //         require(balances[i] > 0, "seller must own given token");
    //     }

    //     require(token.isApprovedForAll(seller, address(this)), "contract must be approved");

    //     for (uint256 i = 0; i < tokenIds.length; i++) {
    //         if (mintedes[i]) {
    //             require(royalties[nftContractAddress][tokenIds[i]].royalty == 0, "this token already minted");
    //             require(_royalties[i] >= 0 && _royalties[i] < 21, "enter valid royalty percentage");
    //             royalties[nftContractAddress][tokenIds[i]] = Royalty(_royalties[i], seller);
    //         } else {
    //             require(royalties[nftContractAddress][tokenIds[i]].royalty != 0, "this token must be minted");
    //         }

    //         listings[nftContractAddress][tokenIds[i]][seller] = Listing(prices[i], token.balanceOf(seller, tokenIds[i]), seller);
    //     }
    // }

    function purchase(
        address _contractAddress,
        address payable _seller,
        uint256 _tokenId,
        uint256 _amount
    ) public payable {
        Listing memory item = listings[_contractAddress][_tokenId][_seller];
        ERC1155 token = ERC1155(_contractAddress);
        require(item.amount > 0, "iNo listings found");
        require(msg.value >= item.price * _amount, "insufficient funds sent");
        require(
            token.balanceOf(_seller, _tokenId) >= _amount,
            "seller must own given token"
        );
        require(
            token.isApprovedForAll(_seller, address(this)),
            "contract must be approved"
        );

        _seller.transfer((msg.value / 100) * (100 - serviceComission));
        item.amount -= _amount;
        payable(owner()).transfer((msg.value / 100) * serviceComission);
        token.safeTransferFrom(_seller, msg.sender, _tokenId, _amount, "");

        emit Purchase(
            _contractAddress,
            _seller,
            msg.sender,
            msg.value,
            _tokenId,
            _amount
        );
    }
}
