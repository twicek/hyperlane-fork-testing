pragma solidity >=0.5.0 <0.9.0;

import "../src/interfaces/IMailbox.sol";
import "../src/interfaces/IInterchainGasPaymaster.sol";
import "../src/interfaces/IInterchainSecurityModule.sol";
import "../src/Router.sol";

contract E2ERouter is Router {

    function Initialize(address _localMailbox, address _localIGP, address _localISM) external initializer {
        __Router_initialize(_localMailbox, _localIGP, _localISM);
    }

    // Externally exposes _dispatchWithGas for convenience 
    function dispatchWithGas(
        uint32 _destination,
        bytes memory _messageBody,
        uint256 _gasAmount,
        address _gasPaymentRefundAddress
    ) external payable {
        _dispatchWithGas(
            _destination,
            _messageBody,
            _gasAmount,
            msg.value,
            _gasPaymentRefundAddress
        );
    }

    // This overridden _handle function will be called upon calling process -> handle -> _handle
    function _handle(
        uint32 _origin,
        bytes32 _sender,
        bytes calldata _message
    ) internal override {
        // Do whatever you want with _message
    }
}