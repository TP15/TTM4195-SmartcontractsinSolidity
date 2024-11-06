// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract CarLeasing is ERC721, ReentrancyGuard {
    struct Car {
        string model;
        string color;
        uint16 year;
        uint256 originalValue;
        uint256 mileage;
    }

    struct Lease {
        uint256 monthlyQuota;
        uint256 downPayment;
        address lessee;
        uint256 startDate;
        bool active;
    }

    mapping(uint256 => Car) public cars;
    mapping(uint256 => Lease) public leases;
    mapping(uint256 => uint256) public driverExperience; // Driver's license years
    uint256 public carCounter;
    address public bilBoyd; // Dealership address

    event CarAdded(uint256 tokenId, string model, uint16 year, uint256 value);
    event LeaseInitiated(uint256 tokenId, address lessee);
    event LeaseTerminated(uint256 tokenId, address lessee, string reason);
    event LeaseExtended(uint256 tokenId, address lessee);

    modifier onlyBilBoyd() {
        require(msg.sender == bilBoyd, "Only BilBoyd can perform this action");
        _;
    }

    constructor() ERC721("BilBoydCar", "BBC") {
        bilBoyd = msg.sender;
    }

    // Task 1: Add a Car NFT with attributes
    function addCar(
        string memory _model,
        string memory _color,
        uint16 _year,
        uint256 _originalValue
    ) public onlyBilBoyd returns (uint256) {
        carCounter++;
        cars[carCounter] = Car(_model, _color, _year, _originalValue, 0);
        _mint(bilBoyd, carCounter);
        emit CarAdded(carCounter, _model, _year, _originalValue);
        return carCounter;
    }

    // Register driver's experience (license years)
    function registerDriverExperience(uint256 _tokenId, uint256 _licenseYears) public {
        require(ownerOf(_tokenId) == msg.sender, "Not the car owner");
        driverExperience[_tokenId] = _licenseYears;
    }

    // Task 2: Calculate Monthly Quota based on car value, mileage, driver experience, mileage cap, and contract duration
    function calculateMonthlyQuota(
        uint256 _tokenId,
        uint256 _contractDuration
    ) public view returns (uint256) {
        Car memory car = cars[_tokenId];
        uint256 experienceYears = driverExperience[_tokenId];

        // Base cost is proportional to car's original value and contract duration
        uint256 baseCost = car.originalValue / _contractDuration;

        // Additional costs based on mileage and driver's experience
        uint256 mileageCost = car.mileage * 0.01 ether; // Assuming a mileage cost factor
        uint256 insuranceCost = (10 - experienceYears) * 0.005 ether; // Higher experience lowers insurance cost

        return baseCost + mileageCost + insuranceCost;
    }

    // Task 3: Initiate Lease with down payment and first monthly payment
    function initiateLease(
        uint256 _tokenId,
        uint256 _monthlyQuota,
        address _lessee
    ) public payable nonReentrant {
        require(msg.value == (_monthlyQuota * 3), "Down payment not met");
        require(leases[_tokenId].active == false, "Lease already active");

        leases[_tokenId] = Lease({
            monthlyQuota: _monthlyQuota,
            downPayment: msg.value,
            lessee: _lessee,
            startDate: block.timestamp,
            active: true
        });

        safeTransferFrom(bilBoyd, _lessee, _tokenId);
        emit LeaseInitiated(_tokenId, _lessee);
    }

    // Task 4: Monthly payment protection
    function makeMonthlyPayment(uint256 _tokenId) public payable nonReentrant {
        require(leases[_tokenId].active, "Lease not active");
        require(leases[_tokenId].lessee == msg.sender, "Only lessee can pay");
        require(msg.value == leases[_tokenId].monthlyQuota, "Incorrect payment amount");

        payable(bilBoyd).transfer(msg.value);
    }

    // Task 5a: Terminate Lease
    function terminateLease(uint256 _tokenId) public nonReentrant {
        require(leases[_tokenId].active, "Lease already terminated or inactive");
        require(leases[_tokenId].lessee == msg.sender || msg.sender == bilBoyd, "Only lessee or BilBoyd can terminate");

        leases[_tokenId].active = false;
        _transfer(leases[_tokenId].lessee, bilBoyd, _tokenId);

        emit LeaseTerminated(_tokenId, leases[_tokenId].lessee, "Lease terminated by request");
    }

    // Task 5b: Extend Lease by 1 Year
    function extendLease(uint256 _tokenId) public payable nonReentrant {
        require(leases[_tokenId].active, "Lease inactive");
        require(leases[_tokenId].lessee == msg.sender, "Only lessee can extend lease");

        uint256 newMonthlyQuota = calculateMonthlyQuota(1,2); // Adjusting parameters as needed
        leases[_tokenId].monthlyQuota = newMonthlyQuota;

        emit LeaseExtended(_tokenId, msg.sender);
    }

    // Task 5c: Sign a New Lease for a Different Vehicle
    function newLeaseForNewVehicle(
        uint256 _oldTokenId,
        uint256 _newTokenId,
        uint256 _monthlyQuota
    ) public payable nonReentrant {
        require(leases[_oldTokenId].active, "Current lease inactive");
        require(leases[_oldTokenId].lessee == msg.sender, "Not the current lessee");
        require(msg.value == (_monthlyQuota * 3), "Down payment not met");

        leases[_oldTokenId].active = false;
        _transfer(leases[_oldTokenId].lessee, bilBoyd, _oldTokenId);

        leases[_newTokenId] = Lease({
            monthlyQuota: _monthlyQuota,
            downPayment: msg.value,
            lessee: msg.sender,
            startDate: block.timestamp,
            active: true
        });

        safeTransferFrom(bilBoyd, msg.sender, _newTokenId);
        emit LeaseInitiated(_newTokenId, msg.sender);
    }
}
