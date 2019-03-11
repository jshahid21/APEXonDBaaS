#!/bin/bash

echo "-------------------------------------------------------------------------"
echo " Setting up environment variables to launch a compute instance for ORDS."
echo " Please enter required information below: "
echo "-------------------------------------------------------------------------"
echo ""

cd `dirname $0`
stamp=`date +%Y%m%d_%H%M%S`

### Reading current setting variables
# checking env-vars file exists
if [ ! -e env-vars ]; then
  no_env-vars=true
  echo "INFO: env-vars file is not found in `pwd`."
  echo "      It will be newly created."
else
  grep = env-vars | grep -v '^#.*' | grep -v "cat " > .env-vars_1_${stamp}
  source .env-vars_1_${stamp}
fi

for i in PathToYourSshPublicKey PathToYourSshPrivateKey PathToYourApiPrivateKey
do
  if ! eval echo '$'${i} | grep / >/dev/null; then
    export ${i}=
  fi
done

echo "***** Authentication *****"
read -p "Enter your tenancy's OCID [${TF_VAR_tenancy_ocid}]: " TENANCYID
read -p "Enter your user's OCID [${TF_VAR_user_ocid}]: " USERID
read -p "Enter your fingerprint [${TF_VAR_fingerprint}]: " FINGERPRINT
read -p "Enter path to your SSH public key [${PathToYourSshPublicKey}]: " SSHPUBKEYPATH
read -p "Enter path to your SSH private key [${PathToYourSshPrivateKey}]: " SSHPRIVKEYPATH
read -p "Enter path to your API private key [${PathToYourApiPrivateKey}]: " APIPRIVKEYPATH
read -p "Enter your compartment's OCID [${TF_VAR_compartment_ocid}]: " CID 
echo ""

echo "***** Target Database *****"
read -p "Enter the database host's IP address [${TF_VAR_target_db_ip}]: " DBHOSTIP
read -p "Enter the database service name [${TF_VAR_target_db_srv_name}]: " DBSRVNAME
echo ""

echo "***** Compute Instance *****"
read -p "Enter the region <us-phoenix-1|us-ashburn-1|eu-frankfurt-1|uk-london-1|ca-toronto-1> [${TF_VAR_region}]: " REGION
read -p "Enter the AD <1|2|3> [${TF_VAR_AD}]: " AD
read -p "Enter the available Oracle Linux 7.X version <7.6|...> [${TF_VAR_InstanceOSVersion}]: " OLVER
read -p "Enter the subnet's OCID [${TF_VAR_subnet_ocid}]: " SUBNETID
read -p "Enter the Compute Instance's display name [${TF_VAR_ComputeDisplayName}]: " COMDISPNAME
read -p "Enter the Compute Instance's hostname [${TF_VAR_InstanceName}]: " COMHOSTNAME
read -p "Enter the Compute Instance's shape <VM.Standard2.1|VM.Standard2.2|...> [${TF_VAR_InstanceShape}]: " COMSHAPE
read -p "Enter the Compute Instance's port [${TF_VAR_com_port}]: " COMPORT
read -p "Enter 0 to run Jetty (ORDS standalone mode), or 1 to run Tomcat [${TF_VAR_web_srv}]: " WEBSRV
read -p "Enter 0 to access with FQDN (hostname.yourdomain), or 1 to access with public IP address [${TF_VAR_Secure_FQDN_access}]: " COMACCESS
if [ "${COMACCESS:-${TF_VAR_Secure_FQDN_access}}" = "0" ]; then
  read -p "Enter the domain name [${TF_VAR_ZoneName}]: " ZONENAME
fi
echo ""

echo "***** File location on Object Storage *****"
read -p "Enter the URL for ORDS.war file [${TF_VAR_URL_ORDS_file}]: " URLORDS
if [ "${WEBSRV:-${TF_VAR_web_srv}}" = "1" ]; then
  read -p "Enter the URL for Tomcat 8.5 tar.gz file [${TF_VAR_URL_tomcat_file}]: " URLTOMCAT
