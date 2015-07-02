define srcds::instance(
  $config    = {},
  $servercfg = {},
  $autostart = true,
  $monitor   = true,
  $servercfg = {},
  $overwrite = false,
  $gamedir   = $::srcds::defaults['gamedir'],
) {
  if ($osfamily == 'Windows') {
  } else {
    #Firewall defaults
    Firewall { proto => udp, action => accept, }

    if ($title != 'default') {
      file { "${::srcds::linux::homedir}/${title}": ensure => symlink, target => "${::srcds::linux::homedir}/${gamedir}", }
      $cmd = $title
    } else {
      $cmd = $gamedir
    }

    $rule_clientport = "${config['clientport']} UDP srcds"
    if (!defined(Firewall[$rule_clientport])) {
      firewall { $rule_clientport: port => $config['clientport'], }
    }

    $rule_port = "${config['port']} UDP srcds"
    if (!defined(Firewall[$rule_port])) {
      firewall { $rule_port: port => $config['port'], }
    }

    $rule_sourcetvport = "${config['sourcetvport']} UDP srcds"
    if (!defined(Firewall[$rule_sourcetvport])) {
      firewall { $rule_sourcetvport: port => $config['sourcetvport'], }
    }

    #Create server config
    if (!defined(File[$::srcds::linux::servercfgdir])) {
      exec { 'create-servercfgdir': command => "/bin/mkdir -p ${::srcds::linux::servercfgdir}", creates => $::srcds::linux::servercfgdir, user => root, } ->
      file { $::srcds::linux::servercfgdir: ensure => directory, }
    }
    file { "${::srcds::linux::filesdir}/${gamedir}/cfg/${cmd}.cfg": content => template('srcds/servercfg.erb'), } ->

    #Create config for script
    file { "${::srcds::linux::homedir}/cfg.${gamedir}/${cmd}.cfg": content => template('srcds/instance.cfg.erb'), replace => $overwrite, }

    if ($autostart) {
      cron { "update-${cmd}": user => $::srcds::linux::user, command => "cd ${::srcds::linux::homedir} && ./${cmd} update-restart", }
    }

    if ($monitor) {
      cron { "monitor-${cmd}": user => $::srcds::linux::user, command => "cd ${::srcds::linux::homedir} && ./${cmd} monitor", }
    }
  }
}
