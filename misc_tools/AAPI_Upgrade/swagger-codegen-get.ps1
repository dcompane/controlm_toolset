#! /usr/bin/pwsh
# See latest version at 
# https://repo1.maven.org/maven2/io/swagger/codegen/v3/swagger-codegen-cli/maven-metadata.xml

$latest = (Invoke-WebRequest "https://repo1.maven.org/maven2/io/swagger/codegen/v3/swagger-codegen-cli/maven-metadata.xml").Content
[xml]$xml = $latest
$version = $xml.metadata.versioning.latest

# Download current stable 3.x.x branch (OpenAPI version 3)
$url="https://repo1.maven.org/maven2/io/swagger/codegen/v3/swagger-codegen-cli/"+$version+"/swagger-codegen-cli-"+$version+".jar"
echo $url
Invoke-WebRequest -OutFile swagger-codegen-cli.jar $url

cls

java -jar swagger-codegen-cli.jar version
java -jar swagger-codegen-cli.jar --help
java -jar swagger-codegen-cli.jar langs
java -jar swagger-codegen-cli.jar config-help -l python
java -jar swagger-codegen-cli.jar config-help -l go