// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

contract diceGame   {

    mapping (address => uint) public playerResult;
    uint nonce;
    uint playerWon = 0;
    uint public transactionCount = 0;
    uint public transactionAmount = 0;
    address public owner;
    uint256 fixedAmountForPlaying = 100000000000000000;     //Wei -> 0.1Eth to play
    uint256 maxWin = 200000000000000000;                    //Wei -> 0.2 Max win
    mapping (address=>bool) public allowedPlayer;           // True if the player has paid the amount
    mapping(address => uint) public balances;

    constructor() {
        owner = payable (msg.sender);
    }

    receive() payable external {
        balances[msg.sender] += msg.value;
    }  

    function play() public payable  {
        require (canUserPlay(msg.sender));
        // Only who paid can play
        // Register who is calling the method
        address payable fromWallet;
        fromWallet = payable(msg.sender);
        uint256 seed = uint256(keccak256(abi.encodePacked(
        block.timestamp + block.difficulty +
        ((uint256(keccak256(abi.encodePacked(block.coinbase)))) / (block.timestamp)) +
        block.gaslimit + 
        ((uint256(keccak256(abi.encodePacked(msg.sender)))) / (block.timestamp)) +
        block.number
        )));
        // This is the number generated by user and i need to register it
        playerResult[fromWallet] = (seed - ((seed / 1000) * 1000));
        // Verify who wins
        if (playerResult[fromWallet] > generateRandomFromContract())    {
        // Player wins
            playerWon = 1;
            fromWallet.transfer(200000000000000000);
            //fromWallet.transfer(address(this).balance);
        }
        else    {
            // Contract wins
            playerWon = 0;
        } 
    }

    function generateRandomFromContract() private view returns (uint)    {
        // Generate a dice launch for contract 
        uint256 seed = uint256(keccak256(abi.encodePacked(
        block.timestamp + block.difficulty +
        ((uint256(keccak256(abi.encodePacked(block.coinbase)))) / (block.timestamp)) +
        block.gaslimit + 
        ((uint256(keccak256(abi.encodePacked(address(this))))) / (block.timestamp)) +
        block.number
        )));       
        return (seed - ((seed / 1000) * 1000));
    }
    
    function whoWhon() public view returns (uint)   {
        return playerWon;
    }

    function withdraw(address payable myAddress) public  {
        require(msg.sender == owner, "Only owner can withdraw funds"); 
        myAddress.transfer(address(this).balance);
    }

    function changeAmountForPlay(uint256 newAmount) public {
        fixedAmountForPlaying = newAmount;
    }

    function canUserPlay(address playerAddress) public view returns (bool)  {
        // Check if the user sent money before playing
        bool canPlayGame = false;
        if(balances[playerAddress] > fixedAmountForPlaying) {
            // User has paid and can play
            canPlayGame = true;
        }
        // Return boolean
        return canPlayGame;
    }

}
