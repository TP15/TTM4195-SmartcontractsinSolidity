// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract CarLeasing is ERC721 {
    struct Car {
        string model;
        string color;
        uint16 year;
        uint256 originalValue;
        uint256 mileage;
    }

    struct Driver {
        uint256 licenseYears;
    }

    mapping(uint256 => Car) public cars;
    mapping(uint256 => Driver) public drivers;
    uint256 public carCounter;

    constructor() ERC721("BilBoydCar", "BBC") {}

    function addCar(
        string memory _model,
        string memory _color,
        uint16 _year,
        uint256 _originalValue
    ) public returns (uint256) {
        carCounter++;
        cars[carCounter] = Car(_model, _color, _year, _originalValue, 0);
        _mint(msg.sender, carCounter);
        return carCounter;
    }

    function registerDriver(uint256 _tokenId, uint256 _licenseYears) public {
        require(ownerOf(_tokenId) == msg.sender, "Not the car owner");
        drivers[_tokenId] = Driver(_licenseYears);
    }

    function calculateMonthlyQuota(
        uint256 _tokenId,
        uint256 _contractDuration
    ) public view returns (uint256) {
        Car memory car = cars[_tokenId];
        Driver memory driver = drivers[_tokenId];

        // Example calculation: (originalValue / contract duration) + (mileage * 0.01) + (insurance cost based on license years)
        uint256 baseCost = car.originalValue / _contractDuration;
        uint256 mileageCost = car.mileage * 0.01 ether; // Assuming a mileage cost factor
        uint256 insuranceCost = (10 - driver.licenseYears) * 0.005 ether;

        return baseCost + mileageCost + insuranceCost;
    }
}
