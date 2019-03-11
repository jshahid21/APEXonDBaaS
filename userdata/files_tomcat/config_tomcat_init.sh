#!/bin/bash

# This script requires 2 arguments
# Arg1 : port for access to ORDS
# Arg2 : Object Storage URL for Tomcat 8.5 tar.gz file

# Set variables
ComPort=$1
URL_tomcat_file=$2

### Install and setup Tomcat
# Add User for Tomcat
useradd tomcat
mkdir /home/tomcat/.ssh
cp -f /home/opc/.ssh/authorized_keys /home/tomcat/.ssh/
chown -R tomcat. /home/tomcat/.ssh

# Environment Variable Setting
cat <<EOF >> /home/tomcat/.bash_profile
export LD_LIBRARY_PATH=/usr/lib/oracle/18.3/client64/lib:\$LD_LIBRARY_PATH
export PATH=/usr/lib/oracle/18.3/client64/bin:\$PATH
EOF

# Copy files to tomcat home directory
mv files_tomcat.zip /home/tomcat/
chown tomcat. /home/tomcat/files_tomcat.zip

# Download Tomcat
curl -v -X GET -o apache-tomcat.tar.gz ${URL_tomcat_file}

# Install Tomcat
tar -xf apache-tomcat.tar.gz
dir_tomcat=`ls -dl apache-tomcat*|grep -v tar|awk '{print $NF}'`
mv ${dir_tomcat} /opt/
chown -R tomcat. /opt/${dir_tomcat}

# Set profile for Tomcat
ln -s /opt/${dir_tomcat} /opt/tomcat
echo 'export CATALINA_HOME=/opt/tomcat'  >  /etc/profile.d/tomcat.sh
source /etc/profile.d/tomcat.sh

# Configure Service for Tomcat
cat <<EOF >> /etc/systemd/system/tomcat.service
[Unit]
Description=Apache Tomcat 8
After=syslog.target network.target

[Service]
User=tomcat
Group=tomcat
Type=oneshot
PIDFile=/opt/tomcat/tomcat.pid
RemainAfterExit=yes

ExecStart=/opt/tomcat/bin/startup.sh
ExecStop=/opt/tomcat/bin/shutdown.sh
ExecReStart=/opt/tomcat/bin/shutdown.sh;/opt/tomcat/bin/startup.sh

[Install]
WantedBy=multi-user.target
EOF

chmod 755 /etc/systemd/system/tomcat.service

# Create a keystore containing a self-signed cert
su - tomcat -c "keytool -genkey -keyalg RSA -alias self-signed -dname "CN=`hostname -f`" -validity 3650 -keysize 2048 -storepass changeit -keypass changeit"

# Configure a Connector with the port that user specified
row_server_xml=`grep -n "Service name=" /opt/tomcat/conf/server.xml | awk -F: '{print $1}'`
cp /opt/tomcat/conf/server.xml /opt/tomcat/conf/server.xml_orig
chown tomcat. /opt/tomcat/conf/server.xml_orig
sed -i -e "${row_server_xml}a \    <Connector port=\"${ComPort}\" maxThreads=\"200\" scheme=\"https\" secure=\"true\" SSLEnabled=\"true\"\n               clientAuth=\"false\" sslProtocol=\"TLS\" keystorePass=\"changeit\" />" /opt/tomcat/conf/server.xml

# Open the specific port/tcp for Tomcat
cat <<EOF >> /etc/firewalld/services/tomcat.xml
<?xml version="1.0" encoding="utf-8"?>
<service>
  <short>Tomcat (HTTPS)</short>
  <description>Open port for Apache Tomcat.</description>
  <port protocol="tcp" port="${ComPort}"/>
</service>
EOF

sleep 3

# Start Tomcat
systemctl enable tomcat
systemctl start tomcat
systemctl status tomcat

sleep 3

# firewall setting update and restart firewalld to open the specfic port
firewall-cmd --permanent --add-service tomcat
systemctl stop firewalld
systemctl start firewalld

