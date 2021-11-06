const hre = require("hardhat");

async function main() {
  const [owner, ...rest] = await hre.ethers.getSigners();
  console.log(rest[0].address);

  const NFT1 = await hre.ethers.getContractFactory("NFT1");
  const nft1 = await NFT1.deploy();
  await nft1.deployed();
  console.log("NFT1 deployed to:", nft1.address);

  const NFT2 = await hre.ethers.getContractFactory("NFT2");
  const nft2 = await NFT2.deploy();
  await nft2.deployed();
  console.log("NFT2 deployed to:", nft2.address);

  const NFTSwap = await hre.ethers.getContractFactory("NFTSwap");
  const nftSwap = await NFTSwap.deploy();
  await nftSwap.deployed();
  console.log("NFTSwap deployed to:", nftSwap.address);

  let txn = await nft1.connect(rest[0]).mint();
  await txn.wait();

  txn = await nft2.connect(rest[1]).mint();
  await txn.wait();

  txn = await nft1.connect(rest[0]).setApprovalForAll(nftSwap.address, true);
  await txn.wait();

  txn = await nft2.connect(rest[1]).setApprovalForAll(nftSwap.address, true);
  await txn.wait();

  console.log(
    "======================= Before Swapping ======================="
  );

  txn = await nft1.ownerOf(0);
  console.log("token 0 from NFT1 owner:", txn);

  txn = await nft2.ownerOf(0);
  console.log("token 0 from NFT2 owner:", txn);

  // create swap request
  txn = await nftSwap
    .connect(rest[0])
    .createSwapRequest(rest[1].address, nft1.address, nft2.address, 0, 0);

  txn = await nftSwap.connect(rest[1]).acceptSwapRequest(1);

  console.log("======================= After Swapping =======================");

  txn = await nft1.ownerOf(0);
  console.log("token 0 from NFT1 owner:", txn);

  txn = await nft2.ownerOf(0);
  console.log("token 0 from NFT2 owner:", txn);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
