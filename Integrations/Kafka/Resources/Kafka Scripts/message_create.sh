#! /bin/bash

if [ x$1 == "x" ]; then
    topic="test"
else
    topic=$1
fi

~/kafka/bin/kafka-console-producer.sh --topic $topic --bootstrap-server localhost:9092

