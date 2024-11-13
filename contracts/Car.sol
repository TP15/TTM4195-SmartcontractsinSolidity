// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

library CarLibrary {
    struct Car { 
        string model;
        string color;
        uint year;
        uint originalValue;
        uint currentMileage;
        address leasee;
    }
}

contract CarToken is ERC721 {

    constructor() ERC721("CarToken", "CT2") {}
    mapping(uint => CarLibrary.Car) public cars;

    // modifier onlyTokenOwner(uint tokenId) {
    //     require(_isApprovedOrOwner(_msgSender(), tokenId), "Caller is not owner nor approved");
    //     _;
    // }

    modifier  notLeased(uint tokenId) {
        require(cars[tokenId].leasee == address(0), "Cannot modify a leased car.");
        _;
    }

    // modifier  existingCar(uint tokenId) {
    //     require(_exists(uint(tokenId)), "Car doesn't exist.");
    //     _;
    // }

    uint public carCounter;
    function addCar(
        string memory _model,
        string memory _color,
        uint _year,
        uint _originalValue,
        uint _currentMilage
    ) public returns (uint256) {
        carCounter++; // create a unique tokenId
        uint tokenId = carCounter;
        _mint(msg.sender, tokenId); //mint = create NFT and give its token to msg.sender which is the one calling it/creating it
        cars[tokenId] = CarLibrary.Car(_model, _color, _year, _originalValue, _currentMilage, address(0));
        return tokenId;
    }

    function getCar(uint tokenId) public view returns(CarLibrary.Car memory) {
        return cars[tokenId];
    }

    function updateCarLeasee(uint carId, address newLeasee) external {
        require(ownerOf(carId) == msg.sender, "Only owner has permission to update the leasee");
        cars[carId].leasee = newLeasee;
    }


}

