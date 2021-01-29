pragma solidity >=0.5.17 <0.8.0;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract StakingToken is ERC20 {
    constructor() public ERC20("StakingToken", "StakingToken") {
        _mint(msg.sender, 1000000 ether);
    }
}