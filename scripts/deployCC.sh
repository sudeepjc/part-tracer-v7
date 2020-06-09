
CHANNEL_NAME="$1"
CC_SRC_LANGUAGE="$2"
VERSION="$3"
DELAY="$4"
MAX_RETRY="$5"
VERBOSE="$6"
: ${CHANNEL_NAME:="mychannel"}
: ${CC_SRC_LANGUAGE:="golang"}
: ${VERSION:="1"}
: ${DELAY:="3"}
: ${MAX_RETRY:="5"}
: ${VERBOSE:="false"}
CC_SRC_LANGUAGE=`echo "$CC_SRC_LANGUAGE" | tr [:upper:] [:lower:]`

FABRIC_CFG_PATH=$PWD/configtx/

if [ "$CC_SRC_LANGUAGE" = "go" -o "$CC_SRC_LANGUAGE" = "golang" ] ; then
	CC_RUNTIME_LANGUAGE=golang
	CC_SRC_PATH="./chaincode/partTracer_$VERSION"

	echo Vendoring Go dependencies ...
	pushd $CC_SRC_PATH
	GO111MODULE=on go mod vendor
	popd
	echo Finished vendoring Go dependencies

# sudeep: defaults
# elif [ "$CC_SRC_LANGUAGE" = "javascript" ]; then
# 	CC_RUNTIME_LANGUAGE=node # chaincode runtime language is node.js
# 	CC_SRC_PATH="../chaincode/fabcar/javascript/"

# elif [ "$CC_SRC_LANGUAGE" = "java" ]; then
# 	CC_RUNTIME_LANGUAGE=java
# 	CC_SRC_PATH="../chaincode/fabcar/java/build/install/fabcar"

# 	echo Compiling Java code ...
# 	pushd ../chaincode/fabcar/java
# 	./gradlew installDist
# 	popd
# 	echo Finished compiling Java code

# elif [ "$CC_SRC_LANGUAGE" = "typescript" ]; then
# 	CC_RUNTIME_LANGUAGE=node # chaincode runtime language is node.js
# 	CC_SRC_PATH="../chaincode/fabcar/typescript/"

# 	echo Compiling TypeScript code into JavaScript ...
# 	pushd ../chaincode/fabcar/typescript
# 	npm install
# 	npm run build
# 	popd
# 	echo Finished compiling TypeScript code into JavaScript

else
	echo The chaincode language ${CC_SRC_LANGUAGE} is not supported by this script
	echo Supported chaincode languages are: go, java, javascript, and typescript
	exit 1
fi

# import utils
. scripts/envVar.sh


packageChaincode() {
  ORG=$1
  setGlobals $ORG
  set -x
  peer lifecycle chaincode package partTracer.tar.gz --path ${CC_SRC_PATH} --lang ${CC_RUNTIME_LANGUAGE} --label partTracer_${VERSION} >&log.txt
  res=$?
  set +x
  cat log.txt
  if [ $ORG -eq 1 ]; then
    ORG=general
  elif [ $ORG -eq 2 ]; then
    ORG=airbus 
  else
    ORG=Org3
  fi
  verifyResult $res "Chaincode packaging on peer0.${ORG} has failed"
  echo "===================== Chaincode is packaged on peer0.${ORG} ===================== "
  echo
}

# installChaincode PEER ORG
installChaincode() {
  ORG=$1
  setGlobals $ORG
  set -x
  peer lifecycle chaincode install partTracer.tar.gz >&log.txt
  res=$?
  set +x
  cat log.txt
  if [ $ORG -eq 1 ]; then
    ORG=general
  elif [ $ORG -eq 2 ]; then
    ORG=airbus 
  else
    ORG=Org3
  fi
  verifyResult $res "Chaincode installation on peer0.${ORG} has failed"
  echo "===================== Chaincode is installed on peer0.${ORG} ===================== "
  echo
}

