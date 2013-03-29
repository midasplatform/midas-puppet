

class midas {

  #### TODO anything with apache default site or https
  #### TODO maybe break this out to install, config, params...

  $midas_git_repo = 'http://public.kitware.com/MIDAS/Midas3.git'
  $projects_root = '/projects'
  $midas_dir = 'midas'
  $midas_path = "${projects_root}/${midas_dir}"
  # TODO: get this from facter or apache?
  $doc_root = '/var/www'
  $midas_link_path = "${doc_root}/${midas_dir}"





  ## update os packages
  exec { 'package update':
      command => 'apt-get update',
      path => ['/usr/bin'],
  }
  
  ## install non config packages
  package { 'imagemagick':
    name => $imagemagick,
    ensure => installed,
    require => Exec['package update']
  }
  
  package { 'sendmail':
    ensure => installed,
    require => Exec['package update']
  }

  package { 'git':
    ensure => present,
    require => Exec['package update'],
  }
  
  
  ## install apache and modules
  class {'apache': 
    require => Exec['package update']
  }

  class {'apache::mod::php': }

  class {'apache::mod::ssl': }

  #no native support yet in apache module for mod_rewrite
  apache::mod { 'rewrite': }
  
#  apache::vhost{ 'midas': 
#    docroot => '/var/www/midas',
#    port    => '80',
#    priority => '0',
#    options => 'FollowSymLinks',
#    override => 'All',
#    ssl => true,
#    redirect_ssl => true,
#  }
#





 
  ## install php and modules 
  package { 'php5':
    ensure => installed,
    require => [Package['httpd'], Exec['package update']],
    notify => Service['httpd'],
  }

  package { 'php5-ldap':
    ensure => installed,
    require => Package['php5'],
    notify => Service['httpd'],
  }
  
  package { 'php5-gd':
    ensure => installed,
    require => Package['php5'],
    notify => Service['httpd'],
  }
  
  # set up php session garbage collection
  cron {
    'php_session_cleanup':
      command => "root [ -x /usr/lib/php5/maxlifetime ] && [ -d /var/lib/php5 ] && find /var/lib/php5/ -depth -mindepth 1 -maxdepth 1 -type f -cmin +$(/usr/lib/php5/maxlifetime) ! -execdir fuser -s {} 2>/dev/null \\; -delete",
      user    => root,
      minute  => [09, 39],
  }
  
  # copy the midas specific php configuration file
  $phpConfPath = '/etc/php5/apache2/conf.d/midas.ini'
  file { $phpConfPath:
    require => Package['php5'],
    ensure => present,
    owner => root, group => root, mode => 444,
    source => "puppet:///modules/midas/midas.ini",
    notify => Service['httpd'],
  }
  

  ## install mysql and modules 
  class { 'mysql':
    require => Exec['package update'],
  }

  class { 'mysql::php':
    require => Package['php5'],
    notify => Service['httpd'],
  }

  class { 'mysql::server':
    require => Exec['package update'],
  }
 
  # install the midas db
  # TODO paramaterize this 
  mysql::db { 'midas db':
    ensure   => present,
    user     => 'midas',
    password => 'midas',
    host     => 'localhost',
    charset  => 'utf8',
    grant    => ['all'],
  }


  ## create projects directory
  file { $projects_root:
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => 755,
  }


  ## install midas application
  # git clone midas
  # TODO: what about just updating midas, rather than cloning, a particular commit or tag?
  exec {
    'midas_git_clone':
      path => ['/usr/bin'],
      cwd => $projects_root,
      # creates ensures won't clone if this dir already exists
      creates => "${projects_root}/${midas_dir}",
      command => "git clone ${midas_git_repo} ${midas_dir}",
      require => [ Package['git'], File[$projects_root] ],
  }
  

  # give ownership of midas tree to apache user
  # would like to do this using a file type rather than exec, but that was super slow
  $apache_user = 'www-data'
  exec {
    'chown apache_user midas':
      require => Exec['midas_git_clone'],
      path => ['/bin'],
      command => "chown -R ${apache_user}:${apache_user} ${midas_path}",
  }
  
  file {
    "${midas_link_path}":
      require => [Package['httpd'], Exec['chown apache_user midas']],
      ensure  => 'link',
      target  => $midas_path,
  }
  

}
