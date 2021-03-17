import sys
import json

count = 1

data = {}
data['nodes'] = []

while count < len(sys.argv):
    data['nodes'].append({
        'ip_address': sys.argv[count],
        'hostname': ''
    })
    count += 1

with open('cluster_config.json', 'w') as f:
    json.dump(data, f, indent=4)

