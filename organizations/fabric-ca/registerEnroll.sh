

function createGeneral {

  echo
	echo "Enroll the CA admin"
  echo
	mkdir -p organizations/peerOrganizations/general.parttracer.com/

	export FABRIC_CA_CLIENT_HOME=${PWD}/organizations/peerOrganizations/general.parttracer.com/
#  rm -rf $FABRIC_CA_CLIENT_HOME/fabric-ca-client-config.yaml
#  rm -rf $FABRIC_CA_CLIENT_HOME/msp

  set -x
  fabric-ca-client enroll -u https://generalAdmin:generalAdminpw@localhost:7054 --caname ca-general --tls.certfiles ${PWD}/organizations/fabric-ca/general/tls-cert.pem
  set +x

  echo 'NodeOUs:
  Enable: true
  ClientOUIdentifier:
    Certificate: cacerts/localhost-7054-ca-general.pem
    OrganizationalUnitIdentifier: client
  PeerOUIdentifier:
    Certificate: cacerts/localhost-7054-ca-general.pem
    OrganizationalUnitIdentifier: peer
  AdminOUIdentifier:
    Certificate: cacerts/localhost-7054-ca-general.pem
    OrganizationalUnitIdentifier: admin
  OrdererOUIdentifier:
    Certificate: cacerts/localhost-7054-ca-general.pem
    OrganizationalUnitIdentifier: orderer' > ${PWD}/organizations/peerOrganizations/general.parttracer.com/msp/config.yaml

  echo
	echo "Register peer0"
  echo
  set -x
	fabric-ca-client register --caname ca-general --id.name peer0 --id.secret peer0pw --id.type peer --tls.certfiles ${PWD}/organizations/fabric-ca/general/tls-cert.pem
  set +x

  echo
  echo "Register user"
  echo
  set -x
  fabric-ca-client register --caname ca-general --id.name User1 --id.secret User1pw --id.type client --tls.certfiles ${PWD}/organizations/fabric-ca/general/tls-cert.pem
  set +x

  echo
  echo "Register the org admin"
  echo
  set -x
  fabric-ca-client register --caname ca-general --id.name Admin --id.secret Adminpw --id.type admin --tls.certfiles ${PWD}/organizations/fabric-ca/general/tls-cert.pem
  set +x

  echo
  echo "Create a new affiliation"
  echo
  set -x
  fabric-ca-client affiliation add general.manufacturing --tls.certfiles ${PWD}/organizations/fabric-ca/general/tls-cert.pem
  set +x

  echo
  echo "Register manu from Manufacturing"
  echo
  set -x
  fabric-ca-client register --id.name manu --id.secret manupw --id.type client --id.affiliation general.manufacturing --tls.certfiles ${PWD}/organizations/fabric-ca/general/tls-cert.pem
  set +x

  echo
  echo "Register salu from Sales"
  echo
  set -x
  fabric-ca-client register --id.name salu --id.secret salupw --id.type client --id.affiliation general.sales.sharks --tls.certfiles ${PWD}/organizations/fabric-ca/general/tls-cert.pem
  set +x

  echo
  echo "Register balu from Sales"
  echo
  set -x
  fabric-ca-client register --id.name balu --id.secret balupw --id.type client --id.affiliation general.sales.mgrs --tls.certfiles ${PWD}/organizations/fabric-ca/general/tls-cert.pem
  set +x


	mkdir -p organizations/peerOrganizations/general.parttracer.com/peers
  mkdir -p organizations/peerOrganizations/general.parttracer.com/peers/peer0.general.parttracer.com

  echo
  echo "## Generate the peer0 msp"
  echo
  set -x
	fabric-ca-client enroll -u https://peer0:peer0pw@localhost:7054 --caname ca-general -M ${PWD}/organizations/peerOrganizations/general.parttracer.com/peers/peer0.general.parttracer.com/msp --csr.hosts peer0.general.parttracer.com --tls.certfiles ${PWD}/organizations/fabric-ca/general/tls-cert.pem
  set +x

  cp ${PWD}/organizations/peerOrganizations/general.parttracer.com/msp/config.yaml ${PWD}/organizations/peerOrganizations/general.parttracer.com/peers/peer0.general.parttracer.com/msp/config.yaml

  echo
  echo "## Generate the peer0-tls certificates"
  echo
  set -x
  fabric-ca-client enroll -u https://peer0:peer0pw@localhost:7054 --caname ca-general -M ${PWD}/organizations/peerOrganizations/general.parttracer.com/peers/peer0.general.parttracer.com/tls --enrollment.profile tls --csr.hosts peer0.general.parttracer.com --csr.hosts localhost --tls.certfiles ${PWD}/organizations/fabric-ca/general/tls-cert.pem
  set +x


  cp ${PWD}/organizations/peerOrganizations/general.parttracer.com/peers/peer0.general.parttracer.com/tls/tlscacerts/* ${PWD}/organizations/peerOrganizations/general.parttracer.com/peers/peer0.general.parttracer.com/tls/ca.crt
  cp ${PWD}/organizations/peerOrganizations/general.parttracer.com/peers/peer0.general.parttracer.com/tls/signcerts/* ${PWD}/organizations/peerOrganizations/general.parttracer.com/peers/peer0.general.parttracer.com/tls/server.crt
  cp ${PWD}/organizations/peerOrganizations/general.parttracer.com/peers/peer0.general.parttracer.com/tls/keystore/* ${PWD}/organizations/peerOrganizations/general.parttracer.com/peers/peer0.general.parttracer.com/tls/server.key

  mkdir ${PWD}/organizations/peerOrganizations/general.parttracer.com/msp/tlscacerts
  cp ${PWD}/organizations/peerOrganizations/general.parttracer.com/peers/peer0.general.parttracer.com/tls/tlscacerts/* ${PWD}/organizations/peerOrganizations/general.parttracer.com/msp/tlscacerts/ca.crt

  mkdir ${PWD}/organizations/peerOrganizations/general.parttracer.com/tlsca
  cp ${PWD}/organizations/peerOrganizations/general.parttracer.com/peers/peer0.general.parttracer.com/tls/tlscacerts/* ${PWD}/organizations/peerOrganizations/general.parttracer.com/tlsca/tlsca.general.parttracer.com-cert.pem

  mkdir ${PWD}/organizations/peerOrganizations/general.parttracer.com/ca
  cp ${PWD}/organizations/peerOrganizations/general.parttracer.com/peers/peer0.general.parttracer.com/msp/cacerts/* ${PWD}/organizations/peerOrganizations/general.parttracer.com/ca/ca.general.parttracer.com-cert.pem

  mkdir -p organizations/peerOrganizations/general.parttracer.com/users
  mkdir -p organizations/peerOrganizations/general.parttracer.com/users/User1@general.parttracer.com

  echo
  echo "## Generate the user msp"
  echo
  set -x
	fabric-ca-client enroll -u https://User1:User1pw@localhost:7054 --caname ca-general -M ${PWD}/organizations/peerOrganizations/general.parttracer.com/users/User1@general.parttracer.com/msp --tls.certfiles ${PWD}/organizations/fabric-ca/general/tls-cert.pem
  set +x

  mkdir -p organizations/peerOrganizations/general.parttracer.com/users/Admin@general.parttracer.com

  echo
  echo "## Generate the org admin msp"
  echo
  set -x
	fabric-ca-client enroll -u https://Admin:Adminpw@localhost:7054 --caname ca-general -M ${PWD}/organizations/peerOrganizations/general.parttracer.com/users/Admin@general.parttracer.com/msp --tls.certfiles ${PWD}/organizations/fabric-ca/general/tls-cert.pem
  set +x

  cp ${PWD}/organizations/peerOrganizations/general.parttracer.com/msp/config.yaml ${PWD}/organizations/peerOrganizations/general.parttracer.com/users/Admin@general.parttracer.com/msp/config.yaml

}


function createAirbus {

  echo
	echo "Enroll the CA admin"
  echo
	mkdir -p organizations/peerOrganizations/airbus.parttracer.com/

	export FABRIC_CA_CLIENT_HOME=${PWD}/organizations/peerOrganizations/airbus.parttracer.com/
#  rm -rf $FABRIC_CA_CLIENT_HOME/fabric-ca-client-config.yaml
#  rm -rf $FABRIC_CA_CLIENT_HOME/msp

  set -x
  fabric-ca-client enroll -u https://airbusAdmin:airbusAdminpw@localhost:8054 --caname ca-airbus --tls.certfiles ${PWD}/organizations/fabric-ca/airbus/tls-cert.pem
  set +x

  echo 'NodeOUs:
  Enable: true
  ClientOUIdentifier:
    Certificate: cacerts/localhost-8054-ca-airbus.pem
    OrganizationalUnitIdentifier: client
  PeerOUIdentifier:
    Certificate: cacerts/localhost-8054-ca-airbus.pem
    OrganizationalUnitIdentifier: peer
  AdminOUIdentifier:
    Certificate: cacerts/localhost-8054-ca-airbus.pem
    OrganizationalUnitIdentifier: admin
  OrdererOUIdentifier:
    Certificate: cacerts/localhost-8054-ca-airbus.pem
    OrganizationalUnitIdentifier: orderer' > ${PWD}/organizations/peerOrganizations/airbus.parttracer.com/msp/config.yaml

  echo
	echo "Register peer0"
  echo
  set -x
	fabric-ca-client register --caname ca-airbus --id.name peer0 --id.secret peer0pw --id.type peer --tls.certfiles ${PWD}/organizations/fabric-ca/airbus/tls-cert.pem
  set +x

  echo
  echo "Register user"
  echo
  set -x
  fabric-ca-client register --caname ca-airbus --id.name User1 --id.secret User1pw --id.type client --tls.certfiles ${PWD}/organizations/fabric-ca/airbus/tls-cert.pem
  set +x

  echo
  echo "Register the org admin"
  echo
  set -x
  fabric-ca-client register --caname ca-airbus --id.name Admin --id.secret Adminpw --id.type admin --tls.certfiles ${PWD}/organizations/fabric-ca/airbus/tls-cert.pem
  set +x

	mkdir -p organizations/peerOrganizations/airbus.parttracer.com/peers
  mkdir -p organizations/peerOrganizations/airbus.parttracer.com/peers/peer0.airbus.parttracer.com

  echo
  echo "## Generate the peer0 msp"
  echo
  set -x
	fabric-ca-client enroll -u https://peer0:peer0pw@localhost:8054 --caname ca-airbus -M ${PWD}/organizations/peerOrganizations/airbus.parttracer.com/peers/peer0.airbus.parttracer.com/msp --csr.hosts peer0.airbus.parttracer.com --tls.certfiles ${PWD}/organizations/fabric-ca/airbus/tls-cert.pem
  set +x

  cp ${PWD}/organizations/peerOrganizations/airbus.parttracer.com/msp/config.yaml ${PWD}/organizations/peerOrganizations/airbus.parttracer.com/peers/peer0.airbus.parttracer.com/msp/config.yaml

  echo
  echo "## Generate the peer0-tls certificates"
  echo
  set -x
  fabric-ca-client enroll -u https://peer0:peer0pw@localhost:8054 --caname ca-airbus -M ${PWD}/organizations/peerOrganizations/airbus.parttracer.com/peers/peer0.airbus.parttracer.com/tls --enrollment.profile tls --csr.hosts peer0.airbus.parttracer.com --csr.hosts localhost --tls.certfiles ${PWD}/organizations/fabric-ca/airbus/tls-cert.pem
  set +x


  cp ${PWD}/organizations/peerOrganizations/airbus.parttracer.com/peers/peer0.airbus.parttracer.com/tls/tlscacerts/* ${PWD}/organizations/peerOrganizations/airbus.parttracer.com/peers/peer0.airbus.parttracer.com/tls/ca.crt
  cp ${PWD}/organizations/peerOrganizations/airbus.parttracer.com/peers/peer0.airbus.parttracer.com/tls/signcerts/* ${PWD}/organizations/peerOrganizations/airbus.parttracer.com/peers/peer0.airbus.parttracer.com/tls/server.crt
  cp ${PWD}/organizations/peerOrganizations/airbus.parttracer.com/peers/peer0.airbus.parttracer.com/tls/keystore/* ${PWD}/organizations/peerOrganizations/airbus.parttracer.com/peers/peer0.airbus.parttracer.com/tls/server.key

  mkdir ${PWD}/organizations/peerOrganizations/airbus.parttracer.com/msp/tlscacerts
  cp ${PWD}/organizations/peerOrganizations/airbus.parttracer.com/peers/peer0.airbus.parttracer.com/tls/tlscacerts/* ${PWD}/organizations/peerOrganizations/airbus.parttracer.com/msp/tlscacerts/ca.crt

  mkdir ${PWD}/organizations/peerOrganizations/airbus.parttracer.com/tlsca
  cp ${PWD}/organizations/peerOrganizations/airbus.parttracer.com/peers/peer0.airbus.parttracer.com/tls/tlscacerts/* ${PWD}/organizations/peerOrganizations/airbus.parttracer.com/tlsca/tlsca.airbus.parttracer.com-cert.pem

  mkdir ${PWD}/organizations/peerOrganizations/airbus.parttracer.com/ca
  cp ${PWD}/organizations/peerOrganizations/airbus.parttracer.com/peers/peer0.airbus.parttracer.com/msp/cacerts/* ${PWD}/organizations/peerOrganizations/airbus.parttracer.com/ca/ca.airbus.parttracer.com-cert.pem

  mkdir -p organizations/peerOrganizations/airbus.parttracer.com/users
  mkdir -p organizations/peerOrganizations/airbus.parttracer.com/users/User1@airbus.parttracer.com

  echo
  echo "## Generate the user msp"
  echo
  set -x
	fabric-ca-client enroll -u https://User1:User1pw@localhost:8054 --caname ca-airbus -M ${PWD}/organizations/peerOrganizations/airbus.parttracer.com/users/User1@airbus.parttracer.com/msp --tls.certfiles ${PWD}/organizations/fabric-ca/airbus/tls-cert.pem
  set +x

  mkdir -p organizations/peerOrganizations/airbus.parttracer.com/users/Admin@airbus.parttracer.com

  echo
  echo "## Generate the org admin msp"
  echo
  set -x
	fabric-ca-client enroll -u https://Admin:Adminpw@localhost:8054 --caname ca-airbus -M ${PWD}/organizations/peerOrganizations/airbus.parttracer.com/users/Admin@airbus.parttracer.com/msp --tls.certfiles ${PWD}/organizations/fabric-ca/airbus/tls-cert.pem
  set +x

  cp ${PWD}/organizations/peerOrganizations/airbus.parttracer.com/msp/config.yaml ${PWD}/organizations/peerOrganizations/airbus.parttracer.com/users/Admin@airbus.parttracer.com/msp/config.yaml

}

function createRegulator {

  echo
	echo "Enroll the CA admin"
  echo
	mkdir -p organizations/regulatorOrganizations/parttracer.com

	export FABRIC_CA_CLIENT_HOME=${PWD}/organizations/regulatorOrganizations/parttracer.com
#  rm -rf $FABRIC_CA_CLIENT_HOME/fabric-ca-client-config.yaml
#  rm -rf $FABRIC_CA_CLIENT_HOME/msp

  set -x
  fabric-ca-client enroll -u https://regulatorAdmin:regulatorAdminpw@localhost:9054 --caname ca-regulator --tls.certfiles ${PWD}/organizations/fabric-ca/regulatorOrg/tls-cert.pem
  set +x

  echo 'NodeOUs:
  Enable: true
  ClientOUIdentifier:
    Certificate: cacerts/localhost-9054-ca-regulator.pem
    OrganizationalUnitIdentifier: client
  PeerOUIdentifier:
    Certificate: cacerts/localhost-9054-ca-regulator.pem
    OrganizationalUnitIdentifier: peer
  AdminOUIdentifier:
    Certificate: cacerts/localhost-9054-ca-regulator.pem
    OrganizationalUnitIdentifier: admin
  OrdererOUIdentifier:
    Certificate: cacerts/localhost-9054-ca-regulator.pem
    OrganizationalUnitIdentifier: orderer' > ${PWD}/organizations/regulatorOrganizations/parttracer.com/msp/config.yaml


  echo
	echo "Register orderer"
  echo
  set -x
	fabric-ca-client register --caname ca-regulator --id.name orderer --id.secret ordererpw --id.type orderer --tls.certfiles ${PWD}/organizations/fabric-ca/regulatorOrg/tls-cert.pem
    set +x

  echo
  echo "Register the orderer admin"
  echo
  set -x
  fabric-ca-client register --caname ca-regulator --id.name ordererAdmin --id.secret ordererAdminpw --id.type admin --tls.certfiles ${PWD}/organizations/fabric-ca/regulatorOrg/tls-cert.pem
  set +x

	mkdir -p organizations/regulatorOrganizations/parttracer.com/orderers
  mkdir -p organizations/regulatorOrganizations/parttracer.com/orderers/parttracer.com

  mkdir -p organizations/regulatorOrganizations/parttracer.com/orderers/orderer.parttracer.com

  echo
  echo "## Generate the orderer msp"
  echo
  set -x
	fabric-ca-client enroll -u https://orderer:ordererpw@localhost:9054 --caname ca-regulator -M ${PWD}/organizations/regulatorOrganizations/parttracer.com/orderers/orderer.parttracer.com/msp --csr.hosts orderer.parttracer.com --csr.hosts localhost --tls.certfiles ${PWD}/organizations/fabric-ca/regulatorOrg/tls-cert.pem
  set +x

  cp ${PWD}/organizations/regulatorOrganizations/parttracer.com/msp/config.yaml ${PWD}/organizations/regulatorOrganizations/parttracer.com/orderers/orderer.parttracer.com/msp/config.yaml

  echo
  echo "## Generate the orderer-tls certificates"
  echo
  set -x
  fabric-ca-client enroll -u https://orderer:ordererpw@localhost:9054 --caname ca-regulator -M ${PWD}/organizations/regulatorOrganizations/parttracer.com/orderers/orderer.parttracer.com/tls --enrollment.profile tls --csr.hosts orderer.parttracer.com --csr.hosts localhost --tls.certfiles ${PWD}/organizations/fabric-ca/regulatorOrg/tls-cert.pem
  set +x

  cp ${PWD}/organizations/regulatorOrganizations/parttracer.com/orderers/orderer.parttracer.com/tls/tlscacerts/* ${PWD}/organizations/regulatorOrganizations/parttracer.com/orderers/orderer.parttracer.com/tls/ca.crt
  cp ${PWD}/organizations/regulatorOrganizations/parttracer.com/orderers/orderer.parttracer.com/tls/signcerts/* ${PWD}/organizations/regulatorOrganizations/parttracer.com/orderers/orderer.parttracer.com/tls/server.crt
  cp ${PWD}/organizations/regulatorOrganizations/parttracer.com/orderers/orderer.parttracer.com/tls/keystore/* ${PWD}/organizations/regulatorOrganizations/parttracer.com/orderers/orderer.parttracer.com/tls/server.key

  mkdir ${PWD}/organizations/regulatorOrganizations/parttracer.com/orderers/orderer.parttracer.com/msp/tlscacerts
  cp ${PWD}/organizations/regulatorOrganizations/parttracer.com/orderers/orderer.parttracer.com/tls/tlscacerts/* ${PWD}/organizations/regulatorOrganizations/parttracer.com/orderers/orderer.parttracer.com/msp/tlscacerts/tlsca.parttracer.com-cert.pem

  mkdir ${PWD}/organizations/regulatorOrganizations/parttracer.com/msp/tlscacerts
  cp ${PWD}/organizations/regulatorOrganizations/parttracer.com/orderers/orderer.parttracer.com/tls/tlscacerts/* ${PWD}/organizations/regulatorOrganizations/parttracer.com/msp/tlscacerts/tlsca.parttracer.com-cert.pem

  mkdir -p organizations/regulatorOrganizations/parttracer.com/users
  mkdir -p organizations/regulatorOrganizations/parttracer.com/users/Admin@parttracer.com

  echo
  echo "## Generate the admin msp"
  echo
  set -x
	fabric-ca-client enroll -u https://ordererAdmin:ordererAdminpw@localhost:9054 --caname ca-regulator -M ${PWD}/organizations/regulatorOrganizations/parttracer.com/users/Admin@parttracer.com/msp --tls.certfiles ${PWD}/organizations/fabric-ca/regulatorOrg/tls-cert.pem
  set +x

  cp ${PWD}/organizations/regulatorOrganizations/parttracer.com/msp/config.yaml ${PWD}/organizations/regulatorOrganizations/parttracer.com/users/Admin@parttracer.com/msp/config.yaml


}
