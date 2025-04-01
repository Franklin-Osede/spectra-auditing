// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.20;

import {AggregatorV3Interface} from "src/interfaces/AggregatorV3Interface.sol";
import {BaseFeedCurveLPTIBTSNG} from "src/spectra-oracles/chainlinkFeeds/stableswap-ng/BaseFeedCurveLPTIBT.sol";

/// @dev Mock Curve PT price feed that gives the LPT price in a provided IBT/PT Curve Pool in IBT
contract MockPriceFeedCurveLPTIBTSNG is BaseFeedCurveLPTIBTSNG {
    string public constant description = "IBT/PT Curve Pool Oracle: LPT price in IBT";

    /* CONSTRUCTOR
     *****************************************************************************************************************/
    /**
     * @notice Constructor for a Mock Price Feed of a Curve Pool (in IBT)
     */
    constructor(address _pt, address _pool) BaseFeedCurveLPTIBTSNG(_pt, _pool) {}
}
