name             'docker-engine'
maintainer       'Kevin Kingsbury'
maintainer_email 'kingsbury_kevin@bah.com'
license          'All rights reserved'
description      'Installs/Configures docker-engine'
long_description 'Installs/Configures docker-engine'
version          '0.1.1'

depends 'yum', '~> 3.8.2'
depends 'apt', '~> 3.0.0'
depends 'yum-docker', '~> 0.3.0'
#depends 'apt-docker', '~> 0.3.0'

#depends 'docker', '~> 2.3.19'
depends 'docker', '~> 2.5.8'
depends 'chef-client', '~> 4.3.1'

depends 'python', '~> 1.4.6'
