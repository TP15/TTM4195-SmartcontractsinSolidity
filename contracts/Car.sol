// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

library CarLibrary {
    struct CarStruct {
        string model;
        string color;
        uint256 year;
        uint256 originalValue;
        uint256 currentMileage;
        address leasee;
    }
}

contract Car is ERC721 {
    constructor() ERC721("Car", "C2") {}

    mapping(uint256 => CarLibrary.CarStruct) public cars;

    uint256 public carToken;


    /**
    * @notice Adds a new car as an NFT token to the contract.
    * @dev This function mints a new NFT token for the car and stores car details in a mapping.
    * @param _model The model of the car
    * @param _color The color of the car
    * @param _year The manufacturing year of the car
    * @param _originalValue The initial value of the car in dollar
    * @param _currentMilage The current mileage of the car in miles.
    * @return carToken The unique token ID of the newly added car.
    */
    function addCar(
        string memory _model,
        string memory _color,
        uint256 _year,
        uint256 _originalValue,
        uint256 _currentMilage
    ) public returns (uint256) {
        carToken++; // Increment to create a unique tokenId for each new car
        _mint(msg.sender, carToken); // Mint an NFT and assign it to the caller (msg.sender)
        
        // Store car details in the cars mapping with the newly created tokenId
        cars[carToken] = CarLibrary.CarStruct(
            _model,
            _color,
            _year,
            _originalValue,
            _currentMilage,
            address(0)
        );
        return carToken;
    }

    /**
    * @notice Retrieves the details of a car based on its token ID.
    * @dev Throws an error if the car does not exist in the cars mapping.
    * @param _carToken The unique token ID of the car to retrieve.
    * @return CarLibrary.CarStruct The struct containing car details like model, color, year, and mileage.
    */
    function getCar(uint256 _carToken)
        public
        view
        returns (CarLibrary.CarStruct memory)
    {
        require(bytes(cars[_carToken].model).length != 0, "Car does not exist for the given car token");
        return cars[_carToken];
    }


    /**
    * @notice Updates the leasee address for a car.
    * @dev Only the car owner can update the leasee address.
    * @param _carToken The unique token ID of the car to update.
    * @param newLeasee The new leasee address to be set for the car.
    */
    function updateCarLeasee(uint256 _carToken, address newLeasee) external {
        address carOwner = ownerOf(_carToken); 
        require(
        msg.sender == carOwner,
        "Only the owner has permission to update the leasee"
    );
        cars[carToken].leasee = newLeasee;
    }

    /**
    * @notice Deletes a car from the contract.
    * @dev Only the car owner can delete the car from the mapping.
    * @param _carToken The unique token ID of the car to delete.
    */
    function deleteCar(uint256 _carToken) public {
        address carOwner = ownerOf(_carToken);
        require(
        msg.sender == carOwner,
        "Only the owner can delete this car"
    );
        delete cars[_carToken];
    }
}
