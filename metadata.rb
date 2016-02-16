name             'docker-engine'
maintainer       'Kevin Kingsbury'
maintainer_email 'kingsbury_kevin@bah.com'
license          'All rights reserved'
description      'Installs/Configures docker-engine'
long_description 'Installs/Configures docker-engine'
version          '0.1.0'


depends 'yum', '~> 3.8.2'
depends 'yum-docker', '~> 0.3.0'
depends 'docker', '~> 2.3.19'
