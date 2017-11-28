#!/bin/bash
#TODO(pabloem) Document with comments here.
if [ "$1" = "-h" ]
then
  cat << EOF
  usage: setup.sh [-all|-h]
      flags:
          -all - Set up ALL the environment variables, instead of just the basic ones.
          -h   - Show this help.
EOF
  return 1;
fi

CHANGE_ALL_VALUES=false
if [ "$1" = "-all" ]
then
  CHANGE_ALL_VALUES=true
fi

##################
# DEFAULT VALUES FOR ENV VARIABLES
##################
_DEFAULT_GCP_PROJECT=beam-workshop-pabloem

_DEFAULT_PUBSUB_TOPIC=user-scores-topic
_DEFAULT_KAFKA_IP=127.0.0.1
_DEFAULT_GCP_INPUT_FILE=gs://apache-beam-demo/data/gaming*
_DEFAULT_GCP_OUTPUT_FILE=gs://$_DEFAULT_GCP_PROJECT/data/gaming*

function readOrDefault {
  REQUESTED_VALUE_NAME=$1
  DEFAULT_VALUE=$2
  ACCEPT_USER_INPUT=$3
  if [ "$ACCEPT_USER_INPUT" = "true" ]
  then
    read -p "Enter ${REQUESTED_VALUE_NAME} [${DEFAULT_VALUE}]: " USER_VALUE
    >&2 echo "Set to ${USER_VALUE:=$DEFAULT_VALUE}"
    >&2 echo ""
  fi
  echo ${USER_VALUE:=$DEFAULT_VALUE}
}

# Setting main environment variables
GCP_PROJECT=`readOrDefault "GCP Project ID" $_DEFAULT_GCP_PROJECT true`
GCP_OUTPUT_FILE=`readOrDefault "Output Prefix" $_DEFAULT_GCP_OUTPUT_FILE true`

GCP_INPUT_FILE=`readOrDefault "Input File" $_DEFAULT_GCP_INPUT_FILE $CHANGE_ALL_VALUES`
PUBSUB_TOPIC=`readOrDefault "PubSub Topic" $_DEFAULT_PUBSUB_TOPIC $CHANGE_ALL_VALUES`
KAFKA_IP_ADDRESS=`readOrDefault "PubSub Topic" $_DEFAULT_KAFKA_IP $CHANGE_ALL_VALUES`

# TODO(pabloem) Document this further.
read -p "Install GCP SDK? [y/n]" _INSTALL_GCP
if [ "$_INSTALL_GCP" = "y" ]
then
  pushd `mktemp -d`
  curl https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-sdk-180.0.1-linux-x86_64.tar.gz -o gcp-sdk.tar.gz
  tar xvf gcp-sdk.tar.gz > /dev/null
  rm gcp-sdk.tar.gz
  _GCP_SDK_TEMPDIR=$PWD
  PATH=$PATH:$PWD/google-cloud-sdk/bin

  function removeGCPSDK() {
    rm -rf $_GCP_SDK_TEMPDIR
  }
  echo "To remove the GCP SDK, run removeGCPSDK"
  popd
fi

