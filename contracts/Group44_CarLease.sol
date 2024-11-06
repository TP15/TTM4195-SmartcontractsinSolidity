// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract CarLeasing is ERC721 {
    constructor() ERC721("Test", "Test") {

    }
}