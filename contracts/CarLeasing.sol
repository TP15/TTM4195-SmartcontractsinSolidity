// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;
import "./Car.sol";

contract CarLeasing {

    struct Contract {
        uint256 monthlyQuota;
        uint32 startTs;
        uint32 carId;
        uint256 amountPayed;
        MileageCap mileageCap;
        ContractDuration duration;
        bool existensFlag;
        bool isactiveFlag;
    }

    mapping(address => Contract) contracts;
    address payable public employee;
    address[] private contractAddresses; // Track addresses with contracts
    Car public carContract; // Reference to Car contract

    
    uint256 transferrableAmount;

    enum MileageCap {
        SMALL,
        MEDIUM,
        LARGE,
        UNLIMITED
    }
    enum ContractDuration {
        ONE_MONTH,
        THREE_MONTHS,
        SIX_MONTHS,
        TWELVE_MONTHS
    }
    enum DrivingExperience {
        NEW_DRIVER,
        EXPERIENCED_DRIVER
    }

    // Only the owner of the SC can call the function
    modifier onlyEmployee() {
        require(
            msg.sender == employee,
            "Only Employees who created the contract can call this."
        );
        _;
    }

    constructor(address _carContractAddress) {
        carContract = Car(_carContractAddress);
        employee = payable(msg.sender);
    }



    function addCar(
        string memory _model,
        string memory _color,
        uint256 _year,
        uint256 _originalValue,
        uint256 _currentMilage
    ) public returns (uint256) {
        uint256 token;
        token = carContract.addCar(_model, _color, _year, _originalValue, _currentMilage);
        return token;
    }

    // Task 2
    /**
     * @notice Calculates the monthly quota for leasing a car based on various factors.
     * @dev The final quota is affected by mileage cap, contract duration, driver experience, car value,
     *      and the car's current mileage. This function is view-only and does not alter the contract state.
     * @param _carToken The unique identifier of the car being leased.
     * @param mileageCap The selected mileage cap for the lease, which influences the monthly quota.
     *                   Options are SMALL (least miles), MEDIUM, LARGE, and UNLIMITED.
     * @param contractDuration The duration of the lease contract. Options are ONE_MONTH, THREE_MONTHS,
     *                         SIX_MONTHS, and TWELVE_MONTHS.
     * @param drivingExperience Driver's experience level. Options are NEW_DRIVER (higher quota)
     *                          and EXPERIENCED_DRIVER (lower quota).
     * @return monthlyQuota The calculated monthly quota in Wei.
     */
    function calculateMonthlyQuota(
        uint256 _carToken,
        MileageCap mileageCap,
        ContractDuration contractDuration,
        DrivingExperience drivingExperience
    ) public view returns (uint256) {
        CarLibrary.CarStruct memory car = carContract.getCar(_carToken);
        uint256 experienceFactor = drivingExperience == DrivingExperience.NEW_DRIVER
            ? 2
            : 1;

        //Determine mileage cap factor
        uint256 mileageFactor = mileageCap == MileageCap.MEDIUM
            ? 2
            : mileageCap == MileageCap.LARGE
            ? 3
            : mileageCap == MileageCap.UNLIMITED
            ? 5
            : 1;

        // Determine original car value factor
        uint256 carValueFactor = car.originalValue > 60_000
            ? 5
            : car.originalValue > 40_000
            ? 3
            : car.originalValue > 20_000
            ? 2
            : 1;

        // Determine contract duration factor
        uint256 durationFactor = contractDuration ==
            ContractDuration.TWELVE_MONTHS
            ? 1
            : contractDuration == ContractDuration.SIX_MONTHS
            ? 2
            : contractDuration == ContractDuration.THREE_MONTHS
            ? 3
            : 5;

        // Calculates a value used to modify the monthly quota calculation based on a cars current mileage
        uint256 mileageModifier = 1 + ((car.currentMileage + 1) / 10000);
        
        // Calculate the monthly quota
        uint256 monthlyQuota = (experienceFactor *
            mileageFactor *
            carValueFactor *
            durationFactor) / mileageModifier;

        return monthlyQuota * 1e6 + 1e7; // Scale by 1e6 Wei and add 1e7 Wei minimum
    }


    //Task 3
    // 3 Methods: proposeContract, deleteContractProposal, evaluateContract

    /**
     * @notice Propose a new contract to the leaser, the contract still needs to be confirmed by the leaser. The amount sent must be at least 4x the monthly quota (1 for the rent and 3 for the deposit).
     * @param carId the car NFT id to rent
     * @param drivingExperience the years of driving license ownage
     * @param mileageCap the selected mileage limit
     * @param duration the duration of the contract
     */
    function proposeContract(
        uint32 carId,
        DrivingExperience drivingExperience,
        MileageCap mileageCap,
        ContractDuration duration
    ) external payable {
        CarLibrary.CarStruct memory car = carContract.getCar(carId);
        // Checks if Car and Sender are valid
        require(car.year != 0, "[Error] The car doesn't exists.");
        require(
            !contracts[msg.sender].existensFlag,
            "[Error] You already have a contract."
        );
        require(car.leasee == address(0), "[Error] Car not available.");

        // calulation of the monthly Quota
        uint256 monthlyQuota = calculateMonthlyQuota(
            carId,
            mileageCap,
            duration,
            drivingExperience
        );
        // checking the amount given from the user
        require(
            msg.value >= 4 * monthlyQuota,
            "[Error] Amount sent is not enough."
        );

        uint256 durationFactor = duration == ContractDuration.TWELVE_MONTHS
            ? 1
            : duration == ContractDuration.SIX_MONTHS
            ? 2
            : duration == ContractDuration.THREE_MONTHS
            ? 3
            : 5;

        require(
            msg.value <= (3 + (durationFactor)) * monthlyQuota,
            "[Error] Amount sent is too much."
        );

        contracts[msg.sender] = Contract(
            monthlyQuota,
            0,
            carId,
            msg.value - 3 * monthlyQuota,
            mileageCap,
            duration,
            true,
            false
        );
        contractAddresses.push(msg.sender);
    }

    /**
     * @notice This function allows a leasee to delete their own contract proposal if it has not yet started.
     * @dev The contract proposal can only be deleted before it has been approved and started by an employee.
     */
    function deleteContractProposal() external {
        uint256 monthlyQuota = contracts[msg.sender].monthlyQuota;

        require(
            contracts[msg.sender].startTs == 0,
            "Contract already started."
        );

        payable(msg.sender).transfer(
            3 * monthlyQuota + contracts[msg.sender].amountPayed
        );
        delete contracts[msg.sender];
    }

    function getContract(address _Owner)
        external
        view
        onlyEmployee
        returns (Contract memory)
    {
        Contract storage con = contracts[_Owner];
        return con;
    }

    function getInactiveContracts()
        external
        view
        onlyEmployee
        returns (address[] memory)
    {
        uint256 inactiveCount = 0;

        // First, count the number of inactive contracts
        for (uint256 i = 0; i < contractAddresses.length; i++) {
            if (!contracts[contractAddresses[i]].isactiveFlag) {
                inactiveCount++;
            }
        }

        // Prepare array for inactive contract addresses
        address[] memory inactiveContracts = new address[](inactiveCount);
        uint256 index = 0;

        // Collect inactive contracts
        for (uint256 i = 0; i < contractAddresses.length; i++) {
            if (!contracts[contractAddresses[i]].isactiveFlag) {
                inactiveContracts[index] = contractAddresses[i];
                index++;
            }
        }

        return inactiveContracts;
    }

    /**
     * @notice This function allows an authorized employee to evaluate a lease contract for a given leasee.
     * @dev The function can either approve or reject the contract based on the `accept` parameter.
     * @param leasee The address of the leasee whose contract is being evaluated.
     * @param accept A boolean indicating whether to accept or reject the contract.
     */
    function evaluateContract(address leasee, bool accept)
        external
        onlyEmployee
    {
        Contract storage con = contracts[leasee];

        require(
            con.monthlyQuota > 0,
            "Leasee doesn't have contracts to evaluate."
        );
        require(con.startTs == 0, "Leasee contract has already started.");

        if (accept) {
            CarLibrary.CarStruct memory car = carContract.getCar(con.carId);
            require(car.leasee == address(0), "Car is already rented!");
            con.startTs = uint32(block.timestamp);
            con.isactiveFlag = true;
            car.leasee = leasee;
            transferrableAmount += con.amountPayed;
        } else {
            payable(leasee).transfer(3 * con.monthlyQuota + con.amountPayed);
            delete contracts[leasee];
        }
    }
    
    // Task 4
    /**
     * @dev this function lets only employees to check if a customer is insolvent and delete the contract
     * @dev the deposit will be refunded
     */
    function protectAgainstInsolventCustomer(address leasee)
        external
        onlyEmployee
    {
        Contract storage contr = contracts[leasee];

        require(contr.existensFlag, "No contract exists");
        require(contr.startTs > 0, "Contract is not active");

        uint256 monthsActive = (block.timestamp - contr.startTs) / 30 days;

        uint256 due = monthsActive * contr.monthlyQuota;

        // Check if the leasee has not paid the required amount
        if (contr.amountPayed < due) {
            CarLibrary.CarStruct memory car = carContract.getCar(contr.carId);
            require(
                car.leasee == leasee,
                "Leasee does not have this car leased"
            );

            // Reset the leasee of the car to make it available again
            carContract.updateCarLeasee(contr.carId, address(0));

            // Refund the deposit if applicable
            uint256 refundableAmount = 3 * contr.monthlyQuota;
            if (refundableAmount > 0) {
                payable(leasee).transfer(refundableAmount);
            }

            // should I emit that the contract is terminated?

            // Delete the lease contract
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
    function getDurationInSeconds(ContractDuration duration)
        internal
        pure
        returns (uint32)
    {
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
        require(
            block.timestamp >= con.startTs + getDurationInSeconds(con.duration),
            "Contract period not yet over."
        );

        // refund potentially remaining deposit to leasee
        uint256 refundableAmount = 3 * con.monthlyQuota;
        if (refundableAmount > 0) {
            payable(msg.sender).transfer(refundableAmount);
        }

        // reset car availability
        carContract.getCar(con.carId).leasee = address(0);

        // remove the contract
        delete contracts[msg.sender];
    }

    // Task 5b
    /**
     * @notice Allows a leasee to extend their lease contract for an additional year.
     * @dev Recalculates the monthly quota based on updated parameters and charges a deposit and first payment.
     *      Updates the contract duration to reflect a one-year extension.
     * @param drivingExperience The updated driving experience level of the leasee.
     * @param mileageCap The desired mileage cap for the extended contract.
     */

    function extendLease(
        DrivingExperience drivingExperience,
        MileageCap mileageCap
    ) external payable {
        Contract storage con = contracts[msg.sender];

        // Check if contract exists and is active
        require(con.existensFlag, "Contract does not exist.");
        require(con.startTs > 0, "Contract is not active.");
        require(
            block.timestamp >= con.startTs + getDurationInSeconds(con.duration),
            "Contract period not yet over."
        );

        // Recalculate the monthly quota based on updated parameters
        uint256 newMonthlyQuota = calculateMonthlyQuota(
            con.carId,
            mileageCap,
            ContractDuration.TWELVE_MONTHS,
            drivingExperience
        );

        // Check if enough ETH is sent for deposit and the first monthly payment
        require(
            msg.value >= 4 * newMonthlyQuota,
            "Insufficient payment for extension deposit and first monthly quota."
        );

        // Update the contract fields with the new terms
        con.monthlyQuota = newMonthlyQuota;
        con.amountPayed = msg.value - 3 * newMonthlyQuota;
        con.startTs = uint32(block.timestamp);
        con.duration = ContractDuration.TWELVE_MONTHS;
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
    function signNewContract(
        uint32 newCarId,
        DrivingExperience drivingExperience,
        MileageCap mileageCap,
        ContractDuration duration
    ) external payable {
        // properly terminate current contract (inlcuding checking that it really ended)
        this.terminateContract();

        // propose a new contract for new car
        this.proposeContract(newCarId, drivingExperience, mileageCap, duration);
    }
}
