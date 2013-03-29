define midas::apachesetup {

  $apache_conf_path = '/etc/apache2'
  $sites_available = "${apache_conf_path}/sites-available"
  $sites_enabled = "${apache_conf_path}/sites-enabled"

  # create and link midas_directory
  file { "${sites_available}/midas_directory":
    require => Package['httpd'],
    ensure => present,
    owner => root, group => root, mode => 644,
    source => "puppet:///modules/midas/midas_directory",
  }
  file { "${sites_enabled}/midas_directory":
    require => File["${sites_available}/midas_directory"],
    ensure => 'link',
    target => "${sites_available}/midas_directory",
    notify => Service['apache2'],
  }
 

  # create and link midasdocroot_sslonly
  file { "${sites_available}/midasdocroot_sslonly":
    require => Package['httpd'],
    ensure => present,
    owner => root, group => root, mode => 644,
    source => "puppet:///modules/midas/midasdocroot_sslonly",
  }
  file { "${sites_enabled}/midasdocroot_sslonly":
    require => File["${sites_available}/midasdocroot_sslonly"],
    ensure => 'link',
    target => "${sites_available}/midasdocroot_sslonly",
    notify => Service['apache2'],
  }
  

}
