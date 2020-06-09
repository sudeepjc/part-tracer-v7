#!/bin/bash

# import utils
source scripts/envVar.sh

parsePeerConnectionParameters $@

echo $PEER_CONN_PARMS

export PEER_CONN_PARMS=$PEER_CONN_PARMS