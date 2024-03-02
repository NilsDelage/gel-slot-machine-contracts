pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "../src/SlotMachine.sol";

contract Deployment is Script {
    function run() public{
        
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // deploy collection
        SlotMachine _slot_machine = new SlotMachine(vm.envAddress("DEDICATED_MSG_SENDER"));
    }
}