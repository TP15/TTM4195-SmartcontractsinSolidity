// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract CarLeasing is ERC721 {
    struct LeasingCar {
        string model;
        string color;
        uint16 year;
        uint256 buyin_price_original_value;
    }
    
    address public group2CarLease;
    mapping(uint256 => LeasingCar) public cars;
    event CarAdded(uint256 tokenId, string model, string color, uint16 year, uint256 value);

    modifier onlyGroup2CarLease() {
        require(msg.sender == group2CarLease, "Unauthorized access");
        _;
    }

    constructor() ERC721("Group2_CarLease", "G2CL") {
        group2CarLease = msg.sender;
    }

     function addCar(string memory model, string memory color, uint16 year, uint256 buyin_price_original_value)
        public onlyGroup2CarLease returns (string memory) 
    {
        cars[0] = LeasingCar(model, color, year, buyin_price_original_value);
        _mint(group2CarLease, 0); // NFT Creation by ERC721

        return "Created";
    }

}