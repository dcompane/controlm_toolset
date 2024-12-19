#! /bin/bash


sudo systemctl -l --no-pager status kafka-zookeeper.service
sudo systemctl -l --no-pager status kafka.service

