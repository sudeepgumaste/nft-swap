const hre = require("hardhat");
//! we can actually divide this and make it into seperate scripts, and run each one individually ?

async function main() {
  //* get them accounts boy (weiredest syntaxt though)
  const [_, ...rest] = await hre.ethers.getSigners();
  console.log(rest[0].address);

  //? get the actual NFT1 contract and Deploy that bad boy online
  const NFT1 = await hre.ethers.getContractFactory("NFT1");
  const nft1 = await NFT1.deploy();
  await nft1.deployed();
  console.log("NFT1 deployed to:", nft1.address);

  //? get the actual NFT2 contract and Deploy it online
  const NFT2 = await hre.ethers.getContractFactory("NFT2");
  const nft2 = await NFT2.deploy();
  await nft2.deployed();
  console.log("NFT2 deployed to:", nft2.address);

  //! now get the Swapping contract boy and deploy it online !
  const NFTSwap = await hre.ethers.getContractFactory("NFTSwap");
  const nftSwap = await NFTSwap.deploy();
  await nftSwap.deployed();
  console.log("NFTSwap deployed to:", nftSwap.address);

  //? connect to the contract using the account provided at the top, mint it from the contract, and add the token URI for it
  let txn = await nft1.connect(rest[0]).mint();
  await txn.wait();

  txn = await nft2.connect(rest[1]).mint();
  await txn.wait();

  //! give approval for the swapping contract to both accounts
  txn = await nft1.connect(rest[0]).setApprovalForAll(nftSwap.address, true);
  await txn.wait();

  txn = await nft2.connect(rest[1]).setApprovalForAll(nftSwap.address, true);
  await txn.wait();

  console.log("======================= Before Swapping =======================");

  //! gives us what owner owns the NFT with the token ID(to double check ?)
  txn = await nft1.ownerOf(0);
  console.log("token 0 from NFT1 owner:", txn);

  txn = await nft2.ownerOf(0);
  console.log("token 0 from NFT2 owner:", txn);

  //? create swap request from contract
  //! connects to the first account, taps into the function for request, we pass in the address of the receiver, the NFT addresses and
  txn = await nftSwap.connect(rest[0]).createSwapRequest(rest[1].address, nft1.address, nft2.address, 0, 0);

  txn = await nftSwap.connect(rest[1]).acceptSwapRequest(1);

  console.log("======================= After Swapping =======================");
  //! gives us what owner owns the NFT with the token ID(to double check ?)
  txn = await nft1.ownerOf(0);
  console.log("token 0 from NFT1 owner:", txn);

  txn = await nft2.ownerOf(0);
  console.log("token 0 from NFT2 owner:", txn);

  //! the rest is Data that users might wanna see displayed
  console.log("======================= Created Requests =======================");
  txn = await nftSwap.connect(rest[0]).getMyCreatedRequests();
  console.log("Created by 0th account", txn);

  txn = await nftSwap.connect(rest[1]).getMyCreatedRequests();
  console.log("Created by 1st account", txn);

  console.log("======================= Received Requests =======================");

  txn = await nftSwap.connect(rest[0]).getMyReceivedRequests();
  console.log("Received by 0th account", txn);

  txn = await nftSwap.connect(rest[1]).getMyReceivedRequests();
  console.log("Received by 1st account", txn);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
