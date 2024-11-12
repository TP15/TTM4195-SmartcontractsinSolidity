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
        address leasee;
    }

    struct Contract {
        uint monthlyQuota;
        uint32 startTs;
        uint32 carId;
        uint amountPayed;
        MileageCap mileageCap;
        ContractDuration duration;
        bool existensFlag;
    }

    mapping(address => Contract) contracts;

    // Initializing contract with a name of NFT collection and a symbol/ticker of the NFT collection
    constructor() ERC721("Group2", "G2") {}

    mapping(uint => Car) public cars;

    address payable public employee;
    uint256 transferrableAmount;

    uint public carCounter;

    enum MileageCap { SMALL, MEDIUM, LARGE, UNLIMITED }
    enum ContractDuration { ONE_MONTH, THREE_MONTHS, SIX_MONTHS, TWELVE_MONTHS }
    enum DrivingExperience { NEW_DRIVER, EXPERIENCED_DRIVER }

    // Only the owner of the SC can call the function
    modifier onlyEmployee() {
        require( msg.sender == employee , "Only Employees who created the contract can call this.");
        _;
    } 

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
        cars[tokenId] = Car(_model, _color, _year, _originalValue, _currentMilage, address(0));
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


    ///Task Nr 3
    /// 3 Methods: proposeContract, deleteContractProposal, evaluateContract

    /// @notice Propose a new contract to the leaser, the contract still needs to be confirmed by the leaser. The amount sent must be at least 4x the monthly quota (1 for the rent and 3 for the deposit).
    /// @param carId the car NFT id to rent
    /// @param drivingExperience the years of driving license ownage
    /// @param mileageCap the selected mileage limit
    /// @param duration the duration of the contract
    function proposeContract(uint32 carId, DrivingExperience drivingExperience, MileageCap mileageCap, ContractDuration duration) external payable {

        Car memory car = cars[carId];
        // Checks if Car and Sender are valid
        require(car.year != 0, "[Error] The car doesn't exists.");
        require(contracts[msg.sender].existensFlag, "[Error] You already have a contract.");
        require(car.leasee == address(0), "[Error] Car not available.");
        
        // calulation of the monthly Quota
        uint monthlyQuota = calculateMonthlyQuota(carId, mileageCap, duration, drivingExperience);
        // checking the amount given from the user
        require(msg.value >= 4 * monthlyQuota, "[Error] Amount sent is not enough.");

        uint durationFactor = duration == ContractDuration.TWELVE_MONTHS ? 1 :
                              duration == ContractDuration.SIX_MONTHS ? 2 :
                              duration == ContractDuration.THREE_MONTHS ? 3 : 5;

        require(msg.value <= (3+(durationFactor))*monthlyQuota, "[Error] Amount sent is too much.");

        contracts[msg.sender] = Contract(monthlyQuota, 0, carId, msg.value - 3*monthlyQuota, mileageCap, duration, true);
    }
    


    ///@notice This function allows a leasee to delete their own contract proposal if it has not yet started.
    ///@dev The contract proposal can only be deleted before it has been approved and started by an employee.
 
    function deleteContractProposal() external {

        uint monthlyQuota = contracts[msg.sender].monthlyQuota;

        require(contracts[msg.sender].startTs == 0, "Contract already started.");

        payable(msg.sender).transfer(3*monthlyQuota + contracts[msg.sender].amountPayed);
        delete contracts[msg.sender];
    }

    
    ///@notice This function allows an authorized employee to evaluate a lease contract for a given leasee.
    ///@dev The function can either approve or reject the contract based on the `accept` parameter.
    ///@param leasee The address of the leasee whose contract is being evaluated.
    ///@param accept A boolean indicating whether to accept or reject the contract.
    function evaluateContract(address leasee, bool accept) external onlyEmployee {
        
        Contract storage con = contracts[leasee];

        require(con.monthlyQuota > 0, "Leasee doesn't have contracts to evaluate.");
        require(con.startTs == 0, "Leasee contract has already started.");

        if (accept) {
            Car memory car = cars[con.carId];
            require(car.leasee == address(0), "Car is already rented!");
            con.startTs = uint32(block.timestamp);
            car.leasee = leasee;
            transferrableAmount += con.amountPayed;
        } else {
            payable(leasee).transfer(3*con.monthlyQuota+con.amountPayed);
            delete contracts[leasee];
        }

    }


    /**
    * @notice Converts a ContractDuration enum value into corresponding duration in seconds.
    * @dev This function is used to calculate the length of a lease period in seconds.
    * @param duration The contract duration, represented as an enum value of `ContractDuration`.
    *                 Valid values are ONE_MONTH, THREE_MONTHS, SIX_MONTHS, and TWELVE_MONTHS.
    * @return The duration of the contract in seconds.
    */
    function getDurationInSeconds(ContractDuration duration) internal pure returns (uint32) {
        if (duration == ContractDuration.TWELVE_MONTHS) return 365 days;
        if (duration == ContractDuration.SIX_MONTHS) return 182 days;
        if (duration == ContractDuration.THREE_MONTHS) return 90 days;
        return 30 days; // case for duration == ONE_MONTH
    }

    // Task 5a
    /**
    * @notice Allows a leasee to terminate their contract once the lease period has ended.
    * @dev Ensures the lease period has expired and refunds any remaining deposit to the leasee.
    *      Also resets the car's availability and removes the contract from the mapping.
    */
    function terminateContract() external {

        Contract storage con = contracts[msg.sender];

        // Check if the contract exists
        require(con.existensFlag, "Contract does not exist.");
        require(con.startTs > 0, "Contract not active.");
        require(block.timestamp >= con.startTs + getDurationInSeconds(con.duration), "Contract period not yet over.");

        // refund potentially remaining deposit to leasee
        uint refundableAmount = 3 * con.monthlyQuota;
        if (refundableAmount > 0) {
            payable(msg.sender).transfer(refundableAmount);
        }

        // reset car availability
        cars[con.carId].leasee = address(0);

        // remove the contract
        delete contracts[msg.sender];
    }


    // Task 5c
    /**
    * @notice Allows a leasee to terminate their existing contract and immediately sign a new one for a different car.
    * @dev Terminates the existing contract and proposes a new contract for a different vehicle.
    * @param newCarId The ID of the new car to lease.
    * @param drivingExperience The driving experience of the leasee.
    * @param mileageCap The selected mileage cap for the new contract.
    * @param duration The duration of the new contract.
    *                 Valid values are ONE_MONTH, THREE_MONTHS, SIX_MONTHS, and TWELVE_MONTHS.
    */
    function signNewContract(uint32 newCarId, DrivingExperience drivingExperience, MileageCap mileageCap, ContractDuration duration) external payable {
        // properly terminate current contract (inlcuding checking that it really ended)
        this.terminateContract();

        // propose a new contract for new car
        this.proposeContract(newCarId, drivingExperience, mileageCap, duration);
    }

    
}
