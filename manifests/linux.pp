class srcds::linux(
  $user              = $::srcds::user,
  $group             = $::srcds::group,
  $uid               = $::srcds::uid,
  $gid               = $::srcds::gid,
  $homedir           = $::srcds::homedir,
  $steamuser         = $::srcds::defaults['steamuser'],
  $steampass         = $::srcds::defaults['steampass'],
  $appid             = $::srcds::defaults['appid'],
  $gamedir           = $::srcds::defaults['gamedir'],
) {
  $rootdir           = $::srcds::homedir
  $filesdir          = "${rootdir}/serverfiles"
  $systemdir         = "${filesdir}/${gamedir}"
  $executabledir     = "${filesdir}"
  $executable        = "./srcds_linux"
  $servercfgdir      = "${systemdir}/cfg"
  $gamelogdir        = "${systemdir}/logs"
  $scriptlogdir      = "${rootdir}/log/script"
  $scriptlog         = "${scriptlogdir}/${servicename}-script.log"
  $consolelogdir     = "${rootdir}/log/console"
  $serverlogdir      = "${rootdir}/log/server"

  include wget

  #Create hash of options
  $options = merge({'ip' => $::ipaddress},$::srcds::defaults)

  #Set defaults for resources
  Vcsrepo { owner => $user, group => $group, ensure => present, provider => git, revision => 'master', }
  File { owner => $user, group => $group, }
  Exec { user => $user, }

  #Install packages
  $packages = $::osfamily ? {
    'debian' => ['gdb','mailutils','postfix','lib32gcc1'],
    default => ['git','gdb','mailx','nano','tmux','glibc.i686','libstdc++.i686'],
  }
  package { $packages: ensure => present, } ->

  #Set up group and user with homedir
  group { $group: gid => $gid, } ->
  user { $user: uid => $uid, home => $homedir, gid => $group, } ->
  exec { 'create-homedir': command => "/bin/mkdir -p \"${homedir}\"", creates => $homedir, user => 'root', notify => Exec['fix-srcds-permissions'], } ->
  file { $homedir: ensure => directory, } ->

  #Install scripts
  file { "${homedir}/${gamedir}": mode => '0755', content => template('srcds/script.erb'), } ->
  file { "${homedir}/cfg.${gamedir}": ensure => directory, } ->

  #Install SteamCMD
  file { "${rootdir}/steamcmd": ensure => directory, } ->
  download_uncompress { 'install_steamcmd':
    download_base_url => 'http://media.steampowered.com/client/',
    distribution_name => 'steamcmd_linux.tar.gz',
    dest_folder       => "${rootdir}/steamcmd",
    creates           => "${rootdir}/steamcmd/steamcmd.sh",
    uncompress        => 'tar.gz',
    user              => $user,
    group             => $group,
  } ->
  file { "${rootdir}/steamcmd/steamcmd.sh": mode => '0755', } ->

  #Apply Steam client fix
  file { "${homedir}/.steam": ensure => directory, } ->
  file { "${homedir}/.steam/sdk32": ensure => directory, } ->
  file { "${homedir}/.steam/sdk32/steamclient.so": ensure => symlink, target => "${rootdir}/steamcmd/linux32/steamclient.so", } ->

  #Create filesdir
  exec { 'create-filesdir': command => "/bin/mkdir -p ${filesdir}", creates => $filesdir, user => 'root', notify => Exec['fix-srcds-permissions'], } ->
  file { $filesdir: ensure => directory, source => 'puppet:///modules/srcds/serverfiles', recurse => remote, } ->

  #Create logging directory structure
  exec { 'create-scriptlogdir': command => "/bin/mkdir -p ${scriptlogdir}", creates => $scriptlogdir, user => 'root', notify => Exec['fix-srcds-permissions'], } ->
  exec { 'create-consolelogdir': command => "/bin/mkdir -p ${consolelogdir}", creates => $consolelogdir, user => 'root', notify => Exec['fix-srcds-permissions'], } ->
  exec { 'create-serverlogdir': command => "/bin/mkdir -p ${serverlogdir}", creates => $serverlogdir, user => 'root', notify => Exec['fix-srcds-permissions'], } ->
  file { $scriptlogdir: ensure => directory, } ->
  file { $consolelogdir: ensure => directory, } ->
  file { $serverlogdir: ensure => directory, } ->

  #Install srcds
  file { "${rootdir}/steamcmd/update.txt": content => template('srcds/steamcmd-script.erb'), } ->

  
  #Glibc fix
  exec { 'create-bindir': command => "/bin/mkdir -p ${filesdir}/bin", creates => "${filesdir}/bin", user => 'root', notify => Exec['fix-srcds-permissions'], } ->
  exec { 'install-srcds': path => "${rootdir}/steamcmd", cwd => "${rootdir}/steamcmd", command => "steamcmd.sh +runscript update.txt|/usr/bin/tee -a \"${scriptlog}\"", creates => "${filesdir}/${executable}", timeout => 3600, require => Exec['fix-srcds-permissions'], } ->

  #Symlink game log directory to server log dir
  file { $gamelogdir: ensure => symlink, target => $serverlogdir, } ->

  #Create default instance (sets up scripts and startup configs)
  srcds::instance { 'default': config => $options, }

  #Permissions fixup called as needed
  exec { 'fix-srcds-permissions': command => "/bin/chown ${user}:${group} ${homedir} -R", refreshonly => true, }

}
