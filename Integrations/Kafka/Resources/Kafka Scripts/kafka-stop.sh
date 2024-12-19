#! /bin/bash

sudo systemctl stop kafka-zookeeper.service
sudo systemctl stop kafka.service


sudo systemctl status kafka-zookeeper.service
sudo systemctl status kafka.service

