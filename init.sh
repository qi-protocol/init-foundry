#!/bin/bash

# Change to the script's directory
cd "$(dirname "$0")"

# Git init
git init

# Install submodules
echo "installing submodules..."
git submodule add -f https://github.com/dapphub/ds-test lib/ds-test
git submodule add -f https://github.com/foundry-rs/forge-std lib/forge-std
git submodule add -f https://github.com/Openzeppelin/openzeppelin-contracts lib/openzeppelin-contracts
git submodule add -f https://github.com/Openzeppelin/openzeppelin-contracts-upgradeable lib/openzeppelin-contracts-upgradeable
git submodule add -f https://github.com/eth-infinitism/account-abstraction lib/account-abstraction
git submodule add -f https://github.com/Uniswap/v3-core lib/uniswap-v3-core
git submodule add -f https://github.com/Uniswap/v3-periphery lib/uniswap-v3-periphery

# Output remappings.txt
echo "ds-test/=lib/forge-std/lib/ds-test/src/" > remappings.txt
echo "forge-std/=lib/forge-std/src/" >> remappings.txt
echo "@openzeppelin/=lib/openzeppelin-contracts/" >> remappings.txt
echo "@oppenzeppelin-upgradeable/=lib/openzeppelin-contracts-upgradeable/contracts" >> remappings.txt
echo "account-abstraction/=lib/account-abstraction/contracts" >> remappings.txt
echo "@4337/=lib/account-abstraction/contracts" >> remappings.txt

echo "@utils/=src/utils/" >> remappings.txt
echo "@interfaces/=src/interfaces/" >> remappings.txt
echo "@libraries/=src/libraries/" >> remappings.txt

echo "Initialization completed."

# Foundry Forge init
forge init --force

# Get the script name without the path
script_name=$(basename "$0")

# Delete the existing .gitignore file
rm .gitignore

# Create a new .gitignore file with the specified content
echo "# private
[$script_name]
.env
.secret
.private
flat/

# Compiler files
cache/
out/

artifacts
node_modules
coverage
coverage.json
.DS_Store
compiler_config.json
.deps
package-lock.json
yarn.lock" > .gitignore

# Append lines to foundry.toml
cat <<EOL >> foundry.toml
fs_permissions = [{ access = "read-write", path = ".secret"}, { access ="read", path="./out/"}]
gas_reports = ["*"]
ffi = true 

solc = "0.8.20"
optimize = true
optimizer_runs = 100000
via_ir = true

[rpc_endpoints]
# INFURA_GOERLI_TEST_RPC_URL       = "${INFURA_GOERLI_TEST_RPC_URL}"

[etherscan]
# mumbai = { key = "${POLYSCAN_API_KEY}" }

[fmt]
line_length = 120
multiline_func_header = "params_first"
number_underscore="thousands"
# handle sorting of imports
EOL

# Create Solidity file at test/base/loadkey.t.sol
mkdir -p test/base
echo "// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

import \"lib/forge-std/src/Test.sol\";

contract LoadKey is Test {

  address eoaAddress;
  bytes32 internal key_bytes;
  uint256 internal privateKey;

  function setUp() public virtual {
    // setup private key
    string memory key = vm.readFile(\".secret\");
    key_bytes = vm.parseBytes32(key);
    assembly {
      sstore(privateKey.slot, sload(key_bytes.slot))
    }
    eoaAddress = address(uint160(privateKey));
  }

}" > test/base/loadkey.t.sol

echo "1111111111111111111111111111111111111111111111111111111111111111" > .secret
echo "1111111111111111111111111111111111111111111111111111111111111111" > .secret.example
echo "PRIVATE_KEY=1111111111111111111111111111111111111111111111111111111111111111
PUBLIC_KEY=0x19E7E376E7C213B7E7e7e46cc70A5dD086DAff2A
INFURA_GOERLI_TEST_RPC_URL=
POLYSCAN_API_KEY=
BASESCAN_API_KEY=
BASE_MAINNET_ID=0x2105
BASE_MAINNET_RPC=https://base-rpc.publicnode.com
BASE_MAINNET_EXPLORER=https://basescan.org/
BASE_SEPOLIA_ID=0x14A34
BASE_SEPOLIA_RPC=https://base-sepolia-rpc.publicnode.com
BASE_SEPOLIA-EXPLORER=https://sepolia.basescan.org/" > .env

echo "PRIVATE_KEY=1111111111111111111111111111111111111111111111111111111111111111
PUBLIC_KEY=0x19E7E376E7C213B7E7e7e46cc70A5dD086DAff2A
INFURA_GOERLI_TEST_RPC_URL=
POLYSCAN_API_KEY=
BASESCAN_API_KEY=
BASE_MAINNET_ID=0x2105
BASE_MAINNET_RPC=https://base-rpc.publicnode.com
BASE_MAINNET_EXPLORER=https://basescan.org/
BASE_SEPOLIA_ID=0x14A34
BASE_SEPOLIA_RPC=https://base-sepolia-rpc.publicnode.com
BASE_SEPOLIA-EXPLORER=https://sepolia.basescan.org/" > .env.example

# Create readme for how to deploy
echo "
forge script script/fileName.s.sol:Deploy --broadcast --rpc-url \$NETWORK_RPC --verify \$API_KEY --private-key \$PRIVATE_KEY
"> DEPLOY.md
