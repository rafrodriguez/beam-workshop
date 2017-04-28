#!/bin/bash
#
# Copyright 2017 The Project Authors, see separate AUTHORS file
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# This is a dataproc initialization script for starting a Kafka cluster.

# All the nodes, including master run Kafka brokers (servers). Kafka requires
# Zookeeper server and it is started on the master.

set -x -e

if [[ "$(/usr/share/google/get_metadata_value attributes/dataproc-role)" == "Master" ]]; then
  is_master=true
else
  is_master=false
fi

# Variables for this script
SCALA_VERSION="2.10"
KAFKA_VERSION="0.10.2.0"
CLUSTER_NAME="$(hostname | sed 's/\(.*\)-[m|w][-]*[0-9]*$/\1/g')"
if $is_master; then
  BROKER_ID="0"
else
  BROKER_ID="$(($(hostname | sed 's/.*-w-\([0-9]\)*.*/\1/g') + 1))"
fi
DNS_NAME="$(dnsdomainname)"
KAFKA_PKG="kafka_${SCALA_VERSION}-${KAFKA_VERSION}"

# Download and extract Kafka
curl -s -S -o /tmp/${KAFKA_PKG}.tgz http://www.us.apache.org/dist/kafka/${KAFKA_VERSION}/${KAFKA_PKG}.tgz
tar zxf /tmp/${KAFKA_PKG}.tgz

# wait for a port on a host to be ready to accept connections
wait_for_port() {
  host=$1
  port=$2
  attempts=$3
  sleep_sec=$4
  timeout=1

  for attempt in $(seq "$attempts"); do
    if nc -w "$timeout" "$host" "$port" < /dev/null; then
      return 0
    fi
    sleep "$sleep_sec"
  done
  echo Failed to connect "$host" at port "$port" 1>&2
  return 1
}

EXTERNAL_IP="$(curl -s "http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/access-configs/0/external-ip" -H "Metadata-Flavor: Google")"

# A small script to return external ip
cat << EOF > ${KAFKA_PKG}/bin/external_ip.sh
#!/bin/sh
echo $EXTERNAL_IP
EOF
chmod +x ${KAFKA_PKG}/bin/external_ip.sh

# run zookeeper & pubsub command listener on the master
if $is_master; then
  nohup ${KAFKA_PKG}/bin/zookeeper-server-start.sh \
    ${KAFKA_PKG}/config/zookeeper.properties       \
    >> /var/log/zookeeper.log 2>&1 &
fi

# Wait for zookeeper port to be ready
wait_for_port "${CLUSTER_NAME}-m.${DNS_NAME}" 2181 36 5 # 3 minutes

# Kafka broker configuration
cat << EOF >> ${KAFKA_PKG}/config/server.properties
zookeeper.connect=${CLUSTER_NAME}-m.${DNS_NAME}:2181
broker.id=${BROKER_ID}
log.retention.hours=24
num.partitions=20
advertised.listeners=PLAINTEXT://${EXTERNAL_IP}:9092
delete.topic.enable=true
EOF

# Check Kafka server every 5 seconds and start it if it is not running.
# Once every few weeks Kafka server dies with 'Too many open files'.
cat << EOF > ${KAFKA_PKG}/bin/check_kafka_server.sh
#!/bin/sh
while true; do
  if fuser /tmp/kafka-logs/.lock > /dev/null 2>&1 ; then
    sleep 5 # check in 5 seconds.
  else
    echo \$(date): Kafka server is not found. Starting it.
    # Start Kafka
    nohup ${KAFKA_PKG}/bin/kafka-server-start.sh ${KAFKA_PKG}/config/server.properties >> /var/log/kafka.log 2>&1 &
    sleep 30
  fi
done
EOF

chmod +x ${KAFKA_PKG}/bin/check_kafka_server.sh
nohup ${KAFKA_PKG}/bin/check_kafka_server.sh >> /var/log/check_kafka_server.log 2>&1 &

# Wait up to 1 minute for kafka server to be ready
wait_for_port "${EXTERNAL_IP}" 9092 20 3
