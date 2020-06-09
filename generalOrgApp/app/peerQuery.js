const Client = require('fabric-client');
const getClientContext =  require('./getClientContext');

async function getPeerInfo(user, org, peerName){
  
  let client = await getClientContext(user,org);

  let peer = await client.getPeer(peerName);

  // Creates a new peer with specified properties - same as above except that
  // it will use the default connection properties not the cone specified in YAML
  // let peer=client.newPeer("grpc://localhost:7051", {name:"new-peer"})
  console.log(`Peer Name=${peer.getName()}  URL=${peer.getUrl()}`);

  let chans = await client.queryChannels(peer, true);
  console.log("Channels joined:");
  for (var i=0; i<chans.channels.length; i++){
    console.log(`\t${i+1}. ${chans.channels[i].channel_id}`);
  }

  let chaincodes = await client.queryInstalledChaincodes(peer, true);
  console.log("Chaincode installed:");
  for (var i=0; i<chaincodes.chaincodes.length; i++){
    console.log(`\t${i+1}. name=${chaincodes.chaincodes[i].name} version=${chaincodes.chaincodes[i].version}`);
  }

  let peerQueryRequest = {
    target: peer,
    useAdmin: true
  }
  let peerQueryResponse = await client.queryPeers(peerQueryRequest);
  console.log("Gossip network:");
  if (peerQueryResponse.local_peers.GeneralMSP && peerQueryResponse.local_peers.GeneralMSP.peers.length > 0){
    console.log(`\t${peerQueryResponse.local_peers.GeneralMSP.peers[0].mspid}: ${peerQueryResponse.local_peers.GeneralMSP.peers[0].endpoint}`);
  }

  if (peerQueryResponse.local_peers.AirbusMSP && peerQueryResponse.local_peers.AirbusMSP.peers.length > 0){
    console.log(`\t${peerQueryResponse.local_peers.AirbusMSP.peers[0].mspid}: ${peerQueryResponse.local_peers.AirbusMSP.peers[0].endpoint}`);
  }
}

getPeerInfo("Admin", "general", "peer0.general.parttracer.com");