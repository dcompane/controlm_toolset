#! /bin/bash

if [ x$1 == "x" ]; then
    echo Error: Topic is missing
    exit 1
else
    echo Exiting after 15 seconds if no messages
    ~/kafka/bin/kafka-console-consumer.sh --topic $1 --from-beginning --bootstrap-server localhost:9092 --timeout-ms 15000
fi

