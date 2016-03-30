
dirname = '/opt/flocker'
directory dirname do
  mode '0755'
  action :create
end

directory dirname + '/flocker-' + node['flocker-version'] do
  mode '0755'
  action :create
end


flockeropt = '/opt/flocker/'

case node['platform']
when 'debian', 'ubuntu'
  package %w(apt-transport-https software-properties-common)
  #apt_repository 'clusterhq' do
  #  uri        'https://clusterhq-archive.s3.amazonaws.com/ubuntu/14.04/$(ARCH) /'
    #components ['main']
  #  pin_priority '700'
  #  notifies :run, 'execute[apt-get update]', :immediately
  #end

  execute 'add-apt' do
    command "add-apt-repository -y \"deb https://clusterhq-archive.s3.amazonaws.com/ubuntu/$(lsb_release --release --short)/\\$(ARCH) /\""
    not_if "cat /etc/apt/sources.list | grep -e \"clusterhq-archive\""
    notifies :run, 'execute[apt-get update]', :immediately
  end

  execute 'apt-get update' do
    command 'apt-get update'
    action :nothing
  end

  package 'clusterhq-flocker-cli' do
    action :install
    options '--force-yes'
  end

  package 'clusterhq-flocker-node' do
    action :install
    options '--force-yes'
  end

  package 'clusterhq-flocker-docker-plugin' do
    action :install
    options '--force-yes'
  end

  flockeropt = '/opt/flocker/bin'


when 'redhat', 'centos', 'fedora'
  flockeropt = "/opt/flocker/flocker-#{node['flocker-version']}/flocker-cli/bin/"

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
    only_if node['platform'] == 'redhat'
  end
  execute 'sed2' do
    command "sed -i 's/\$basearch/x86_64/g' /etc/yum.repos.d/clusterhq.repo"
    only_if node['platform'] == 'redhat'
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
# Ends RHEL
end

confdirname = '/etc/flocker'
directory confdirname do
  mode '0755'
  action :create
end

execute 'flocker-ca-init' do
  command "#{flockeropt}/flocker-ca initialize #{node['flocker-clustername']}"
  cwd confdirname
  creates confdirname+"/cluster.crt"
end

execute 'flocker ccc' do
  command "#{flockeropt}/flocker-ca create-control-certificate #{node['hostname']}"
  cwd confdirname
  creates confdirname+"/control-#{node['hostname']}.crt"
end

execute 'flocker api' do
  command "#{flockeropt}/flocker-ca create-api-certificate plugin"
  cwd confdirname
  creates confdirname+"/plugin.crt"
end

execute 'bash-copy-crt' do
  command "mv control-#{node['hostname']}.crt control-service.crt"
  cwd confdirname
  only_if { File.exist?(confdirname+"/control-#{node['hostname']}.crt") }
  creates confdirname+"/control-service.crt"
end

execute 'bash-copy-crt' do
  command "mv control-#{node['hostname']}.key control-service.key"
  cwd confdirname
  only_if { File.exist?(confdirname+"/control-#{node['hostname']}.key")}
  creates confdirname+"/control-service.key"
end
# wrap content in lazy because file is created after compile
#file confdirname+"/control-service.crt" do
#  lazy { content IO.read(confdirname+"/control-#{node['hostname']}.crt") }
#  creates confdirname+"/control-#{node['hostname']}.crt"
#  action :create
#end

#file confdirname+"/control-service.key" do
#  action :create
#  lazy { content IO.read(confdirname+"/control-#{node['hostname']}.key") }
#  creates confdirname+"/control-#{node['hostname']}.key"
#end

# make key for the control node
execute 'flocker node' do
  command "#{flockeropt}/flocker-ca create-node-certificate"
  cwd confdirname
end

execute 'crt copy' do
  command "ls -1 . | egrep '[A-Za-z0-9]+\-[A-Za-z0-9]+\-[A-Za-z0-9]+\-[A-Za-z0-9]+\-[A-Za-z0-9]+\.crt' | xargs -I {} mv {} #{confdirname}/node.crt"
  cwd confdirname
end

execute 'key copy' do
  command "ls -1 . | egrep '[A-Za-z0-9]+\-[A-Za-z0-9]+\-[A-Za-z0-9]+\-[A-Za-z0-9]+\-[A-Za-z0-9]+\.key' | xargs -I {} mv {} #{confdirname}/node.key"
  cwd confdirname
end

# Make keys for N number of Nodes
node['flocker-nodes'].times do |i|

  #create nodeN cert.
  execute 'flocker node' do
    command "#{flockeropt}/flocker-ca create-node-certificate"
    cwd confdirname
  end

  execute 'crt copy' do
    command "ls -1 . | egrep '[A-Za-z0-9]+\-[A-Za-z0-9]+\-[A-Za-z0-9]+\-[A-Za-z0-9]+\-[A-Za-z0-9]+\.crt' | xargs -I {} mv {} #{confdirname}/node#{i}.crt"
    cwd confdirname
  end

  execute 'key copy' do
    command "ls -1 . | egrep '[A-Za-z0-9]+\-[A-Za-z0-9]+\-[A-Za-z0-9]+\-[A-Za-z0-9]+\-[A-Za-z0-9]+\.key' | xargs -I {} mv {} #{confdirname}/node#{i}.key"
    cwd confdirname
  end

  #execute 'crt rm' do
  #  command "ls -1 . | egrep '[A-Za-z0-9]+\-[A-Za-z0-9]+\-[A-Za-z0-9]+\-[A-Za-z0-9]+\-[A-Za-z0-9]+\.crt' | xargs rm"
  #  cwd confdirname
  #end

  #execute 'key rm' do
  #  command "ls -1 . | egrep '[A-Za-z0-9]+\-[A-Za-z0-9]+\-[A-Za-z0-9]+\-[A-Za-z0-9]+\-[A-Za-z0-9]+\.key' | xargs rm"
  #  cwd confdirname
  #end

end



template confdirname+'/agent.yml' do
  source 'agent.yml.erb'
  mode '0755'
  owner 'root'
  group 'root'
end

case node['platform']
when 'debian', 'ubuntu'
file '/etc/init/flocker-control.override' do
  content 'start on runlevel [2345]
  stop on runlevel [016]'
end

execute 'services1' do
  command "echo 'flocker-control-api	4523/tcp			# Flocker Control API port' >> /etc/services"
  not_if "cat /etc/services | grep -e\"flocker-control-api\""
end
execute 'services2' do
  command "echo 'flocker-control-agent	4524/tcp			# Flocker Control Agent port' >> /etc/services"
  not_if "cat /etc/services | grep -e\"flocker-control-agent\""
end



when 'rhel', 'centos'

#systemctl enable flocker-control
service 'flocker-control' do
  action [ :enable, :start ]
end
end

service 'flocker-dataset-agent' do
  action [ :enable, :start ]
end

service 'flocker-container-agent' do
  action [ :enable, :start ]
end

service 'flocker-docker-plugin' do
  action [ :enable, :start ]
end
