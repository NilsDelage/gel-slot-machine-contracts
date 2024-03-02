// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {GelatoVRFConsumerBase} from "./GelatoVRFConsumerBase.sol";
import {IBlast} from "./IBlast.sol";

contract SlotMachine is GelatoVRFConsumerBase {
    event SpinResult(address indexed player, uint256 winMultiplier, uint256 winAmount, uint256 timestamp);
    event updatedBetAmount(uint256 newBetAmount);
    event updatedJackpotMultiplier(uint256 newMultiplier);
    event updatedProb2xOver1000(uint256 newProb2xOver1000);
     
    uint256 public latestRandomness;
    address public owner;
    address private immutable _operatorAddr;
    uint256 public betAmount;
    uint256 public jackpotMultiplier; // probability of Jackpot is 1/1000
    uint256 public prob2xOver1000; // prob2xOver1000/1000 probability for 2x multiplier
    IBlast public constant BLAST = IBlast(0x4300000000000000000000000000000000000002);

    constructor(address operator) {   
        owner = msg.sender;
        _operatorAddr = operator;
        betAmount = 0.001 ether; // better not change
        jackpotMultiplier = 100; // max 198, mid 100, min 20
        prob2xOver1000 = 400; // 400/1000 probability for 2x multiplier, better not change
        BLAST.configureClaimableGas(); 
    }

    function _operator() internal view override returns (address) {
        return _operatorAddr;
    }

    function _fulfillRandomness(
        uint256 randomness,
        uint256,
        bytes memory extraData
    ) internal override {
        require(msg.sender == _operatorAddr, "The sender is not the VRF");
        latestRandomness = randomness;
        distributeOutcome(randomness, abi.decode(extraData, (address)));
    }

    function play() public payable {
        //send exactly betAmount to play
        require(msg.value == betAmount, "Send exactly 'betAmount' ETH to play");
        require(getBalance() >= betAmount*jackpotMultiplier, "House can't cover the win");
        
        _requestRandomness(abi.encode(msg.sender));
    }

    function distributeOutcome(uint256 randomness, address receiver) internal {
        uint256 winMultiplier;
        uint256 result = randomness % 1000;
        if (result == 0) {
            winMultiplier = jackpotMultiplier;
        } else if (result < prob2xOver1000) {
            winMultiplier = 2;
        } else {
            winMultiplier = 0;
        }

        uint256 winAmount = winMultiplier * betAmount;

        if (winAmount > 0) {
            require(getBalance() >= winAmount, "House can't cover the win");
            payable(receiver).transfer(winAmount);
        }

        emit SpinResult(receiver, winMultiplier, winAmount, block.timestamp);

    }

    function deposit() public payable{

    }

    // Withdraw function
    function withdraw(uint256 amount) public {
        require(msg.sender == owner, "Only the owner can withdraw");

        uint256 balance = getBalance();
        require(balance > 0, "No funds available");

        // If requested amount is greater than the balance, withdraw the entire balance
        if (amount > balance) {
            amount = balance;
        }

        payable(owner).transfer(amount);
    }

    // use only if you know what you are doing
    function updateBetAmount(uint256 newBetAmount) public {
        require(msg.sender == owner, "Only the owner can update the bet amount");
        betAmount = newBetAmount;
        emit updatedBetAmount(newBetAmount);
    }

    function updateJackpotMultiplier(uint256 newMultiplier) public {
        require(msg.sender == owner, "Only the owner can update the jackpot multiplier");
        jackpotMultiplier = newMultiplier;
        emit updatedJackpotMultiplier(newMultiplier);
    }

    // use only if you know what you are doing
    function updateProb2xOver1000(uint256 newProb2xOver1000) public {
        require(msg.sender == owner, "Only the owner can update the probability for 2x multiplier");
        //require(newProb2xOver1000 < 1000, "Probability for 2x multiplier must be maximum 999/1000");
        prob2xOver1000 = newProb2xOver1000;
        emit updatedProb2xOver1000(newProb2xOver1000);
    }

    function getBalance() public view returns(uint256){
        uint256 balance = address(this).balance;
        return balance;
    }

    function claimMyContractsGas() external {
        require(msg.sender == owner, "Only the owner can claim the bet amount");
        BLAST.claimAllGas(address(this), msg.sender);
    }
}