# queryInstalled PEER ORG
queryInstalled() {
  ORG=$1
  setGlobals $ORG
  set -x
  peer lifecycle chaincode queryinstalled >&log.txt
  res=$?
  set +x
  cat log.txt
  if [ $ORG -eq 1 ]; then
    ORG=general
  elif [ $ORG -eq 2 ]; then
    ORG=airbus 
  else
    ORG=Org3
  fi
	PACKAGE_ID=$(sed -n "/partTracer_${VERSION}/{s/^Package ID: //; s/, Label:.*$//; p;}" log.txt)
  verifyResult $res "Query installed on peer0.${ORG} has failed"
  echo PackageID is ${PACKAGE_ID}
  echo "===================== Query installed successful on peer0.${ORG} on channel ===================== "
  echo
}

# approveForMyOrg VERSION PEER ORG
approveForMyOrg() {
  ORG=$1
  setGlobals $ORG
  set -x
  peer lifecycle chaincode approveformyorg -o localhost:7050 --ordererTLSHostnameOverride orderer.parttracer.com --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA --channelID $CHANNEL_NAME --name partTracer --version ${VERSION} --init-required --package-id ${PACKAGE_ID} --sequence ${VERSION} >&log.txt
  set +x
  cat log.txt
  if [ $ORG -eq 1 ]; then
    ORG=general
  elif [ $ORG -eq 2 ]; then
    ORG=airbus 
  else
    ORG=Org3
  fi
  verifyResult $res "Chaincode definition approved on peer0.${ORG} on channel '$CHANNEL_NAME' failed"
  echo "===================== Chaincode definition approved on peer0.${ORG} on channel '$CHANNEL_NAME' ===================== "
  echo
}

# checkCommitReadiness VERSION PEER ORG
checkCommitReadiness() {
  ORG=$1
  shift 1
  setGlobals $ORG
  echo "===================== Checking the commit readiness of the chaincode definition on peer0.org${ORG} on channel '$CHANNEL_NAME'... ===================== "
	local rc=1
	local COUNTER=1
	# continue to poll
  # we either get a successful response, or reach MAX RETRY
	while [ $rc -ne 0 -a $COUNTER -lt $MAX_RETRY ] ; do
    sleep $DELAY
    echo "Attempting to check the commit readiness of the chaincode definition on peer0.${ORG} secs"
    set -x
    peer lifecycle chaincode checkcommitreadiness --channelID $CHANNEL_NAME --name partTracer --version ${VERSION} --sequence ${VERSION} --output json --init-required >&log.txt
    res=$?
    set +x
    let rc=0
    for var in "$@"
    do
      grep "$var" log.txt &>/dev/null || let rc=1
    done
		COUNTER=$(expr $COUNTER + 1)
	done
  cat log.txt
  if [ $ORG -eq 1 ]; then
    ORG=general
  elif [ $ORG -eq 2 ]; then
    ORG=airbus 
  else
    ORG=Org3
  fi
  if test $rc -eq 0; then
    echo "===================== Checking the commit readiness of the chaincode definition successful on peer0.${ORG} on channel '$CHANNEL_NAME' ===================== "
  else
    echo "!!!!!!!!!!!!!!! After $MAX_RETRY attempts, Check commit readiness result on peer0.${ORG} is INVALID !!!!!!!!!!!!!!!!"
    echo
    exit 1
  fi
}

# commitChaincodeDefinition VERSION PEER ORG (PEER ORG)...
commitChaincodeDefinition() {
  parsePeerConnectionParameters $@
  res=$?
  verifyResult $res "Invoke transaction failed on channel '$CHANNEL_NAME' due to uneven number of peer and org parameters "

  # while 'peer chaincode' command can get the orderer endpoint from the
  # peer (if join was successful), let's supply it directly as we know
  # it using the "-o" option
  set -x
  peer lifecycle chaincode commit -o localhost:7050 --ordererTLSHostnameOverride orderer.parttracer.com --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA --channelID $CHANNEL_NAME --name partTracer $PEER_CONN_PARMS --version ${VERSION} --sequence ${VERSION} --init-required >&log.txt
  res=$?
  set +x
  cat log.txt
  if [ $ORG -eq 1 ]; then
    ORG=general
  elif [ $ORG -eq 2 ]; then
    ORG=airbus 
  else
    ORG=Org3
  fi
  verifyResult $res "Chaincode definition commit failed on peer0.${ORG} on channel '$CHANNEL_NAME' failed"
  echo "===================== Chaincode definition committed on channel '$CHANNEL_NAME' ===================== "
  echo
}

