const NFT330 = artifacts.require("NFT330");
const MyNft = artifacts.require("MyNft");

module.exports = async function (deployer) {
    // await deployer.deploy(NFT330);
    await deployer.deploy(MyNft);

    // const deployed = await NFT330.deployed();
    // await deployer.deploy(nftTrader, deployed.address, 8);
};
