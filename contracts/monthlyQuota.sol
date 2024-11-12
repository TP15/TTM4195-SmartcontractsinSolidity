// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract CarLeasing is ERC721 {

    //Struct to define types
    struct Car { 
        string model;
        string color;
        uint year;
        uint originalValue;
        uint currentMileage;
    }

    // Initializing contract with a name of NFT collection and a symbol/ticker of the NFT collection
    constructor() ERC721("Group2", "G2") {}

    mapping(uint => Car) public cars;

    uint public carCounter;

    enum MileageCap { SMALL, MEDIUM, LARGE, UNLIMITED }
    enum ContractDuration { ONE_MONTH, THREE_MONTHS, SIX_MONTHS, TWELVE_MONTHS }
    enum DrivingExperience { NEW_DRIVER, EXPERIENCED_DRIVER } 

    //Creates a NFT for a car
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
        cars[tokenId] = Car(_model, _color, _year, _originalValue, _currentMilage);
        return tokenId;
    }

    /**
    * @notice Calculates the monthly quota for leasing a car based on various factors.
    * @dev The final quota is affected by mileage cap, contract duration, driver experience, car value, 
    *      and the car's current mileage. This function is view-only and does not alter the contract state.
    * @param _tokenId The unique identifier of the car being leased.
    * @param mileageCap The selected mileage cap for the lease, which influences the monthly quota.
    *                   Options are SMALL (least miles), MEDIUM, LARGE, and UNLIMITED.
    * @param contractDuration The duration of the lease contract. Options are ONE_MONTH, THREE_MONTHS, 
    *                         SIX_MONTHS, and TWELVE_MONTHS.
    * @param drivingExperience Driver's experience level. Options are NEW_DRIVER (higher quota) 
    *                          and EXPERIENCED_DRIVER (lower quota).
    * @return monthlyQuota The calculated monthly quota in Wei.
    */
    function calculateMonthlyQuota(
        uint _tokenId,
        MileageCap mileageCap,
        ContractDuration contractDuration,
        DrivingExperience drivingExperience
        ) public view returns (uint) {
        

        Car memory car = cars[_tokenId];
        uint experienceFactor = drivingExperience == DrivingExperience.NEW_DRIVER ? 2 : 1;

        //Determine mileage cap factor
       uint mileageFactor = mileageCap == MileageCap.MEDIUM ? 2 :
                            mileageCap == MileageCap.LARGE ? 3 :
                            mileageCap == MileageCap.UNLIMITED ? 5 : 1;

        // Determine original car value factor
       uint carValueFactor = car.originalValue > 60_000 ? 5 :
                             car.originalValue > 40_000 ? 3 :
                             car.originalValue > 20_000 ? 2 : 1;

        // Determine contract duration factor
        uint durationFactor = contractDuration == ContractDuration.TWELVE_MONTHS ? 1 :
                              contractDuration == ContractDuration.SIX_MONTHS ? 2 :
                              contractDuration == ContractDuration.THREE_MONTHS ? 3 : 5;

        // Calculate the monthly quota
        uint monthlyQuota = (experienceFactor * mileageFactor * carValueFactor * durationFactor) / (1 + ((car.currentMileage + 1) / 10000));

        return monthlyQuota * 1e6 + 1e7; // Scale by 1e6 Wei and add 1e7 Wei minimum
   
    }









}