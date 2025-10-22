# Use Control-M Certificates

Root, Intermediate and Zone 1 scripts must be run EM user.

Start an em shell, like

```tcsh
em bash
```

or preface the script with em. For example,

```tcsh
em 01.crtCAcerts.sh
```

For background, please see

* [Best practices for moving from default TCP mode to SSL/TLS in zone 3 between Control-M/Server and Control-M/Agent](https://bmcapps.my.site.com/casemgmt/sc_KnowledgeArticle?sfdcid=000442271) and
* [Best practices for changing the SSL/TLS Certificate Authority in zone 3 between Control-M/Server and Control-M/Agent](https://bmcapps.my.site.com/casemgmt/sc_KnowledgeArticle?sfdcid=000442490)

Note that the solutions recommend to

1. > Make sure to use your organization's own Certificate Authority (CA), provided by your organization's security team, and not a third-party CA.
   > This CA should be dedicated to Control-M and not allow unauthorized issuance.
   > Each certificate issued for a Control-M product should contain a unique value in the emailAddress field (e.g. hostname_component@domain).
   >

The Root and Intermediate CA certficates that these scripts create may not be approved by your SecOps organizations, and thus is not a recommendation to use them.They should be used for educational and example purposes.

## Root and Intermediate certificates

### Create Root CA

Use script 01.crtCAcerts.sh to create a dedicated self-signed root certificate with "random passwords and passphrase

### Create Intermediate certificate

While an intermediate authority is not required, I preferred to do it to do it to demonstrate the procedure

Use script 02.crtIntCACerts.sh to complete the Intermediate certificate

### Download the certs to add to your clients

Download the new Control-M Zone 1 certificates (depending what you need) from:

#### Root Cert

~/sslctm/rootCA/certs/ctmrootCA.crt

#### Intermediate Cert

~/sslctm//intCA/certs/ctmintCA.crt

#### Certificate Chain

~/sslctm/intCA/certs/ctmchainCA.crt

Import these into your browser or client system to avoid certificate warnings, and use the AddCerts2Stores.ps1 script to add them to Windows CertStore or other cacerts if needed. Note that your browser may need to be restarted for it to read the new certs.

> ***NOTE: if you recreate the Root and Intermediate CA, you will need to restart procedures.***

## Zone 1

See the documentation for Zone 1 at [Zone 1 SSL Configuration](https://documents.bmc.com/supportu/9.0.22/en-US/Documentation/Zone_1_SSL_configuration.htm)

### Create private key and certificate for Zone 1

Use script 10.ctm_em_zone1.sh to create the private key and certificates for Zone 1

### Set up the tomcat certificate store

Use script 11.ctm_em_tomcat.sh to create and deploy the certificate store.

**NOTE: This procedure will shut down, reconfigure and restart the web server.**

## Zone 2 and 3

This is work in progress
