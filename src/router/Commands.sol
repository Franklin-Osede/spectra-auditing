// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.29;

// Based on https://github.com/Uniswap/universal-router/blob/main/contracts/libraries/Commands.sol

library Commands {
    bytes1 internal constant COMMAND_TYPE_MASK = 0x3f;

    /**
     * Transfers tokens from msg.sender to the Router.
     * (address token, uint256 value)
     */
    uint256 constant TRANSFER_FROM = 0x00;

    /**
     * Transfers tokens from msg.sender to the Router with a permit.
     * (address token, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s)
     */
    uint256 constant TRANSFER_FROM_WITH_PERMIT = 0x01;

    /**
     * Transfers tokens from the Router to a recipient.
     * (address token, address recipient, uint256 value)
     */
    uint256 constant TRANSFER = 0x02;

    /**
     * Performs a swap on Curve CryptoSwap pool.
     * (address pool, uint256 i, uint256 j, uint256 amountIn, uint256 minAmountOut, address recipient)
     */
    uint256 constant CURVE_SWAP = 0x03;

    /**
     * Deposits an ERC20 underlying into an ERC4626 IBT
     * ibt represents the target IBT and assets represents the amount of underlying to deposit
     * (address ibt, uint256 assets, address recipient)
     */
    uint256 constant DEPOSIT_ASSET_IN_IBT = 0x04;

    /**
     * Deposits an ERC20 underlying into a PT
     * assets represents the amount of underlying to deposit
     * (address pt, uint256 assets, address ptRecipient, address ytRecipient, uint256 minShares)
     */
    uint256 constant DEPOSIT_ASSET_IN_PT = 0x05;

    /**
     * Deposits an ERC4626 IBT into a PT
     * ibts represents the amount of IBT to deposit
     * (address pt, uint256 ibts, address ptRecipient, address ytRecipient, uint256 minShares)
     */
    uint256 constant DEPOSIT_IBT_IN_PT = 0x06;

    /**
     * Redeems an ERC4626 IBT for the corresponding ERC20 underlying
     * ibt represents the target IBT and shares represents the amount of IBT to redeem
     * (address ibt, uint256 shares, address recipient)
     */
    uint256 constant REDEEM_IBT_FOR_ASSET = 0x07;

    /**
     * Redeems a PT:YT pair for the corresponding ERC20 underlying
     * shares represents the amount of PT to redeem
     * (address pt, uint256 shares, address recipient, uint256 minAssets)
     */
    uint256 constant REDEEM_PT_FOR_ASSET = 0x08;

    /**
     * Redeems a PT:YT pair for the corresponding ERC4626 IBT
     * shares represents the amount of PT to redeem
     * (address pt, uint256 shares, address recipient, uint256 minIbts)
     */
    uint256 constant REDEEM_PT_FOR_IBT = 0x09;

    /**
     * Performs a flash loan
     * data represents the sequence of commands and inputs to be executed during the loan
     * (address lender, address token, uint256 amount, bytes calldata data)
     */
    uint256 constant FLASH_LOAN = 0x0a;

    /**
     * Splits liquidity between IBT and PT before depositing in a Curve CryptoSwap pool
     * ibts represents the amount of IBT to split between IBT and PT before depositing in the pool
     * recipient represents the address that will receive the IBT/PT
     * ytRecipient represents the address that will receive the YTs generated by the split
     * (address pool, uint256 ibts, address recipient, address ytRecipient, uint256 minPTShares)
     */
    uint256 constant CURVE_SPLIT_IBT_LIQUIDITY = 0x0b;

    /**
     * Deposits coins into a Curve CryptoSwap pool
     * amounts includes the amounts of IBT and PT to deposit in the pool
     * min_mint_amount represents the minimum amount of LP tokens to mint
     * (address pool, uint256[2] amounts, uint256 min_mint_amount, address recipient)
     */
    uint256 constant CURVE_ADD_LIQUIDITY = 0x0c;

    /**
     * Withdraws coins from a Curve CryptoSwap pool
     * lps represents the amount of LP tokens to burn
     * min_amounts represents the minimum amount of coins to receive
     * (address pool, uint256 lps, uint256[2] min_amounts, address recipient)
     */
    uint256 constant CURVE_REMOVE_LIQUIDITY = 0x0d;

    /**
     * Withdraws a single coin from a Curve CryptoSwap pool
     * lps represents the amount of LP tokens to burn
     * i represents the index of the coin to withdraw
     * min_amount represents the minimum amount of coin to receive
     * (address pool, uint256 lps, uint256 i, uint256 min_amount, address recipient)
     */
    uint256 constant CURVE_REMOVE_LIQUIDITY_ONE_COIN = 0x0e;

    /**
     * Performs a minimum balance check.
     * (address token, address owner, uint256 minValue)
     */
    uint256 constant ASSERT_MIN_BALANCE = 0x0f;

    /**
     * Wraps shares of an interest-bearing vault into an ERC-4626 Wrapper
     * vaultShares represents the amount of vault shares to unwrap
     * (address wrapper, uint256 vaultShares, address recipient)
     */
    uint256 constant WRAP_VAULT_IN_4626_ADAPTER = 0x10;

    /**
     * Unwraps shares of an interest-bearing vault from an ERC-4626 Wrapper
     * wrapperShares represents the amount of wrapper shares to redeem
     * (address wrapper, uint256 wrapperShares, address recipient)
     */
    uint256 constant UNWRAP_VAULT_FROM_4626_ADAPTER = 0x11;

    /**
     * Performs a swap on Kyberswap.
     * (address tokenIn, uint256 amountIn, address tokenOut, uint256 expectedAmountOut, bytes targetData)
     */
    uint256 constant KYBER_SWAP = 0x12;

    /**
     * Removes liquidity from Pendle.
     * (address receiver, address market, uint256 netLpToRemove, TokenOutput calldata output, LimitOrderData calldata limit)
     */
    uint256 constant PENDLE_REMOVE_LIQUIDITY_SINGLE_TOKEN = 0x13;

    /**
     * Performs a swap on a Curve TwoCrypto NG pool.
     * (address pool, uint256 i, uint256 j, uint256 amountIn, uint256 minAmountOut, address recipient)
     */
    uint256 constant CURVE_NG_SWAP = 0x15;

    /**
     * Splits liquidity between IBT and PT before depositing in a Curve TwoCrypto NG pool.
     * ibts represents the amount of IBT to split between IBT and PT before depositing in the pool
     * recipient represents the address that will receive the IBT/PT
     * ytRecipient represents the address that will receive the YTs generated by the split
     * (address pool, uint256 ibts, address recipient, address ytRecipient, uint256 minPTShares)
     */
    uint256 constant CURVE_NG_SPLIT_IBT_LIQUIDITY = 0x16;

    /**
     * Deposits coins into a Curve TwoCrypto NG pool.
     * amounts includes the amounts of IBT and PT to deposit in the pool
     * min_mint_amount represents the minimum amount of LP tokens to mint
     * (address pool, uint256[2] amounts, uint256 min_mint_amount, address recipient)
     */
    uint256 constant CURVE_NG_ADD_LIQUIDITY = 0x17;

    /**
     * Withdraws coins from a Curve TwoCrypto NG pool.
     * lps represents the amount of LP token shares to burn
     * min_amounts represents the minimum amount of coins to receive
     * (address pool, uint256 lps, uint256[2] min_amounts, address recipient)
     */
    uint256 constant CURVE_NG_REMOVE_LIQUIDITY = 0x18;

    /**
     * Withdraws a single coin from a Curve TwoCrypto NG pool.
     * lps represents the amount of LP token shares to burn
     * i represents the index of the coin to withdraw
     * min_amount represents the minimum amount of coin to receive
     * (address pool, uint256 lps, uint256 i, uint256 min_amount, address recipient)
     */
    uint256 constant CURVE_NG_REMOVE_LIQUIDITY_ONE_COIN = 0x19;

    /**
     * Splits liquidity between IBT and PT before depositing in a Curve Stableswap NG pool
     * ibts represents the amount of IBT to split between IBT and PT before depositing in the pool
     * recipient represents the address that will receive the IBT/PT
     * ytRecipient represents the address that will receive the YTs generated by the split
     * (address pool, uint256 ibts, address recipient, address ytRecipient, uint256 minPTShares)
     */
    uint256 constant CURVE_SPLIT_IBT_LIQUIDITY_SNG = 0x1A;

    /**
     * Deposits coins into a Curve Stableswap NG pool
     * amounts includes the amounts of IBT and PT to deposit in the pool
     * min_mint_amount represents the minimum amount of LP tokens to mint
     * (address pool, uint256[2] amounts, uint256 min_mint_amount, address recipient)
     */
    uint256 constant CURVE_ADD_LIQUIDITY_SNG = 0x1B;

    /**
     * Withdraws coins from a Curve Stableswap NG pool
     * lps represents the amount of LP tokens to burn
     * min_amounts represents the minimum amount of coins to receive
     * (address pool, uint256 lps, uint256[2] min_amounts, address recipient)
     */
    uint256 constant CURVE_REMOVE_LIQUIDITY_SNG = 0x1C;

    /**
     * Withdraws a single coin from a Curve Stableswap NG pool
     * lps represents the amount of LP tokens to burn
     * i represents the index of the coin to withdraw
     * min_amount represents the minimum amount of coin to receive
     * (address pool, uint256 lps, uint256 i, uint256 min_amount, address recipient)
     */
    uint256 constant CURVE_REMOVE_LIQUIDITY_ONE_COIN_SNG = 0x1D;

    /**
     * Performs a swap on Curve Stableswap NG pool.
     * (address pool, uint256 i, uint256 j, uint256 amountIn, uint256 minAmountOut, address recipient)
     */
    uint256 constant CURVE_SWAP_SNG = 0x1E;

    /**
     * Given a ratio in which we want to add liquidity to Curve legacy Cryptoswap pools, calculates the amount of IBTs to tokenize in PTs and YTs
     * so that the ratio of the IBTs left after tokenization with the PTs obtained via tokenization mathes the
     * proportion given in function call arguments.
     * (address pool, uint256 ibts, uint256 prop, address recipient, address ytRecipient, uint256 minPTShares)
     */
    uint256 constant CURVE_SPLIT_IBT_LIQUIDITY_CUSTOM_PROP = 0x1F;

    /**
     * Given a ratio in which we want to add liquidity to Curve NG Cryptoswap pools, calculates the amount of IBTs to tokenize in PTs and YTs
     * so that the ratio of the IBTs left after tokenization with the PTs obtained via tokenization mathes the
     * proportion given in function call arguments.
     * (address pool, uint256 ibts, uint256 prop, address recipient, address ytRecipient, uint256 minPTShares)
     */
    uint256 constant CURVE_SPLIT_IBT_LIQUIDITY_CUSTOM_PROP_NG = 0x20;

    /**
     * Given a ratio in which we want to add liquidity to Curve StableSwap pools, calculates the amount of IBTs to tokenize in PTs and YTs
     * so that the ratio of the IBTs left after tokenization with the PTs obtained via tokenization mathes the
     * proportion given in function call arguments.
     * (address pool, uint256 ibts, uint256 prop, address recipient, address ytRecipient, uint256 minPTShares)
     */
    uint256 constant CURVE_SPLIT_IBT_LIQUIDITY_CUSTOM_PROP_SNG = 0x21;

    /**
     * Deposits native token into a wrapper.
     * (address wrapper, uint256 amount)
     */
    uint256 constant DEPOSIT_NATIVE_IN_WRAPPER = 0x22;

    /**
     * Withdraws native token from a wrapper.
     * (address wrapper, uint256 amount)
     */
    uint256 constant WITHDRAW_NATIVE_FROM_WRAPPER = 0x23;

    /**
     * Transfers native token to a recipient.
     * (address recipient, uint256 amount)
     */
    uint256 constant TRANSFER_NATIVE = 0x24;
}
