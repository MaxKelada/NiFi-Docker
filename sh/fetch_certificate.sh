#!/usr/bin/env bash
if ! ( [ -z ${CA_SERVER} ] || [ -z ${CA_TOKEN} ] ); then
    KEYSTORE_PATH=${KEYSTORE_PATH:=${NIFI_HOME}/conf/keystore.jks}
    TRUSTSTORE_PATH=${TRUSTSTORE_PATH:=${NIFI_HOME}/conf/truststore.jks}
    cert_path="${NIFI_HOME}/conf/nifi-cert.pem"
    config_json_path="${NIFI_HOME}/conf/config.json"

    # If these files already exist, then there is no need to request for a new certificate
    if ! ( [ -f ${KEYSTORE_PATH} ] && [ -f ${TRUSTSTORE_PATH} ] && [ -f ${cert_path} ] && [ -f ${config_json_path} ] ); then
        subject_alternative_names="$(hostname -f),${HOSTNAME}"
        certificate_owner="${NODE_IDENTITY:-"CN="${HOSTNAME}", OU=NIFI"}"


        # uncomment this line to export NODE_IDENTITY, this is here
        # to support a situation where the NIFI-6849 jira ticket is resolved
        # for more details look in the README.md
        #export NODE_IDENTITY=${certificate_owner}


        # Generate certificate
        echo "Generating Certificate from CA ${CA_SERVER} for ${certificate_owner}"
        ${NIFI_TOOLKIT_HOME}/bin/tls-toolkit.sh client -D "${certificate_owner}" --certificateAuthorityHostname "${CA_SERVER}" --token "${CA_TOKEN}" --PORT "${CA_PORT:-8443}" --subjectAlternativeNames "${subject_alternative_names}"

        # Move all files generated to their correct location
        mv ./keystore.jks ${KEYSTORE_PATH}
        mv ./truststore.jks ${TRUSTSTORE_PATH}
        mv ./nifi-cert.pem ${cert_path}
        mv ./config.json ${config_json_path}

        # Set security values from config.json
        export KEYSTORE_PATH
        export TRUSTSTORE_PATH
        export KEYSTORE_PASSWORD=$(cat ${config_json_path} | jq -r '.keyStorePassword')
        export TRUSTSTORE_PASSWORD=$(cat ${config_json_path} | jq -r '.trustStorePassword')
        export KEY_PASSWORD=$(cat ${config_json_path} | jq -r '.keyPassword')
        export KEYSTORE_TYPE=$(cat ${config_json_path} | jq -r '.keyStoreType')
        export TRUSTSTORE_TYPE=$(cat ${config_json_path} | jq -r '.trustStoreType')
    fi
fi