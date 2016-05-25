#!/bin/bash

consul_delete_kv()
{
    consul_host=$1
    kv_path=$2
    python <<-EOF
import consul
c = consul.Consul(host="$consul_host")
c.kv.delete("$kv_path", recurse=True)
EOF
}

consul_delete_services()
{
    consul_host=$1
    service_name=$2
    kv_path=$2
    python <<-EOF
import consul
c = consul.Consul(host="172.20.20.10")
for node in  c.catalog.nodes()[1]:
    local = consul.Consul(host=node['Address'])
    services = local.health.service("$service_name")[1]
    for service in services:
        local.agent.service.deregister(service['Service']['ID'])
EOF
}

consul_get_docker_hosts()
{
    consul_host=$1
    python <<-EOF
import consul
c = consul.Consul(host="$consul_host")

health =  c.health.service("docker", passing=True)[1]

result = []
for entry in health:
    addr = entry['Service']['Address'] or entry['Node']['Address']
    port = entry['Service']['Port']

    result.append(addr+':'+str(port))

print "\n".join(result)
EOF
}
