# hyperlane-fork-testing

## Overview

The goal of this repos is to allow developers integrating with Hyperlane to test their contracts using the real Mailbox contracts deployed on local and destination chains.

## How to use

### Close the repos:

git clone https://github.com/twicek/hyperlane-fork-testing.git

### Run the example test:
```
forge test --match-test "test_localContract" -vvvvv
```

### Customize

To adapt this fork setup to your own use do the following steps:
- Add all rpc endpoints that you will use in `foundry.toml` and define their respective rpc url in a `.env` file.
```
[rpc_endpoints]
ethereum = "${RPC_ETHEREUM_URL}"
polygon = "${RPC_POLYGON_URL}"
```
- Next, copy `tests/E2ETemplate.t.sol`, uncomment the code and fill the placeholders for local/destination mailbox and IGP addresses:
```solidity
    // Local addresses
    address constant localMailbox = address(/* local mailbox address */);
    address constant localIGP = address(/* local mailbox interchain gas paymaster */);

    // Destination adresses
    address constant destMailbox = address(/* destination mailbox address */);
    address constant destIGP = address(/* destination mailbox interchain gas paymaster */);
```
- Do the same for local/destination rpc endpoints and block numbers:
```solidity
        localDomain = vm.createFork(vm.rpcUrl(/* "rpc endpoint defined in config" */), /* block.number */);
        destDomain = vm.createFork(vm.rpcUrl(/* "rpc endpoint defined in config" */), /* block.number */);
```
- Customize/Sanitize inputs as you wish:
```solidity
    // Choose/Sanatize function inputs
    function test_localContract() public {
        uint32 _destinationDomain = 137;
        bytes memory _messageBody = abi.encodeWithSignature("answer(uint256)", 42);
        uint256 _gasAmount = 200000;
        uint256 _gasPayment = 1 ether;
        address _gasPaymentRefundAddress = user;
        test_e2e(_destinationDomain, _messageBody, _gasAmount, _gasPayment, _gasPaymentRefundAddress);
    }
```
- In `src/E2ERouter.sol`, and whatever logic you want to be executed on the destination chain:
```solidity
    // This overridden _handle function will be called upon calling process -> handle -> _handle
    function _handle(
        uint32 _origin,
        bytes32 _sender,
        bytes calldata _message
    ) internal override {
        // Do whatever you want with _message
    }
```