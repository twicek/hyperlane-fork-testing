pragma solidity >=0.5.0 <0.9.0;

contract MockISM {

    function verify(bytes calldata _metadata, bytes calldata _message) public returns (bool) {
        return true;
    }
}