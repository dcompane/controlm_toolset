# This script must be run as an Administrator

# Define variables for the old and new certificates

param ( $CertType = "Root", 
        $CertCN = "DCO Root CA", 
        $certStoreLoc = "CurrentUser", 
        $CertPath = (New-Object -ComObject Shell.Application).NameSpace('shell:Downloads').Self.Path ,
        $CertFileExt = "crt",
        $testRun = $true)


# Usage 
# For root cert when the certs are CurrentUser and in the Downloads folder of the current user
#       .\AddCerts2Stores.ps1 -CertType Root -CertCN "DCO Root CA" 
# For Intermediate cert when the certs are CurrentUser and in the Downloads folder of the current user
#       .\AddCerts2Stores.ps1 -CertType CA -CertCN "DCO Intermediate CA"
# This will run without actions by default. If want to perform the actions, set $testRun to $false
#       .\AddCerts2Stores.ps1 -testRun $false

###  R E A D   T H I S  ###
###  R E A D   T H I S  ###
###  R E A D   T H I S  ###
# No validations for entries. be precise with the CN. It will remove all that finds.
# TEST WITH 
#            Get-ChildItem -Path $certStore | Where-Object {$_.Subject -like "$CertSubject"}

$newCertPath = "$CertPath\$CertCN.$CertFileExt"

# #If want to verify that user is Administrator
# $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
# if(-Not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
#     write-host Being executed by an administrator.
#     If Admin role is available for user, it could be LocalMachine 
#     $certStoreLoc = "Cert:\LocalMachine"
# }


$CertSubject = "*CN=$CertCN*"
Write-Host "Using CertSubject: $CertSubject" -ForegroundColor Green
$certStore = "Cert:\$certStoreLoc\$CertType"
Write-Host "Using CertStore: $CertStore" -ForegroundColor Green
$newCertPath = "$CertPath\$CertCN.crt"
Write-Host "Using NewCertPath: $newCertPath" -ForegroundColor Green

# Step 1: Find and remove the old certificate
Write-Host "Searching for old certificate with criteria: $CertSubject" -ForegroundColor Green
$oldCert = Get-ChildItem -Path $certStore | Where-Object {$_.Subject -like "$CertSubject"} 
try {
	if ($oldCert) {
		Write-Host "Backing up old certificate. Removing it..." -ForegroundColor Yellow
		Export-Certificate -Cert $oldCert -FilePath "$newCertPath.backup"
		Write-Host "Certificate data to be deleted follows" -ForegroundColor Yellow
		Write-Host "$oldCert" -ForegroundColor Yellow
		if (-Not $testRun) {
			Write-Host "Found old certificate. Removing it..." -ForegroundColor Yellow
			Remove-Item -Path $certStore\$oldCert.Thumbprint -Force
			Write-Host "Old certificate removed successfully." -ForegroundColor Yellow
		} else {   
			Write-Host "Test run enabled. Old certificate NOT removed." -ForegroundColor Red
		}
	} else {
		Write-Host "Could not find old certificate. Proceeding with import." -ForegroundColor Cyan
	}

	# Step 2: Import the new certificate
	Write-Host "Importing new certificate from: $newCertPath" -ForegroundColor Green
	if (-Not $testRun) {
		Import-Certificate -FilePath $newCertPath -CertStoreLocation $certStore
		Write-Host "New certificate added successfully." -ForegroundColor Yellow
	} else {   
		Write-Host "Test run enabled. New certificate NOT added." -ForegroundColor Red
	}


	Write-Host "Certificate replacement complete." -ForegroundColor Green
} catch {
	Write-Error "Error removing certificate: $($_.Exception.Message)"
}