# queryCommitted ORG
queryCommitted() {
  ORG=$1
  setGlobals $ORG
  if [ $ORG -eq 1 ]; then
    ORG=general
  elif [ $ORG -eq 2 ]; then
    ORG=airbus 
  else
    ORG=Org3
  fi
  EXPECTED_RESULT="Version: ${VERSION}, Sequence: ${VERSION}, Endorsement Plugin: escc, Validation Plugin: vscc"
  echo "===================== Querying chaincode definition on peer0.${ORG} on channel '$CHANNEL_NAME'... ===================== "
	local rc=1
	local COUNTER=1
	# continue to poll
  # we either get a successful response, or reach MAX RETRY
	while [ $rc -ne 0 -a $COUNTER -lt $MAX_RETRY ] ; do
    sleep $DELAY
    echo "Attempting to Query committed status on peer0.org${ORG}, Retry after $DELAY seconds."
    set -x
    peer lifecycle chaincode querycommitted --channelID $CHANNEL_NAME --name partTracer >&log.txt
    res=$?
    set +x
		test $res -eq 0 && VALUE=$(cat log.txt | grep -o '^Version: [0-9], Sequence: [0-9], Endorsement Plugin: escc, Validation Plugin: vscc')
    test "$VALUE" = "$EXPECTED_RESULT" && let rc=0
		COUNTER=$(expr $COUNTER + 1)
	done
  echo
  cat log.txt
  if test $rc -eq 0; then
    echo "===================== Query chaincode definition successful on peer0.${ORG} on channel '$CHANNEL_NAME' ===================== "
		echo
  else
    echo "!!!!!!!!!!!!!!! After $MAX_RETRY attempts, Query chaincode definition result on peer0.${ORG} is INVALID !!!!!!!!!!!!!!!!"
    echo
    exit 1
  fi
}

chaincodeInvokeInit() {
  parsePeerConnectionParameters $@
  res=$?
  verifyResult $res "Invoke transaction failed on channel '$CHANNEL_NAME' due to uneven number of peer and org parameters "

  # while 'peer chaincode' command can get the orderer endpoint from the
  # peer (if join was successful), let's supply it directly as we know
  # it using the "-o" option
  set -x
  peer chaincode invoke -o localhost:7050 --ordererTLSHostnameOverride orderer.parttracer.com --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA -C $CHANNEL_NAME -n partTracer $PEER_CONN_PARMS --isInit -c '{"function":"initLedger","Args":[]}' >&log.txt
  res=$?
  set +x
  cat log.txt
  verifyResult $res "Invoke execution on $PEERS failed "
  echo "===================== Invoke transaction successful on $PEERS on channel '$CHANNEL_NAME' ===================== "
  echo
}

invokeAddPart(){

  parsePeerConnectionParameters $@
  res=$?
  verifyResult $res "Invoke transaction failed on channel '$CHANNEL_NAME' due to uneven number of peer and org parameters "

  setGlobals $1
  if [ $ORG -eq 1 ]; then
    ORG=general
  elif [ $ORG -eq 2 ]; then
    ORG=airbus 
  else
    ORG=Org3
  fi
  echo "===================== Invoking on peer0.${ORG} on channel '$CHANNEL_NAME'... ===================== "


  # while 'peer chaincode' command can get the orderer endpoint from the
  # peer (if join was successful), let's supply it directly as we know
  # it using the "-o" option
  set -x
  peer chaincode invoke -o localhost:7050 --ordererTLSHostnameOverride orderer.parttracer.com --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA -C $CHANNEL_NAME -n partTracer $PEER_CONN_PARMS -c '{"function":"addPart","Args":["engine_1","engine", "Two seater plane engine","100000","General Org"]}' >&log.txt
  res=$?
  set +x
  cat log.txt
  verifyResult $res "Invoke execution on $PEERS failed "
  echo "===================== Invoke transaction successful on $PEERS on channel '$CHANNEL_NAME' ===================== "
  echo

}

