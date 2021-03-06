var utils = require('web3-utils')
var BondedToken = artifacts.require('./BondedToken.sol')

let gasPrice = 1000000000 // 1GWEI

let _ = '        '

contract('BondedToken', async function(accounts) {
  let bondedToken

  before(done => {
    ;(async () => {
      try {
        var totalGas = new web3.BigNumber(0)

        // Deploy BondedToken.sol
        bondedToken = await BondedToken.new()
        var tx = web3.eth.getTransactionReceipt(bondedToken.transactionHash)
        totalGas = totalGas.plus(tx.gasUsed)
        console.log(_ + tx.gasUsed + ' - Deploy bondedToken')
        bondedToken = await BondedToken.deployed()

        console.log(_ + '-----------------------')
        console.log(_ + totalGas.toFormat(0) + ' - Total Gas')
        done()
      } catch (error) {
        console.error(error)
        done(false)
      }
    })()
  })

  describe('BondedToken.sol', function() {
    it('should pass', async function() {
      assert(
        true === true,
        'this is true'
      )
    })

  })
})

function getBlockNumber() {
  return new Promise((resolve, reject) => {
    web3.eth.getBlockNumber((error, result) => {
      if (error) reject(error)
      resolve(result)
    })
  })
}

function increaseBlocks(blocks) {
  return new Promise((resolve, reject) => {
    increaseBlock().then(() => {
      blocks -= 1
      if (blocks == 0) {
        resolve()
      } else {
        increaseBlocks(blocks).then(resolve)
      }
    })
  })
}

function increaseBlock() {
  return new Promise((resolve, reject) => {
    web3.currentProvider.sendAsync(
      {
        jsonrpc: '2.0',
        method: 'evm_mine',
        id: 12345
      },
      (err, result) => {
        if (err) reject(err)
        resolve(result)
      }
    )
  })
}

function decodeEventString(hexVal) {
  return hexVal
    .match(/.{1,2}/g)
    .map(a =>
      a
        .toLowerCase()
        .split('')
        .reduce(
          (result, ch) => result * 16 + '0123456789abcdefgh'.indexOf(ch),
          0
        )
    )
    .map(a => String.fromCharCode(a))
    .join('')
}
