# Set the Kafka consumer configuration
# conf = {'bootstrap.servers': 'dc01:9092,host2:9092',
#           'group.id': 'foo',
conf = {'bootstrap.servers': 'dc01:9092',
        'group.id': 'test',
        'auto.offset.reset': 'smallest'
        }

ctmcli = { 
        "ctmhost": "dc01",
        "ctmport": "8443",
        "ctmtoken": "b25QcmVtOmJlNzA5MzExLTcxZmEtNDIzZi1iZTJjLTE4ZTdhZjg4YzhjMg==",
        "ctmssl": True,
        "ctm_verify_ssl": False
        }
