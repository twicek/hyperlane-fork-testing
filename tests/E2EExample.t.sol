pragma solidity >=0.5.0 <0.9.0;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../src/interfaces/IMailbox.sol";
import "../src/interfaces/IInterchainGasPaymaster.sol";
import "../src/interfaces/IInterchainSecurityModule.sol";
import "../src/interfaces/IRouter.sol";
import "../src/libs/EnumerableMapExtended.sol";
import "../src/libs/Message.sol";
import "../src/libs/BytesLib.sol";
import "../src/E2ERouter.sol";
import "../src/MockISM.sol";

contract E2EExample is Test {
    
    address constant admin = address(0x1337);
    address constant user = address(0x01);
    address constant relayer = address(0x02);

    // Domains
    uint256 internal localDomain;
    uint256 internal destDomain;

    // Local addresses
    address constant localMailbox = address(0x35231d4c2D8B8ADcB5617A638A0c4548684c7C70);
    address constant localIGP = address(0x6cA0B6D22da47f091B7613223cD4BB03a2d77918);

    // Destination adresses
    address constant destMailbox = address(0x35231d4c2D8B8ADcB5617A638A0c4548684c7C70);
    address constant destIGP = address(0x6cA0B6D22da47f091B7613223cD4BB03a2d77918);

    // Local contracts
    IMailbox constant LOCAL_MAILBOX = IMailbox(localMailbox);
    IInterchainGasPaymaster constant LOCAL_IGP = IInterchainGasPaymaster(localIGP);
    E2ERouter public LOCAL_ROUTER;

    // Destination contracts
    IMailbox constant DEST_MAILBOX = IMailbox(destMailbox);
    IInterchainGasPaymaster constant DEST_IGP = IInterchainGasPaymaster(destIGP);
    E2ERouter public DEST_ROUTER;


    function setUp() public {
        localDomain = vm.createFork(vm.rpcUrl("ethereum"), 17449877);
        destDomain = vm.createFork(vm.rpcUrl("polygon"), 43742914);

        // Deploy and initialize E2ERouter on local and destination chain
        vm.selectFork(localDomain);
        LOCAL_ROUTER = new E2ERouter();
        LOCAL_ROUTER.Initialize(localMailbox, localIGP, address(new MockISM())); // MockISM will always return true when "verify" is called
        vm.selectFork(destDomain);
        DEST_ROUTER = new E2ERouter();
        DEST_ROUTER.Initialize(destMailbox, destIGP, address(new MockISM()));

        // A remote router must be enrolled for _dispatch router function to work
        vm.selectFork(localDomain);
        LOCAL_ROUTER.enrollRemoteRouter(137, bytes32(abi.encode(address(DEST_ROUTER))));

        vm.selectFork(destDomain);
        DEST_ROUTER.enrollRemoteRouter(1, bytes32(abi.encode(address(LOCAL_ROUTER))));
    }

    // Choose/Sanitize function inputs
    function test_localContract() public {
        uint32 _destinationDomain = 137;
        bytes memory _messageBody = abi.encodeWithSignature("answer(uint256)", 42);
        uint256 _gasAmount = 200000;
        uint256 _gasPayment = 1 ether;
        address _gasPaymentRefundAddress = user;
        test_e2e(_destinationDomain, _messageBody, _gasAmount, _gasPayment, _gasPaymentRefundAddress);
    }


    function test_e2e(uint32 _destinationDomain, bytes memory _messageBody, uint256 _gasAmount, uint256 _gasPayment, address _gasPaymentRefundAddress) public payable {
        // Select local fork
        vm.selectFork(localDomain);
   
        vm.recordLogs();

        // Call local router contract that call _dispatchWithGas function on the Router
        vm.deal(user, 1 ether);
        vm.startPrank(user);
        LOCAL_ROUTER.dispatchWithGas{value: _gasPayment}(_destinationDomain, _messageBody, _gasAmount, _gasPayment, _gasPaymentRefundAddress);
        

        // Retrieve message from logs
        Vm.Log[] memory entries = vm.getRecordedLogs();
        bytes memory _message = retrieveMessageFromLogs(entries);

        // Select destination fork
        vm.selectFork(destDomain);

        // Call process on the destination mailbox
        changePrank(relayer);
        bytes memory _metadata = hex"";
        DEST_MAILBOX.process(_metadata, _message);
    }


    // Convenience methods

    function retrieveMessageFromLogs(Vm.Log[] memory entries) public returns (bytes memory message){
        // Dispatch event function signature: Dispatch(address,uint32,bytes32,bytes)
        bytes32 hashSigDispatch = keccak256("Dispatch(address,uint32,bytes32,bytes)"); // 0x769f711d20c679153d382254f59892613b58a97cc876b249134ac25c80f9c814
        

        for (uint256 i; i < entries.length; i++) {
            if (entries[0].topics[0] == hashSigDispatch) {
                message = entries[0].data;
                break;
            }
        }
        message = BytesLib.slice(message, 64, message.length - 64); // remove first 64 bytes from: 32 (length) + 32 (length) + 113 (data) + 15 (padding) = 192 bytes
    }
}