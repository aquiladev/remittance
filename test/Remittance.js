const { BN, expectRevert, constants, send, balance, expectEvent } = require('openzeppelin-test-helpers');

const Remittance = artifacts.require('./Remittance.sol');

contract('Remittance', accounts => {
    let remittance;
    beforeEach(async () => {
        remittance = await Remittance.new();
    });

    describe('fallback', function () {
        it('reverts when send value', async () => {
            await expectRevert.unspecified(send.ether(accounts[4], remittance.address, new BN('1')));
        });
    });

    describe('resume', function () {
        it('reverts when killed', async () => {
            remittance.pause();
            remittance.kill();

            await expectRevert(remittance.resume(), 'Killed');
        });
    });

    describe('createRemittance', function () {
        it('reverts when key is zero', async () => {
            await expectRevert(remittance.createRemittance('0x0'), 'Key cannot be zero');
        });

        it('reverts when key is empty', async () => {
            await expectRevert(remittance.createRemittance('0x'), 'Key cannot be zero');
        });

        it('reverts when value is zero', async () => {
            await expectRevert(remittance.createRemittance('0x1', { value: 0 }), 'Value should be greater 0 Wei');
        });

        it('reverts when paused', async () => {
            remittance.pause();

            await expectRevert(remittance.createRemittance('0x1', { value: 1 }), 'Paused');
        });

        it('should remit', async () => {
            const { logs } = await remittance.createRemittance('0x21', { value: 1, from: accounts[0] });

            (await remittance.balances(accounts[0])).should.be.bignumber.equal('1');
            expectEvent.inLogs(logs, 'LogRemitted', {
                sender: accounts[0],
                puzzle: web3.utils.padRight('0x21', 64),
                amount: new BN('1')
            });
        });

        it('should consume right amount of wei', async () => {
            const balanceSender = new BN(await web3.eth.getBalance(accounts[0]));
            const gasPrice = new BN('20000000');

            const result = await remittance.createRemittance('0x12e', { value: 15, from: accounts[0], gasPrice });

            const newBalanceSender = new BN(await web3.eth.getBalance(accounts[0]));
            const gasUsed = new BN(gasPrice).mul(new BN(result.receipt.gasUsed));
            const delta = balanceSender.sub(newBalanceSender).sub(gasUsed);

            delta.should.be.bignumber.equal('15');
        });
    })

    describe('claim', function () {
        it('reverts when sender is empty', async () => {
            await expectRevert(remittance.claim(constants.ZERO_ADDRESS, '0x'), 'Sender cannot be empty');
        });

        it('reverts when nothing to claim', async () => {
            await expectRevert(remittance.claim(accounts[1], '0x'), 'Amount cannot be zero');
        });

        it('reverts when paused', async () => {
            remittance.pause();

            await expectRevert(remittance.claim(accounts[1], '0x'), 'Paused');
        });

        it('should claim', async () => {
            const key = 'hi there';
            const secret = await remittance.generateSecret(accounts[1], web3.utils.fromAscii(key));
            await remittance.createRemittance(secret, { value: 10, from: accounts[0] });

            const { logs } = await remittance.claim(
                accounts[0],
                web3.utils.toHex(key),
                { from: accounts[1] });

            (await remittance.balances(accounts[0])).should.be.bignumber.equal('0');
            expectEvent.inLogs(logs, 'LogClaimed', {
                who: accounts[1],
                amount: new BN('10')
            });
        });

        it('reverts when cliam twice', async () => {
            const key = 'Hi there';
            const secret = await remittance.generateSecret(accounts[2], web3.utils.fromAscii(key));
            await remittance.createRemittance(secret, { value: 10, from: accounts[0] });

            await remittance.claim(
                accounts[0],
                web3.utils.toHex(key),
                { from: accounts[2] });

            await expectRevert(remittance.claim(
                accounts[0],
                web3.utils.toHex(key),
                { from: accounts[2] }), 'Amount cannot be zero');
        });
    });
});