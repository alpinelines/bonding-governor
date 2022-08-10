const { BigNumber } = require("ethers");
const { parseEther } = require("ethers/lib/utils");

const CONNECTOR_WEIGHT = BigNumber.from("1000");
const BASE_Y = parseEther("10");

module.exports = {
    CONNECTOR_WEIGHT,
    BASE_Y
}