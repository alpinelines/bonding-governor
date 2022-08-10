const { expect } = require('chai');
const { ethers } = require('hardhat');
const { BigNumber } = require('ethers');

const { CONNECTOR_WEIGHT, BASE_Y } = require('./Constants');
const { parseEther, formatUnits } = require('ethers/lib/utils');
const { parse } = require('typechain');

let BancorZeroFormulaFactory;
let TokenFactory;
let ReserveFactory;

let formula;
let token;
let reserve;

let first;
let second;
let admin;

describe('ReserveContract', () => {
    before(async () => {
        [first, second, admin] = await ethers.getSigners();

        // BancorZeroFormulaFactory = await ethers.getContractFactory("BancorZeroFormula");
        TokenFactory = await ethers.getContractFactory("Token");
        ReserveFactory = await ethers.getContractFactory("Reserve");

        // formula = await BancorZeroFormulaFactory.deploy();
        token = await TokenFactory.deploy();
        reserve = await ReserveFactory.deploy(
            token.address,
            CONNECTOR_WEIGHT,
            BASE_Y,
            { value: parseEther("100") }
        );
        await token
            .connect(admin)
            .mint(admin.address, 1000000);
    }); 

    xit('should calculate the same nTokens value given purchase price as sale return for nTokens', async () => {
        const nTokens = await reserve.calculatePurchaseReturn(token.totalSupply(), await reserve.connectorBalance(), await reserve.connectorWeight(), parseEther("1"));
        const salePrice = await reserve.calculateSaleReturn(token.totalSupply(), await reserve.connectorBalance(), await reserve.connectorWeight(), nTokens);
        expect(salePrice).to.eq(parseEther("1"));
    })

    it('should mint the correct number of tokens and provide correct connectorBalance and totalSupply values', async () => {
        await reserve.connect(first).buy({ value: parseEther('1') });
        const supply = await token.totalSupply();
        const expectedFinalSupply = supply + await reserve.calculatePurchaseReturn(supply, await reserve.connectorBalance(), await reserve.connectorWeight(), parseEther("1"));
        console.log("expectedFinalSupply: ", expectedFinalSupply, await token.totalSupply());
        expect(await token.totalSupply()).to.eq(BigNumber.from(1000009));
        expect(await token.balanceOf(first.address)).to.eq(BigNumber.from(9));
        expect(ethers.utils.formatUnits(await reserve.connectorBalance(), "wei")).to.eq(parseEther('101'));
        await reserve.connect(second).buy({ value: parseEther('1000') });
    });

    it('should burn the correct number of tokens and provide correct connectorBalance and totalSupply values', async () => {
        await reserve.connect(first).sell(BigNumber.from(9));
        const supply = await token.totalSupply();
        const expectedFinalSupply = supply + await reserve.calculatePurchaseReturn(supply, await reserve.connectorBalance(), await reserve.connectorWeight(), parseEther("1"));
        console.log("expectedFinalSupply: ", expectedFinalSupply, await token.totalSupply());
        expect(await token.totalSupply()).to.eq(BigNumber.from(1002391));
        expect(formatUnits(await reserve.connectorBalance(), "wei")).to.eq(BigNumber.from('1091158925398268290036'));
    });

    it('should fallback to buy when receiving ether', async () => {
        // await reserve.connect(second).buy({ value: parseEther("1") });
        const supply = Number(await token.totalSupply());
        const expectedFinalSupply = supply + Number(await reserve.calculatePurchaseReturn(supply, await reserve.connectorBalance(), await reserve.connectorWeight(), parseEther("1.1")));
        await second.sendTransaction({ to: reserve.address, value: parseEther('1.1') });
        expect(await token.totalSupply()).to.eq(expectedFinalSupply);
        expect(formatUnits(await reserve.connectorBalance(), "wei")).to.eq(BigNumber.from('1092258925398268290036'));
    });
    
});