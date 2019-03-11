#!/bin/bash

# This script requires 2 arguments
# Arg1 : Compute FQDN (with customer's public domain)
# Arg2 : port for access to ORDS

### Configure ORDS for the target database
# Set Variables 
ComFQDN=$1
ComPort=$2

### Setup Tomcat with using CA certifiate 
# Clean up self-signed Cert
rm -rf ~/.keystore

# Export certificates into a single file in PKCS12 format
openssl pkcs12 -export -name letsencrypt -in ~/.acme.sh/${ComFQDN}/fullchain.cer -inkey ~/.acme.sh/${ComFQDN}/${ComFQDN}.key -out ~/.acme.sh/${ComFQDN}/cert_key.p12 -password pass:changeit

# Create Java Key Store
keytool -importkeystore -deststorepass changeit -destkeypass changeit -destkeystore /opt/tomcat/conf/keystore.jks -srckeystore ~/.acme.sh/${ComFQDN}/cert_key.p12 -srcstoretype PKCS12 -srcstorepass changeit -alias letsencrypt

# Configure a Connector with the port that user specified and keystore
rm /opt/tomcat/conf/server.xml
cp /opt/tomcat/conf/server.xml_orig /opt/tomcat/conf/server.xml
row_server_xml=`grep -n "Service name=" /opt/tomcat/conf/server.xml | awk -F: '{print $1}'`
sed -i -e "${row_server_xml}a \    <Connector port=\"${ComPort}\" maxThreads=\"200\" scheme=\"https\" secure=\"true\" SSLEnabled=\"true\"\n               keystoreFile=\"/opt/tomcat/conf/keystore.jks\" keyAlias=\"letsencrypt\"\n               clientAuth=\"false\" sslProtocol=\"TLS\" />" /opt/tomcat/conf/server.xml

# Update URL for *_add_db.sh
for i in apex_add_db.sh
do 
  IP=`grep https $HOME/${i}|awk -F: '{print $2}'|sed -e 's|//||'`
  sed -i -e "s/${IP}/${ComFQDN}/g" $HOME/${i}
done

# Cleanup 
history -c