fi
read -p "Enter the URL for APEX zip file [${TF_VAR_URL_APEX_file}]: " URLAPEX

echo ""
echo "***** APEX installation mode *****"
read -p "Enter 0 to install APEX with Full development environment mode, or 1 to install APEX with Runtime environment mode [${TF_VAR_APEX_install_mode}]: " APEXINSTMODE

echo ""
echo "INFO: Updating values..."

### Update env-vars file with given parameters
if [ ! "$no_env-vars" = "true" ]; then
  cp env-vars .env-vars_2_${stamp}
  while read line
  do
    i=`echo "$line"|awk '{print $1}'`
    j=`echo "$line"|awk '{print $2}'`
    echo $i | grep -v '^#.*' > /dev/null
    if [ $? -eq 0 ];then
      if [ "$i" = "export" ]; then
        case "$j" in
          TF_VAR_tenancy_ocid* )        echo "export TF_VAR_tenancy_ocid=${TENANCYID:=${TF_VAR_tenancy_ocid}}"               >> .new_env-vars_${stamp};;
          TF_VAR_user_ocid* )           echo "export TF_VAR_user_ocid=${USERID:=${TF_VAR_user_ocid}}"                        >> .new_env-vars_${stamp};;
          TF_VAR_fingerprint* )         echo "export TF_VAR_fingerprint=${FINGERPRINT:=${TF_VAR_fingerprint}}"               >> .new_env-vars_${stamp};;
          TF_VAR_compartment_ocid* )    echo "export TF_VAR_compartment_ocid=${CID:=${TF_VAR_compartment_ocid}}"             >> .new_env-vars_${stamp};;
          TF_VAR_target_db_ip* )        echo "export TF_VAR_target_db_ip=${DBHOSTIP:=${TF_VAR_target_db_ip}}"                >> .new_env-vars_${stamp};;
          TF_VAR_target_db_srv_name* )  echo "export TF_VAR_target_db_srv_name=${DBSRVNAME:=${TF_VAR_target_db_srv_name}}"   >> .new_env-vars_${stamp};;
          TF_VAR_region* )              echo "export TF_VAR_region=${REGION:=${TF_VAR_region}}"                              >> .new_env-vars_${stamp};;
          TF_VAR_AD* )                  echo "export TF_VAR_AD=${AD:=${TF_VAR_AD}}"                                          >> .new_env-vars_${stamp};;
          TF_VAR_InstanceOSVersion* )   echo "export TF_VAR_InstanceOSVersion=${OLVER:=${TF_VAR_InstanceOSVersion}}"         >> .new_env-vars_${stamp};;
          TF_VAR_subnet_ocid* )         echo "export TF_VAR_subnet_ocid=${SUBNETID:=${TF_VAR_subnet_ocid}}"                  >> .new_env-vars_${stamp};;
          TF_VAR_ComputeDisplayName* )  echo "export TF_VAR_ComputeDisplayName=${COMDISPNAME:=${TF_VAR_ComputeDisplayName}}" >> .new_env-vars_${stamp};;
          TF_VAR_InstanceName* )        echo "export TF_VAR_InstanceName=${COMHOSTNAME:=${TF_VAR_InstanceName}}"             >> .new_env-vars_${stamp};;
          TF_VAR_InstanceShape* )       echo "export TF_VAR_InstanceShape=${COMSHAPE:=${TF_VAR_InstanceShape}}"              >> .new_env-vars_${stamp};;
          TF_VAR_com_port* )            echo "export TF_VAR_com_port=${COMPORT:=${TF_VAR_com_port}}"                         >> .new_env-vars_${stamp};;
          TF_VAR_web_srv* )             echo "export TF_VAR_web_srv=${WEBSRV:=${TF_VAR_web_srv}}"                            >> .new_env-vars_${stamp};;
          TF_VAR_Secure_FQDN_access* )  echo "export TF_VAR_Secure_FQDN_access=${COMACCESS:=${TF_VAR_Secure_FQDN_access}}"   >> .new_env-vars_${stamp};;
          TF_VAR_ZoneName* )            echo "export TF_VAR_ZoneName=${ZONENAME:=${TF_VAR_ZoneName}}"                        >> .new_env-vars_${stamp};;
          TF_VAR_URL_ORDS_file* )       echo "export TF_VAR_URL_ORDS_file=${URLORDS:=${TF_VAR_URL_ORDS_file}}"               >> .new_env-vars_${stamp};;
          TF_VAR_URL_tomcat_file* )     echo "export TF_VAR_URL_tomcat_file=${URLTOMCAT:=${TF_VAR_URL_tomcat_file}}"         >> .new_env-vars_${stamp};;
          TF_VAR_URL_APEX_file* )       echo "export TF_VAR_URL_APEX_file=${URLAPEX:=${TF_VAR_URL_APEX_file}}"               >> .new_env-vars_${stamp};;
          TF_VAR_APEX_install_mode* )   echo "export TF_VAR_APEX_install_mode=${APEXINSTMODE:=${TF_VAR_APEX_install_mode}}"  >> .new_env-vars_${stamp};;
          * )                           echo "$line"                                                                         >> .new_env-vars_${stamp}
        esac
      elif echo ${i} | grep '^PathToYour*' > /dev/null ; then
        case "$i" in
          PathToYourSshPublicKey* )     echo "PathToYourSshPublicKey=${SSHPUBKEYPATH:=${PathToYourSshPublicKey}}"            >> .new_env-vars_${stamp};;
          PathToYourSshPrivateKey* )    echo "PathToYourSshPrivateKey=${SSHPRIVKEYPATH:=${PathToYourSshPrivateKey}}"         >> .new_env-vars_${stamp};;
          PathToYourApiPrivateKey* )    echo "PathToYourApiPrivateKey=${APIPRIVKEYPATH:=${PathToYourApiPrivateKey}}"         >> .new_env-vars_${stamp};;
        esac
      fi
    else
      echo "$line" >> .new_env-vars_${stamp}
    fi
  done < env-vars
