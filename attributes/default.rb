# What docker engine version to use?
# @todo: how to upgrade -- check the version and do an only_if
# Also, need to upgrade the master(s) first
# docker --version <- need to do some grepping
default['docker_engine_arch'] = '-1.el7.centos'
default['docker_engine_version'] = '1.10.3'

default['flocker-version'] = '1.10.2'
default['flocker-clustername'] = 'mycluster'
default['flocker-nodes'] = 2

# What docker UCP version to use?
# @todo: how to upgrade? -- check the version and do an only_if
default['docker_ucp_version'] = '1.0.0'

# What version of Jenkins should we pull?
default['docker_jenkins_version'] = 'latest'

# What version of Jenkins should we pull?
default['docker_elk_version'] = 'es220_l220_k440'

# What version of Jenkins should we pull?
default['docker_zabbix_version'] = 'latest'

default['dockerhost']['docker_hub_user'] = ''
default['dockerhost']['docker_hub_pass'] = ""
default['dockerhost']['docker_hub_email'] = ''

# Dockerhost
# This can be overridden by the docker-swarm-master and docker-swarm-slave Roles:
default['dockerhost']['master_ip'] = '10.0.0.1'
