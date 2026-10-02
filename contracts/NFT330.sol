pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract NFT330 is ERC1155, Ownable {
    constructor() ERC1155("https://cpc-json-storage.s3.us-east-2.amazonaws.com/{id}.json") {}
    event Deposit(address sender, uint amount, uint balance);

    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    function mint(address account, uint256 id, uint256 amount) public onlyOwner {
        _mint(account, id, amount, "");
    }

    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts) public onlyOwner {
        _mintBatch(to, ids, amounts, "");
    }

    function uri(uint256 tokenId) override public view returns (string memory) {
        return (string(abi.encodePacked(
                "https://cpc-json-storage.s3.us-east-2.amazonaws.com/",
                Strings.toString(tokenId),
                ".json"
            )));
    }
}
