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
        address owner;
    }
}

contract CarToken is ERC721 {

    constructor() ERC721("CarToken", "CT2") {}
    mapping(uint => CarLibrary.Car) public cars;

    uint public carCounter;
    function addCar(
        string memory _model,
        string memory _color,
        uint _year,
        uint _originalValue,
        uint _currentMilage,
        address _owner
    ) public returns (uint256) {
        carCounter++; // create a unique tokenId
        uint tokenId = carCounter;
        _mint(msg.sender, tokenId); //mint = create NFT and give its token to msg.sender which is the one calling it/creating it
        cars[tokenId] = CarLibrary.Car(_model, _color, _year, _originalValue, _currentMilage,address(0), _owner);
        return tokenId;
    }

    function getCar(uint tokenId) public view returns(CarLibrary.Car memory) {
        return cars[tokenId];
    }

    function updateCarLeasee(uint tokenId, address newLeasee) external {
        require(cars[tokenId].owner == msg.sender, "Only owner has permission to update the leasee");
        cars[tokenId].leasee = newLeasee;
    }

    function deleteCar(uint tokenId) public {
    delete cars[tokenId];
    }



}

