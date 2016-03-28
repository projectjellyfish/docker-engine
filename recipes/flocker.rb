
dirname = '/opt/flocker'
directory dirname do
  mode '0755'
  action :create
end

directory dirname + '/flocker-' + node['flocker-version'] do
  mode '0755'
  action :create
end

case node['platform']
when 'debian', 'ubuntu'
  package %w(apt-transport-https software-properties-common)
  apt_repository 'clusterhq' do
    uri        "https://clusterhq-archive.s3.amazonaws.com/#{node['platform']}/\$(ARCH) /"
    components ['main']
  #  pin_priority '700'
    notifies :run, 'execute[apt-get update]', :immediately
  end

  execute 'apt-get update' do
    command 'apt-get update'
  end

  package 'clusterhq-flocker-cli' do
    action :install
    options '--force-yes'
  end

  package 'clusterhq-flocker-node' do
    action :install
    options '--force-yes'
  end

when 'redhat', 'centos', 'fedora'

  package %w(wget git gcc libffi-devel openssl openssl-devel python python-devel python-virtualenv libyaml)

  # grab repo
  remote_file "#{Chef::Config[:file_cache_path]}/clusterhq-release.el7.centos.noarch.rpm" do
    source "https://clusterhq-archive.s3.amazonaws.com/centos/clusterhq-release.el7.centos.noarch.rpm"
    mode '0755'
  end

  #install repo
  yum_package 'clusterhq-release.el7.centos.noarch.rpm' do
    source "#{Chef::Config[:file_cache_path]}/clusterhq-release.el7.centos.noarch.rpm"
  end

  # Adjust repo from Centos to RHEL vars:
  execute 'sed1' do
    command "sed -i 's/\$releasever/7/g' /etc/yum.repos.d/clusterhq.repo"
  end
  execute 'sed2' do
    command "sed -i 's/\$basearch/x86_64/g' /etc/yum.repos.d/clusterhq.repo"
  end

  #now install package
  yum_package 'clusterhq-flocker-node'
  yum_package 'clusterhq-flocker-docker-plugin'

  #
  venv_dir = "/opt/flocker/flocker-#{node['flocker-version']}/flocker-cli"

  python_virtualenv venv_dir do
      interpreter "python2.7"            # use system default python, not 2.6
      action :create
  end

  python_pip 'pip' do
    virtualenv venv_dir
    action :upgrade
  end

  remote_file "#{Chef::Config[:file_cache_path]}/Flocker-#{node['flocker-version']}-py2-none-any.whl" do
    source "https://clusterhq-archive.s3.amazonaws.com/python/Flocker-#{node['flocker-version']}-py2-none-any.whl"
    mode '0755'
  end

  python_pip "#{Chef::Config[:file_cache_path]}/Flocker-#{node['flocker-version']}-py2-none-any.whl" do
    virtualenv venv_dir
  end

# Ends RHEL
end

confdirname = '/etc/flocker'
directory confdirname do
  mode '0755'
  action :create
end

execute 'flocker-ca-init' do
  command "/opt/flocker/flocker-#{node['flocker-version']}/flocker-cli/bin/flocker-ca initialize #{node['flocker-clustername']}"
  cwd confdirname
  creates confdirname+"/cluster.crt"
end

execute 'flocker ccc' do
  command "/opt/flocker/flocker-#{node['flocker-version']}/flocker-cli/bin/flocker-ca create-control-certificate #{node['hostname']}"
  cwd confdirname
  creates confdirname+"/control-#{node['flocker-clustername']}.crt"
end

execute 'flocker api' do
  command "/opt/flocker/flocker-#{node['flocker-version']}/flocker-cli/bin/flocker-ca create-api-certificate plugin"
  cwd confdirname
  creates confdirname+"/plugin.crt"
end

# wrap content in lazy because file is created after compile
file confdirname+"/control-service.crt" do
  owner 'root'
  group 'root'
  mode 0755
  lazy { content ::File.open(confdirname+"/#{node['hostname']}.crt").read }
  action :create
end

file confdirname+"/control-service.key" do
  owner 'root'
  group 'root'
  mode 0600
  lazy { content ::File.open(confdirname+"/#{node['hostname']}.key").read }
  action :create
end

# Make keys for N number of Nodes
node['flocker-nodes'].times do |i|

  #create nodeN cert.
  execute 'flocker node' do
    command "/opt/flocker/flocker-#{node['flocker-version']}/flocker-cli/bin/flocker-ca create-node-certificate"
    cwd confdirname
  end

  execute 'crt copy' do
    command "ls -1 . | egrep '[A-Za-z0-9]*?-[A-Za-z0-9]*?-[A-Za-z0-9]*?-[A-Za-z0-9]*?-[A-Za-z0-9]*?.crt' | xargs -I {} cp {} #{confdirname}/node#{i}.crt"
    cwd confdirname
  end

  execute 'key copy' do
    command "ls -1 . | egrep '[A-Za-z0-9]*?-[A-Za-z0-9]*?-[A-Za-z0-9]*?-[A-Za-z0-9]*?-[A-Za-z0-9]*?.key' | xargs -I {} cp {} #{confdirname}/node#{i}.key"
    cwd confdirname
  end

  execute 'crt rm' do
    command "ls -1 . | egrep '[A-Za-z0-9]*?-[A-Za-z0-9]*?-[A-Za-z0-9]*?-[A-Za-z0-9]*?-[A-Za-z0-9]*?.crt' | xargs rm"
    cwd confdirname
  end

  execute 'key rm' do
    command "ls -1 . | egrep '[A-Za-z0-9]*?-[A-Za-z0-9]*?-[A-Za-z0-9]*?-[A-Za-z0-9]*?-[A-Za-z0-9]*?.key' | xargs rm"
    cwd confdirname
  end

end

toolsvenv_dir = "/opt/flocker/flocker-#{node['flocker-version']}/flocker-tools"

python_virtualenv toolsvenv_dir do
    interpreter "python2.7"            # use system default python, not 2.6
    action :create
end

python_pip 'pip' do
  virtualenv toolsvenv_dir
  action :upgrade
end

python_pip 'twisted' do
  virtualenv toolsvenv_dir
  version '15.3.0'
  action :install
end

python_pip 'treq' do
  virtualenv toolsvenv_dir
  version '15.0.0'
  action :install
end

python_pip 'git+https://github.com/ClusterHQ/unofficial-flocker-tools.git' do
  virtualenv toolsvenv_dir
  action :install
end

template confdirname+'/agent.yml' do
  source 'agent.yml.erb'
  mode '0755'
  owner 'root'
  group 'root'
end

#systemctl enable flocker-control
service 'flocker-control' do
  action [ :enable, :start ]
end

#systemctl enable flocker-dataset-agent
service 'flocker-dataset-agent' do
  action [ :enable, :start ]
end

#systemctl enable flocker-container-agent
service 'flocker-container-agent' do
  action [ :enable, :start ]
end

#systemctl enable flocker-container-agent
service 'flocker-docker-plugin' do
  action [ :enable, :start ]
end
