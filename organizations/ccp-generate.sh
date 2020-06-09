#!/bin/bash

function one_line_pem {
    echo "`awk 'NF {sub(/\\n/, ""); printf "%s\\\\\\\n",$0;}' $1`"
}

# function json_ccp {
#     local PP=$(one_line_pem $4)
#     local CP=$(one_line_pem $5)
#     sed -e "s/\${ORG}/$1/" \
#         -e "s/\${P0PORT}/$2/" \
#         -e "s/\${CAPORT}/$3/" \
#         -e "s#\${PEERPEM}#$PP#" \
#         -e "s#\${CAPEM}#$CP#" \
#         organizations/ccp-template.json
# }

function yaml_ccp {
    local PP=$(one_line_pem $4)
    local CP=$(one_line_pem $5)
    sed -e "s/\${ORG}/$1/" \
        -e "s/\${P0PORT}/$2/" \
        -e "s/\${CAPORT}/$3/" \
        -e "s#\${PEERPEM}#$PP#" \
        -e "s#\${CAPEM}#$CP#" \
        -e "s#\${ORGC}#$6#" \
        organizations/ccp-template.yaml | sed -e $'s/\\\\n/\\\n        /g'
}

ORG=general
ORGC=General
P0PORT=7051
CAPORT=7054
PEERPEM=organizations/peerOrganizations/general.parttracer.com/tlsca/tlsca.general.parttracer.com-cert.pem
CAPEM=organizations/peerOrganizations/general.parttracer.com/ca/ca.general.parttracer.com-cert.pem

# echo "$(json_ccp $ORG $P0PORT $CAPORT $PEERPEM $CAPEM)" > organizations/peerOrganizations/general.parttracer.com/connection-general.json
echo "$(yaml_ccp $ORG $P0PORT $CAPORT $PEERPEM $CAPEM $ORGC)" > organizations/peerOrganizations/general.parttracer.com/connection-general.yaml

ORG=airbus
ORGC=Airbus
P0PORT=9051
CAPORT=8054
PEERPEM=organizations/peerOrganizations/airbus.parttracer.com/tlsca/tlsca.airbus.parttracer.com-cert.pem
CAPEM=organizations/peerOrganizations/airbus.parttracer.com/ca/ca.airbus.parttracer.com-cert.pem

# echo "$(json_ccp $ORG $P0PORT $CAPORT $PEERPEM $CAPEM)" > organizations/peerOrganizations/airbus.parttracer.com/connection-airbus.json
echo "$(yaml_ccp $ORG $P0PORT $CAPORT $PEERPEM $CAPEM $ORGC)" > organizations/peerOrganizations/airbus.parttracer.com/connection-airbus.yaml
