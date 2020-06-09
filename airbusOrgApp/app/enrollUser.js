const FabricCAServices = require('fabric-ca-client');
const { FileSystemWallet } = require('fabric-network');
const yaml = require('js-yaml');
const fs = require('fs');
const path = require('path');

async function enrollUser(userName, userPwd, userOrg ) {
    try {
        // load the network configuration
        console.log(`Orgname: ${userOrg}`);
        
        let orgDomain = `${userOrg}.parttracer.com`;
        let connectionFile = `connection-${userOrg}.yaml`;

        console.log(`orgDomain: ${orgDomain}`);
        console.log(`connectionFile: ${connectionFile}`);
        
        let connectionProfilePath = path.join(__dirname ,'../../organizations/peerOrganizations',orgDomain,connectionFile);  
        console.log(`connectionProfilePath: ${connectionProfilePath}`);
        let connectionProfile = yaml.safeLoad(fs.readFileSync(connectionProfilePath, 'utf8'));
        console.log(`connectionProfile: ${connectionProfile}`);

        let caName = `ca.${orgDomain}`;

        // Create a new CA client for interacting with the CA.
        const caInfo = connectionProfile.certificateAuthorities[caName];
        console.log(`caInfo: ${caInfo}`);
        const caTLSCACerts = caInfo.tlsCACerts.pem;
        // let connectionOps = { protocol: "HTTPS",}
        const ca = new FabricCAServices(caInfo.url, { trustedRoots: caTLSCACerts, verify: false }, caInfo.caName);

        // Create a new file system based wallet for managing identities.
        const walletPath = path.join(__dirname, `../identity/user/${userName}/wallet`);
        console.log(`walletPath: ${walletPath}`);
        const wallet = new FileSystemWallet(walletPath);

        // Check to see if we've already enrolled the admin user.
        const userExists = await wallet.exists(userName);
        if (userExists) {
            console.log(`An identity for the client user ${userName} already exists in the wallet`);
            response = { success: false, message: `An identity for the client user ${userName} already exists in the wallet`};
            return response;
        }

        // Enroll the admin user, and import the new identity into the wallet.
        const enrollment = await ca.enroll({ enrollmentID: userName, enrollmentSecret: userPwd });
        const x509Identity = {
            certificate: enrollment.certificate,
            privateKey: enrollment.key.toBytes(),
            mspId: connectionProfile.organizations.Airbus.mspid,
            type: 'X.509',
        };
        await wallet.import(userName, x509Identity);
        console.log(`Successfully enrolled client user ${userName} and imported it into the wallet`);

        response = {success: true, message: `Successfully enrolled client user ${userName} and imported it into the wallet` };

    } catch (error) {
        response = { success: false, message: error.message};

        console.error(`Failed to enroll client user "${userName}": ${error}`);
    }

    return response;
}

// enrollUser(process.argv[2],'user1pw','airbus');

module.exports = enrollUser;