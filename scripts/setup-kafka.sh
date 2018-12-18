#!/bin/bash
set -e
#
# Script to setup a Kafka server

# unload the command line
broker_id=$1
az=$2

# update java
yum remove -y java-1.7.0-openjdk
yum install -y java-1.8.0

# add directories that support kafka
mkdir -p /opt

# download kafka
base_name=kafka_${scala_version}-${version}
cd /tmp
curl -O ${repo}/${version}/$base_name.tgz

# unpack the tarball
cd /opt
tar xzf /tmp/$base_name.tgz
rm /tmp/$base_name.tgz
cd $base_name

# TODO: update to min(3,)
# offsets.topic.replication.factor=1
# transaction.state.log.replication.factor=1
# transaction.state.log.min.isr=1

# configure the server
cat config/server.properties \
    | sed "s|broker.id=0|broker.id=$broker_id|" \
    | sed 's|log.dirs=/tmp/kafka-logs|log.dirs=${mount_point}/kafka-logs|' \
    | sed 's|num.partitions=1|num.partitions=${num_partitions}|' \
    | sed 's|log.retention.hours=168|log.retention.hours=${log_retention}|' \
    | sed 's|zookeeper.connect=localhost:2181|zookeeper.connect=${zookeeper_connect}|' \
    > /tmp/server.properties
echo >> /tmp/server.properties
echo "# rack ID" >> /tmp/server.properties
echo "broker.rack=$az" >> /tmp/server.properties
echo " " >> /tmp/server.properties
echo "# replication factor" >> /tmp/server.properties
echo "default.replication.factor=${repl_factor}" >> /tmp/server.properties
mv /tmp/server.properties config/server.properties

echo "PS1='[\u@kafka-${broker_id}-${az} \W]\$ '" >> /etc/bashrc

amazon-linux-extras install -y docker
service docker start
usermod -a -G docker ec2-user
docker run -d --name aws-es-proxy --restart unless-stopped --network host abutaha/aws-es-proxy -endpoint "${aws_es_endpoint}" -listen 0.0.0.0:9200

curl -L -O https://artifacts.elastic.co/downloads/beats/filebeat/filebeat-6.5.3-x86_64.rpm
rpm -vi filebeat-6.5.3-x86_64.rpm && rm -f filebeat-6.5.3-x86_64.rpm
filebeat modules enable kafka
chkconfig filebeat on
service filebeat start