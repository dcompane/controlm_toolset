# Set the Kafka consumer configuration
# conf = {'bootstrap.servers': 'dc01:9092,host2:9092',
#           'group.id': 'foo',

conf_admin = {'bootstrap.servers': 'dc01:9092,host2:9092'}

conf = {'bootstrap.servers': 'dc01:9092,host2:9092'}
conf['group.id'] = 'test'
conf['auto.offset.reset'] = 'smallest'