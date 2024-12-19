#! /bin/bash

sudo systemctl start kafka-zookeeper.service
sudo systemctl start kafka.service


sudo systemctl -l --plain status kafka-zookeeper.service
sudo systemctl -l --plain status kafka.service

