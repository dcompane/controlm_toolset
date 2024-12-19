#! /bin/bash

if [ x$1 == "x" ]; then
    topic="test"
else
    topic=$1
fi

~/kafka/bin/kafka-topics.sh --create --topic $topic --bootstrap-server localhost:9092 --partitions 1 --replication-factor 1
