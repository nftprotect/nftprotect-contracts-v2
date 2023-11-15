#!/bin/bash

# Get the network from command line arguments or use 'sepolia' as default
NETWORK=${1:-sepolia}

# Define the contracts
contracts=("ArbitratorRegistry" "UserDIDDummyAllowAll" "NFTProtect2" "UserRegistry" "RequestsHub" "ProtectorFactory721")

# Array to store contract addresses
addresses=()

# Loop over the contracts
for i in ${!contracts[@]}; do
  # Prompt for the contract address
  echo "Enter the address for ${contracts[$i]}:"
  read address

  # Store the address
  addresses[$i]=$address
done

# Verify the contracts
for i in ${!contracts[@]}; do
  # Prepare the arguments
  args=""
  case ${contracts[$i]} in
    "UserRegistry")
      args="${addresses[0]} ${addresses[1]} ${addresses[2]}"
      ;;
    "RequestsHub")
      args="${addresses[0]} ${addresses[2]}"
      ;;
    "ProtectorFactory721")
      args="${addresses[2]}"
      ;;
  esac

  # Verify the contract
  npx hardhat verify --network $NETWORK ${addresses[$i]} $args
done