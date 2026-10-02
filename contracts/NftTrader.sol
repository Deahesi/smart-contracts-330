pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./NFT330.sol";

contract NftTrader330 is Ownable {
    struct Listing {
        uint256 price;
        uint256 amount;
        address seller;
    }

    struct Royalty {
        uint256 royalty;
        address minter;
    }

    mapping(address => mapping(uint256 => mapping(address => Listing))) public listings;

    mapping(address => mapping(uint256 => Royalty)) private royalties;

    address nftContractAddress;

    uint8 sellCommission;

    event Purchase(address indexed previousOwner, address indexed newOwner, uint price, uint nftID, uint amount);
    event PriceUpdate(address indexed owner, uint oldPrice, uint newPrice, uint nftID);

    constructor(address nftContract, uint8 commission) public {
        require(commission >= 0 && commission < 101, "enter valid commission percentage");
        nftContractAddress = nftContract;
        sellCommission = commission;
    }

    function setServiceCommission(uint8 commission) public onlyOwner {
        require(commission >= 0 && commission < 101, "enter valid commission percentage");
        sellCommission = commission;
    }

    function setRoyalty(uint256 tokenId, address seller, uint8 royalty) public onlyOwner {
        require(royalty >= 0 && royalty < 21, "enter valid royalty percentage");
        royalties[nftContractAddress][tokenId] = Royalty(royalty, seller);
    }

    function addListing(uint256 price, uint256 tokenId, address seller, bool minted, uint8 royalty) public onlyOwner {
        ERC1155 token = ERC1155(nftContractAddress);
        require(token.balanceOf(seller, tokenId) > 0, "seller must own given token");
        require(token.isApprovedForAll(seller, address(this)), "contract must be approved");
        if (minted) {
            require(royalties[nftContractAddress][tokenId].royalty == 0, "this token already minted");
            require(royalty >= 0 && royalty < 21, "enter valid royalty percentage");
            royalties[nftContractAddress][tokenId] = Royalty(royalty, seller);
        } else {
            require(royalties[nftContractAddress][tokenId].royalty != 0, "this token must be minted");
        }

        listings[nftContractAddress][tokenId][seller] = Listing(price, token.balanceOf(seller, tokenId), seller);
    }

    function updatePrice(uint _tokenId, uint _price) public returns (bool) {
        uint oldPrice = listings[nftContractAddress][_tokenId][msg.sender].price;
        require(listings[nftContractAddress][_tokenId][msg.sender].amount > 0, "Error, you are not the owner");
        listings[nftContractAddress][_tokenId][msg.sender].price = _price;

        emit PriceUpdate(msg.sender, oldPrice, _price, _tokenId);
        return true;
    }

    function addListingBatch(uint256[] memory prices, uint256[] memory tokenIds, address seller, bool[] memory mintedes, uint8[] memory _royalties) public onlyOwner {
        ERC1155 token = ERC1155(nftContractAddress);
        require((prices.length == tokenIds.length) && (tokenIds.length == mintedes.length) && (mintedes.length == _royalties.length), "prices, ids, mints, royalties length must be same");
        address[] memory accounts;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            accounts[i] = seller;
        }
        uint256[] memory balances = token.balanceOfBatch(accounts, tokenIds);

        for (uint256 i = 0; i < balances.length; i++) {
            require(balances[i] > 0, "seller must own given token");
        }

        require(token.isApprovedForAll(seller, address(this)), "contract must be approved");

        for (uint256 i = 0; i < tokenIds.length; i++) {
            if (mintedes[i]) {
                require(royalties[nftContractAddress][tokenIds[i]].royalty == 0, "this token already minted");
                require(_royalties[i] >= 0 && _royalties[i] < 21, "enter valid royalty percentage");
                royalties[nftContractAddress][tokenIds[i]] = Royalty(_royalties[i], seller);
            } else {
                require(royalties[nftContractAddress][tokenIds[i]].royalty != 0, "this token must be minted");
            }

            listings[nftContractAddress][tokenIds[i]][seller] = Listing(prices[i], token.balanceOf(seller, tokenIds[i]), seller);
        }
    }

    function purchase(address payable seller, uint256 tokenId, uint256 amount) public payable {
        Listing memory item = listings[nftContractAddress][tokenId][seller];
        ERC1155 token = ERC1155(nftContractAddress);
        require(msg.value >= item.price * amount, "insufficient funds sent");
        require(token.balanceOf(seller, tokenId) >= amount, "seller must own given token");
        require(token.isApprovedForAll(seller, address(this)), "contract must be approved");

        Royalty memory royalty_obj = royalties[nftContractAddress][tokenId];

        item.amount -= amount;
        seller.transfer(msg.value / 100 * (100 - royalty_obj.royalty - sellCommission));
        payable(royalty_obj.minter).transfer(msg.value / 100 * royalty_obj.royalty);
        payable(owner()).transfer(msg.value / 100 * sellCommission);
        token.safeTransferFrom(seller, msg.sender, tokenId, amount, "");

        emit Purchase(seller, msg.sender, msg.value, tokenId, amount);
    }
}
