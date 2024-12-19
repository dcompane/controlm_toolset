#! /bin/bash

if [ x$1 == "x" ]; then
    ~/kafka/bin/kafka-topics.sh --list --bootstrap-server localhost:9092 
else
    ~/kafka/bin/kafka-topics.sh --list --bootstrap-server localhost:9092 | grep $1
fi

