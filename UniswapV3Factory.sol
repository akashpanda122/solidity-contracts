// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import "@uniswap/v3-periphery/contracts/libraries/UniswapV3PoolDeployerLibrary.sol";
import "@uniswap/v3-periphery/contracts/interfaces/INonfungiblePositionManager.sol";
import "@uniswap/v3-periphery/contracts/interfaces/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract UniswapV3Factory is IUniswapV3Factory {
    address public override feeTo;
    address public override feeToSetter;
    uint24 public constant override maxFee = 3000;

    mapping(address => mapping(address => uint24)) private _fee;
    mapping(address => mapping(address => address)) private _pools;

    event PoolCreated(address indexed token0, address indexed token1, uint24 fee, int24 tickSpacing, address pool);

    constructor(address _feeToSetter) {
        feeToSetter = _feeToSetter;
    }

    function createPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external override returns (address pool) {
        require(fee <= maxFee, "UniswapV3: fee exceeds maximum");
        require(tokenA != tokenB, "UniswapV3: identical addresses");
        require(tokenA != address(0) && tokenB != address(0), "UniswapV3: zero address");
        require(_pools[tokenA][tokenB] == address(0), "UniswapV3: pool already exists");

        bytes32 salt = keccak256(abi.encodePacked(tokenA, tokenB, fee));
        pool = UniswapV3PoolDeployerLibrary.deploy(address(this), salt);
        _pools[tokenA][tokenB] = pool;
        _pools[tokenB][tokenA] = pool;
        _fee[tokenA][tokenB] = fee;
        _fee[tokenB][tokenA] = fee;

        emit PoolCreated(tokenA, tokenB, fee, 0, pool);
    }

    function setFeeTo(address _feeTo) external override {
        require(msg.sender == feeToSetter, "UniswapV3: unauthorized");
        feeTo = _feeTo;
    }

    function setFeeToSetter(address _feeToSetter) external override {
        require(msg.sender == feeToSetter, "UniswapV3: unauthorized");
        feeToSetter = _feeToSetter;
    }

    function getPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external view override returns (address) {
        return _pools[tokenA][tokenB];
    }

    function getPoolFee(address tokenA, address tokenB) external view override returns (uint24) {
        return _fee[tokenA][tokenB];
    }
}
