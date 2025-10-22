# Use Control-M Certificates

Root, Intermediate and Zone 1 scripts must be run EM user.

Start an em shell, 

```tcsh
em bash
```

or preface the script with em. For example,

```tcsh
em 01.crtCAcerts.sh
```

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

Import these into your browser or client system to avoid certificate warnings, and use the AddCerts2Stores.ps1 script to add them to Windows CertStore or other cacerts if needed.

## Zone 1

### Create private key and certificate for Zone 1

Use script 10.ctm_em_zone1.sh to create the private key and certificates for Zone 1

### Set up the tomcat certificate store

Use script 11.ctm_em_tomcat.sh to create and deploy the certificate store.

**NOTE: This procedure will shut down, reconfigure and restart the web server.**

## Zone 2 and 3

This is work in progress
