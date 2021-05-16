//SPDX-License-Identifier: Unlicensed

/**
 *   Merkle Air-Drop Token
 *
 *   See: https://blog.ricmoo.com/merkle-air-drops-e6406945584d
 */

pragma solidity ^0.8.4;

contract AirDropToken {

    event Transfer(address indexed from, address indexed to, uint256 tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint256 tokens);

    string _name;
    string _symbol;
    uint8 _decimals;

    uint256 _totalSupply;

    bytes32 _rootHash;

    mapping (address => uint256) _balances;
    mapping (address => mapping(address => uint256)) _allowed;

    mapping (uint256 => uint256) _redeemed;

    constructor(string memory name_, string memory symbol_, uint8 decimals_, bytes32 rootHash_, uint256 premine) {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
        _rootHash = rootHash_;

        if (premine > 0) {
            _balances[msg.sender] = premine;
            _totalSupply = premine;
            emit Transfer(address(0), msg.sender, premine);
        }
    }

    function name() public view returns(string memory) {
        return _name;
    }

    function symbol() public view returns(string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address tokenOwner) public view returns (uint256) {
         return _balances[tokenOwner];
    }

    function allowance(address tokenOwner, address spender) public view returns (uint256) {
        return _allowed[tokenOwner][spender];
    }

    function transfer(address to, uint256 amount) public returns (bool success) {
        if (_balances[msg.sender] < amount) { return false; }

        _balances[msg.sender] -= amount;
        _balances[to] += amount;

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public returns (bool success) {

        if (_allowed[from][msg.sender] < amount || _balances[from] < amount) {
            return false;
        }

        _balances[from] -= amount;
        _allowed[from][msg.sender] -= amount;
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        return true;
    }

    function approve(address spender, uint256 amount) public returns (bool success) {
        _allowed[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function redeemed(uint256 index) public view returns (bool) {
        uint256 redeemedBlock = _redeemed[index / 256];
        uint256 redeemedMask = (uint256(1) << uint256(index % 256));
        return ((redeemedBlock & redeemedMask) != 0);
    }

    function redeemPackage(uint256 index, address recipient, uint256 amount, bytes32[] memory merkleProof) public {

        // Make sure this package has not already been claimed (and claim it)
        uint256 redeemedBlock = _redeemed[index / 256];
        uint256 redeemedMask = (uint256(1) << uint256(index % 256));
        require((redeemedBlock & redeemedMask) == 0);
        _redeemed[index / 256] = redeemedBlock | redeemedMask;

        // Compute the merkle root
        bytes32 node = keccak256(abi.encodePacked(index, recipient, amount));
        uint256 path = index;
        for (uint16 i = 0; i < merkleProof.length; i++) {
            if ((path & 0x01) == 1) {
                node = keccak256(abi.encodePacked(merkleProof[i], node));
            } else {
                node = keccak256(abi.encodePacked(node, merkleProof[i]));
            }
            path /= 2;
        }

        // Check the merkle proof
        require(node == _rootHash);

        // Redeem!
        _balances[recipient] += amount;
        _totalSupply += amount;

        emit Transfer(address(0), recipient, amount);
    }
}

/*
contract AirDropFactory {
    event Create(address tokenContract);
    function createAirDrop(string name, string symbol, uint8 decimals, bytes32 rootHash, uint256 premine) {
        AirDropToken airDropToken = new AirDropToken(name, symbol, decimals, rootHash, premine);
        Create(address(airDropToken));
    }
}
*/