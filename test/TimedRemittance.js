const { BN, expectRevert, expectEvent } = require('openzeppelin-test-helpers');

const TimedRemittance = artifacts.require('./TimedRemittance.sol');

contract('TimedRemittance', accounts => {
    describe('cancelRemittance', function () {
        it('reverts when remittance is open', async () => {
            const remittance = await TimedRemittance.new(false, 100);
            const secret = await remittance.generateSecret(accounts[1], web3.utils.fromAscii('aaaa'));
            await remittance.createRemittance(secret, { value: 10, from: accounts[0] });

            await expectRevert(remittance.cancelRemittance(secret), 'Remittance is open');
        });

        it('cancel remittance when expired', async () => {
            const remittance = await TimedRemittance.new(false, 0);
            const secret = await remittance.generateSecret(accounts[1], web3.utils.fromAscii('key'));

            await remittance.createRemittance(secret, { value: 10, from: accounts[0] });

            const { logs } = await remittance.cancelRemittance(secret, { from: accounts[0] });

            expectEvent.inLogs(logs, 'LogCanceled', {
                sender: accounts[0],
                puzzle: secret,
                amount: new BN('10')
            });
        });
    });

    describe('claim', function () {
        it('reverts when remittance expired', async () => {
            const remittance = await TimedRemittance.new(false, 0);
            const key = "dsdfdsf";
            const secret = await remittance.generateSecret(accounts[1], web3.utils.fromAscii(key));
            await remittance.createRemittance(secret, { value: 10, from: accounts[0] });

            await expectRevert(
                remittance.claim(accounts[0], web3.utils.toHex(key), { from: accounts[1] }),
                'Remittance is expired');
        });

        it('claim remittance when open', async () => {
            const remittance = await TimedRemittance.new(false, 100);
            const key = "xc;gjl";
            const secret = await remittance.generateSecret(accounts[1], web3.utils.fromAscii(key));
            await remittance.createRemittance(secret, { value: 10, from: accounts[0] });

            const { logs } = await remittance.claim(accounts[0], web3.utils.toHex(key), { from: accounts[1] });

            expectEvent.inLogs(logs, 'LogClaimed', {
                who: accounts[1],
                amount: new BN('10')
            });
        });
    });
});