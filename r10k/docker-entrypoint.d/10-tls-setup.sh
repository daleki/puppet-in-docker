#!/usr/bin/env bash

CN=$(hostname)
CA_SERVER=${CA_SERVER:-puppetca.local}

if [ "${USE_LEGACY_CA_API}" == "true" ]; then
  CA_API_URL=https://${CA_SERVER}:8140/production/certificate/ca
  CRL_API_URL=https://${CA_SERVER}:8140/production/certificate_revocation_list/ca
else
  CA_API_URL=https://${CA_SERVER}:8140/puppet-ca/v1/certificate/ca
  CRL_API_URL=https://${CA_SERVER}:8140/puppet-ca/v1/certificate_revocation_list/ca
fi

# Request certificate if not already available
if [ ! -f /etc/puppetlabs/puppet/ssl/certs/${CN}.pem ]; then
  # Wait for CA API to be available
  while ! curl -k -s -f $CA_API_URL > /dev/null; do
    echo "---> Waiting for CA API at ${CA_SERVER}..."
    sleep 10
  done

  echo "---> Requesting certificate for ${CN} from ${CA_SERVER}"
   /opt/puppetlabs/puppet/bin/ruby \
    /usr/local/bin/request-cert.rb \
    --caserver ${CA_SERVER} \
    --cn ${CN} \
    --legacy ${USE_LEGACY_CA_API} \
    --ssldir /etc/puppetlabs/puppet/ssl

  if [ ! -f ${CERTFILE} ]; then
    echo "---> Certificate retrieval failed. Exiting"
    exit 1
  fi

fi