chaincodeQuery() {
  ORG=$1
  setGlobals $ORG
  if [ $ORG -eq 1 ]; then
    ORG=general
  elif [ $ORG -eq 2 ]; then
    ORG=airbus 
  else
    ORG=Org3
  fi
  echo "===================== Querying on peer0.${ORG} on channel '$CHANNEL_NAME'... ===================== "
	local rc=1
	local COUNTER=1
	# continue to poll
  # we either get a successful response, or reach MAX RETRY
	while [ $rc -ne 0 -a $COUNTER -lt $MAX_RETRY ] ; do
    sleep $DELAY
    echo "Attempting to Query peer0.${ORG} ...$(($(date +%s) - starttime)) secs"
    set -x
    peer chaincode query -C $CHANNEL_NAME -n partTracer -c '{"Args":["queryPart","engine_1"]}' >&log.txt
    res=$?
    set +x
		let rc=$res
		COUNTER=$(expr $COUNTER + 1)
	done
  echo
  cat log.txt
  if test $rc -eq 0; then
    echo "===================== Query successful on peer0.${ORG} on channel '$CHANNEL_NAME' ===================== "
		echo
  else
    echo "!!!!!!!!!!!!!!! After $MAX_RETRY attempts, Query result on peer0.${ORG} is INVALID !!!!!!!!!!!!!!!!"
    echo
    exit 1
  fi
}

invokeSellPart(){

  parsePeerConnectionParameters $@
  res=$?
  verifyResult $res "Invoke transaction failed on channel '$CHANNEL_NAME' due to uneven number of peer and org parameters "

  setGlobals $1
  if [ $ORG -eq 1 ]; then
    ORG=general
  elif [ $ORG -eq 2 ]; then
    ORG=airbus 
  else
    ORG=Org3
  fi
  echo "===================== Invoking on peer0.${ORG} on channel '$CHANNEL_NAME'... ===================== "


  # while 'peer chaincode' command can get the orderer endpoint from the
  # peer (if join was successful), let's supply it directly as we know
  # it using the "-o" option
  set -x
  peer chaincode invoke -o localhost:7050 --ordererTLSHostnameOverride orderer.parttracer.com --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA -C $CHANNEL_NAME -n partTracer $PEER_CONN_PARMS -c '{"function":"sellPart","Args":["engine_1","AirbusMSP","9999"]}' >&log.txt
  res=$?
  set +x
  cat log.txt
  verifyResult $res "Invoke execution on $PEERS failed "
  echo "===================== Invoke transaction successful on $PEERS on channel '$CHANNEL_NAME' ===================== "
  echo

}

## at first we package the chaincode
packageChaincode 1

## Install chaincode on peer0.general and peer0.airbus
echo "Installing chaincode on peer0.general..."
installChaincode 1
echo "Install chaincode on peer0.airbus..."
installChaincode 2

## query whether the chaincode is installed
queryInstalled 1

## approve the definition for general
approveForMyOrg 1

## check whether the chaincode definition is ready to be committed
## expect general to have approved and airbus not to
checkCommitReadiness 1 "\"GeneralMSP\": true" "\"AirbusMSP\": false"
checkCommitReadiness 2 "\"GeneralMSP\": true" "\"AirbusMSP\": false"

## now approve also for airbus
approveForMyOrg 2

## check whether the chaincode definition is ready to be committed
## expect them both to have approved
checkCommitReadiness 1 "\"GeneralMSP\": true" "\"AirbusMSP\": true"
checkCommitReadiness 2 "\"GeneralMSP\": true" "\"AirbusMSP\": true"

## now that we know for sure both orgs have approved, commit the definition
commitChaincodeDefinition 1 2

## query on both orgs to see that the definition committed successfully
queryCommitted 1
queryCommitted 2

## Invoke the chaincode
chaincodeInvokeInit 1 2

# sleep 10

# ## Invoke to add the engine part
# echo "Invoking chaincode on peer0.general..."
# invokeAddPart 1 2

# sleep 5

# ## Query chaincode on peer0.general
# echo "Querying chaincode on peer0.general..."
# chaincodeQuery 1

# sleep 5

# ## Invoke to sell the engine part
# echo "Invoking chaincode on peer0.general..."
# invokeSellPart 1 2

# sleep 5

# ## Query chaincode on peer0.airbus
# echo "Querying chaincode on peer0.airbus..."
# chaincodeQuery 2

exit 0