# Set the Kafka consumer configuration
# conf = {'bootstrap.servers': 'dc01:9092,host2:9092',
#           'group.id': 'foo',
conf = {'bootstrap.servers': 'dc01:9092',
        'group.id': 'test',
        'auto.offset.reset': 'smallest'
        }