else
  echo "PathToYourSshPublicKey=${SSHPUBKEYPATH:=${PathToYourSshPublicKey}}"            >> env-vars
  echo "PathToYourSshPrivateKey=${SSHPRIVKEYPATH:=${PathToYourSshPrivateKey}}"         >> env-vars
  echo "PathToYourApiPrivateKey=${APIPRIVKEYPATH:=${PathToYourApiPrivateKey}}"         >> env-vars
  echo "export TF_VAR_tenancy_ocid=${TENANCYID:=${TF_VAR_tenancy_ocid}}"               >> env-vars
  echo "export TF_VAR_user_ocid=${USERID:=${TF_VAR_user_ocid}}"                        >> env-vars
  echo "export TF_VAR_fingerprint=${FINGERPRINT:=${TF_VAR_fingerprint}}"               >> env-vars
  echo "export TF_VAR_compartment_ocid=${CID:=${TF_VAR_compartment_ocid}}"             >> env-vars
  echo "export TF_VAR_target_db_ip=${DBHOSTIP:=${TF_VAR_target_db_ip}}"                >> env-vars
  echo "export TF_VAR_target_db_srv_name=${DBSRVNAME:=${TF_VAR_target_db_srv_name}}"   >> env-vars
  echo "export TF_VAR_region=${REGION:=${TF_VAR_region}}"                              >> env-vars
  echo "export TF_VAR_AD=${AD:=${TF_VAR_AD}}"                                          >> env-vars
  echo "export TF_VAR_InstanceOSVersion=${OLVER:=${TF_VAR_InstanceOSVersion}}"         >> env-vars
  echo "export TF_VAR_subnet_ocid=${SUBNETID:=${TF_VAR_subnet_ocid}}"                  >> env-vars
  echo "export TF_VAR_ComputeDisplayName=${COMDISPNAME:=${TF_VAR_ComputeDisplayName}}" >> env-vars
  echo "export TF_VAR_InstanceName=${COMHOSTNAME:=${TF_VAR_InstanceName}}"             >> env-vars
  echo "export TF_VAR_InstanceShape=${COMSHAPE:=${TF_VAR_InstanceShape}}"              >> env-vars
  echo "export TF_VAR_com_port=${COMPORT:=${TF_VAR_com_port}}"                         >> env-vars
  echo "export TF_VAR_web_srv=${WEBSRV:=${TF_VAR_web_srv}}"                            >> env-vars
  echo "export TF_VAR_Secure_FQDN_access=${COMACCESS:=${TF_VAR_Secure_FQDN_access}}"   >> env-vars
  echo "export TF_VAR_ZoneName=${ZONENAME:=${TF_VAR_ZoneName}}"                        >> env-vars
  echo "export TF_VAR_URL_ORDS_file=${URLORDS:=${TF_VAR_URL_ORDS_file}}"               >> env-vars
  echo "export TF_VAR_URL_tomcat_file=${URLTOMCAT:=${TF_VAR_URL_tomcat_file}}"         >> env-vars
  echo "export TF_VAR_URL_APEX_file=${URLAPEX:=${TF_VAR_URL_APEX_file}}"               >> env-vars
  echo "export TF_VAR_APEX_install_mode=${APEXINSTMODE:=${TF_VAR_APEX_install_mode}}"  >> env-vars
  echo "export TF_VAR_private_key_path=\${PathToYourApiPrivateKey}"                    >> env-vars
  echo "export TF_VAR_ssh_public_key=\$(cat \${PathToYourSshPublicKey} 2>/dev/null)"   >> env-vars
  echo "export TF_VAR_ssh_private_key=\$(cat \${PathToYourSshPrivateKey} 2>/dev/null)" >> env-vars
  echo "export TF_VAR_api_private_key=\$(cat \${PathToYourApiPrivateKey} 2>/dev/null)" >> env-vars
  echo "export TF_VAR_target_db_name=\`echo \$TF_VAR_target_db_srv_name|awk -F. '{print \$1}'\`" >> env-vars
