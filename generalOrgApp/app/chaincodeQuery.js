const asn = require('asn1.js');
var sha = require('js-sha256');

const Client = require('fabric-client');
const getClientContext =  require('./getClientContext');



async function getChaincode(user, org, channelName){
  
  let client = await getClientContext(user,org);

  let channel = await getChannel(channelName, client);

  await getChannelInfo(channel);
}

/**
* Gathers info for the channel
* Prints the information for the 2 latest blocks
*/
async function getChannelInfo(channel) {

  // Gets the info on the blockchain
  let info = await channel.queryInfo()

  const blockHeight = parseInt(info.height.low);
  console.log(`Current Chain Height: ${blockHeight}\n`)

  // Lets make sure there are enough blocks in chai
  if (blockHeight < 3) {
      console.log("Not enough height!! - please invoke chaincode!!")
      return
  }

  // Get the latest block
  let block = await channel.queryBlock(blockHeight - 1)
  printBlockInfo(block)
   
  // Get the previous block with hash from latest block
  block = await channel.queryBlock(blockHeight - 2)
  printBlockInfo(block)
 
}

async function getChannel(channelName, client) {
  try {
      // Get the Channel class instance from client
      channel = await client.getChannel(channelName, true)
  } catch (e) {
      console.log("Could NOT create channel: ", channelName)
      process.exit(1)
  }
  console.log("Created channel object.")

  return channel
}

function printBlockInfo(block) {
  console.log('Block Number: ' + block.header.number);
  console.log('Block Hash: ' +calculateBlockHash(block.header))
  console.log('\tPrevious Hash: ' + block.header.previous_hash);
  console.log('\tData Hash: ' + block.header.data_hash);
  console.log('\tTransactions Count: ' + block.data.data.length);

  block.data.data.forEach(transaction => {
    console.log('\t\tTransaction ID: ' + transaction.payload.header.channel_header.tx_id);
    console.log('\t\tCreator ID: ' + transaction.payload.header.signature_header.creator.Mspid);
  // Following lines if uncommented will dump too much info :)
  //   console.log('Data: ');
  //   console.log(JSON.stringify(transaction.payload.data));
  })
}

function calculateBlockHash(header) {
  let headerAsn = asn.define('headerAsn', function () {
      this.seq().obj(
          this.key('Number').int(),
          this.key('PreviousHash').octstr(),
          this.key('DataHash').octstr()
      );
  });

  let output = headerAsn.encode({
      Number: parseInt(header.number),
      PreviousHash: Buffer.from(header.previous_hash, 'hex'),
      DataHash: Buffer.from(header.data_hash, 'hex')
  }, 'der');

  let hash = sha.sha256(output);
  return hash;
}

getChaincode("User1", "general", "mychannel");