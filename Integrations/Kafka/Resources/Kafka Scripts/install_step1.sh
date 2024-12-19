Documentation=https://hostnextra.com/learn/tutorials/installing-apache-kafka-on-almalinux

#check the version to download
version=3.9

wget https://dlcdn.apache.org/kafka/3.8.0/kafka_2.13-${version}3.9.0.tgz
tar -zxvf kafka_2.13-${version}.0.tgza
rm kafka
ln -s kafka_2.13-${version}.0.tgz kafka  
