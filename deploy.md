
forge create ./src/Token.sol:Token --rpc-url https://sepolia.base.org --account deployer --constructor-args Reach Reach
forge create ./src/Distribution.sol:ReachDistribution --rpc-url https://sepolia.base.org --account deployer --constructor-args
forge verify-contract 0x4F49E2eC8B15b4222C06035AFDb2ee201dfdF2C9 ./src/Distribution.sol:ReachDistribution --chain 84532

//TOKEN
Deployer: 0x4CA45B1D85cA08EfdCF68E76cC78A743fAdc6eC5
Deployed to: 0x0836feE34Bd4403213e6ccA241576DDa315D8eEa
Transaction hash: 0x66911b27f3f8066472c11d73aab05992aaeff8f057daf14fe59e3765dbfaf981


forge create ./src/Distribution.sol:ReachDistribution --rpc-url https://mainnet.base.org --account reach2 --constructor-args 0x4379c13143eb91148ff9282cfb2f93536687a45b 0xa11c3d0c2370462ab2388f0e29baf0e6618c724B

forge verify-contract 0xA7D4aFcDc43bf574f8b9374FF73d48a660bA4530 ./src/Distribution.sol:ReachDistribution --rpc-url https://mainnet.base.org --constructor-args 0x4379c13143eb91148ff9282cfb2f93536687a45b 0xa11c3d0c2370462ab2388f0e29baf0e6618c724B 

Successfully created new keypair.
Address:     0x8bAC3Bc2e749eB32c48c1cFf56036255f6b9bBcf
Private key: 0xfcb7698927f21bcb5c673aef5344ba9b0e95753b62a01aa87e3d54b012d4b7db