fi

### Checking retrun code
if [ $? -eq 0 ];then
  # generating outputs-ORDS.tf
  if [ "${COMACCESS}" = "0" ] && [ "${APEXINSTMODE}" = "0" ]; then
      cat <<EOF > outputs-ORDS.tf

output "URL : APEX (FQDN)" {
  value = ["https://\${var.InstanceName}.\${element(concat(oci_dns_zone.ORDS-Zone.*.name, list("")), 0)}:\${var.com_port}/ords/\${var.target_db_name}/"]
}
EOF
  elif [ "${COMACCESS}" = "1" ] && [ "${APEXINSTMODE}" = "0" ]; then    
      cat <<EOF > outputs-ORDS.tf

output "URL : APEX (PublicIP)" {
  value = ["https://\${data.oci_core_vnic.InstanceVnic.public_ip_address}:\${var.com_port}/ords/\${var.target_db_name}/"]
}
EOF
  fi

  rm env-vars
  mv .new_env-vars_${stamp} env-vars
  rm .env-vars_*_${stamp}
  echo ""
  echo "INFO: env-vars is updated successfully."
  echo "      Pleaes set environment variables. (ex. source env-vars)"
else
  rm .new_env-vars_${stamp} .env-vars_*_${stamp}
  echo ""
  echo "INFO: Failed to update env-vars file, please retry after renaming env-vars. (ex. mv env-vars env-vars_back)"
fi

