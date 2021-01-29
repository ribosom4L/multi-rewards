pragma solidity >=0.5.17 <0.8.0;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Test2 is ERC20 {
    constructor() public ERC20("Test2", "Test2") {
        _mint(msg.sender, 1000000 ether);
    }
}