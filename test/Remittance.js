const { BN, expectRevert, constants, send, balance, expectEvent } = require('openzeppelin-test-helpers');

const Remittance = artifacts.require('./Remittance.sol');

let remittance;

contract('Remittance', accounts => {
    beforeEach(async () => {
        remittance = await Remittance.new();
    });

    describe('fallback', function () {
        it('reverts when send value', async () => {
            await expectRevert.unspecified(send.ether(accounts[4], remittance.address, new BN('1')));
        });
    });

    describe('remit', function () {
        it('reverts when key is zero', async () => {
            await expectRevert(remittance.remit('0x0'), 'Key cannot be zero');
        });

        it('reverts when key is empty', async () => {
            await expectRevert(remittance.remit('0x'), 'Key cannot be zero');
        });

        it('reverts when value is zero', async () => {
            await expectRevert(remittance.remit('0x1', { value: 0 }), 'Value should be greater 0 Wei');
        });

        it('reverts when paused', async () => {
            remittance.pause();

            await expectRevert(remittance.remit('0x1', { value: 1 }), 'Paused');
        });

        it('reverts when killed', async () => {
            remittance.kill();

            await expectRevert(remittance.remit('0x1', { value: 1 }), 'Killed');
        });

        it('should remit', async () => {
            const { logs } = await remittance.remit('0x21', { value: 1, from: accounts[0] });

            (await remittance.balances(accounts[0])).should.be.bignumber.equal('1');
            expectEvent.inLogs(logs, 'LogRemitted', {
                remitter: accounts[0],
                puzzle: web3.utils.padRight('0x21', 64),
                amount: new BN('1')
            });
        });

        it('should consume right amount of wei', async () => {
            const balanceSender = new BN(await web3.eth.getBalance(accounts[0]));
            const gasPrice = new BN('20000000');

            const result = await remittance.remit('0x12e', { value: 15, from: accounts[0], gasPrice });

            const newBalanceSender = new BN(await web3.eth.getBalance(accounts[0]));
            const gasUsed = new BN(gasPrice).mul(new BN(result.receipt.gasUsed));
            const delta = balanceSender.sub(newBalanceSender).sub(gasUsed);

            delta.should.be.bignumber.equal('15');
        });
    })

    describe('claim', function () {
        it('reverts when remitter is empty', async () => {
            await expectRevert(remittance.claim(constants.ZERO_ADDRESS, '0x', '0x'), 'Remitter cannot be empty');
        });

        it('reverts when nothing to claim', async () => {
            await expectRevert(remittance.claim(accounts[1], '0x', '0x'), 'Amount cannot be zero');
        });

        it('reverts when paused', async () => {
            remittance.pause();

            await expectRevert(remittance.claim(accounts[1], '0x', '0x'), 'Paused');
        });

        it('should claim', async () => {
            const pwd1 = 'hi there';
            const pwd2 = 'good luck';
            const key = calcKey(accounts[1], pwd1, pwd2);
            await remittance.remit(key, { value: 10, from: accounts[0] });

            const { logs } = await remittance.claim(
                accounts[0],
                web3.utils.toHex(pwd1),
                web3.utils.toHex(pwd2),
                { from: accounts[1] });

            (await remittance.balances(accounts[0])).should.be.bignumber.equal('0');
            expectEvent.inLogs(logs, 'LogClaimed', {
                who: accounts[1],
                amount: new BN('10')
            });
        });

        it('reverts when cliam twice', async () => {
            const pwd1 = 'Hi there';
            const pwd2 = 'good luck J';
            const key = calcKey(accounts[2], pwd1, pwd2);
            await remittance.remit(key, { value: 10, from: accounts[0] });

            await remittance.claim(
                accounts[0],
                web3.utils.toHex(pwd1),
                web3.utils.toHex(pwd2),
                { from: accounts[2] });

            await expectRevert(remittance.claim(
                accounts[0],
                web3.utils.toHex(pwd1),
                web3.utils.toHex(pwd2),
                { from: accounts[2] }), 'Amount cannot be zero');
        });

        // all params must be hex
        calcKey = (...params) => {
            params = params
                .map(arg => {
                    if (typeof arg === 'string') {
                        if (arg.substring(0, 2) === '0x') {
                            return arg.slice(2);
                        } else {
                            return web3.utils.padRight(web3.utils.toHex(arg), 64).slice(2);
                        }
                    }
                    return '';
                })
                .join('');
            return web3.utils.keccak256(`0x${params}`);
        }
    });
});