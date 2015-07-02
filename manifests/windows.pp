class srcds::windows(
  $steamcmd_path = 'c:\steamcmd',
  $steamcmd_url  = 'https://steamcdn-a.akamaihd.net/client/installer/steamcmd.zip',
  $steamuser     = $::srcds::defaults['steamuser'],
  $steampass     = $::srcds::defaults['steampass'],
  $appid         = $::srcds::defaults['appid'],
  $gamedir       = $::srcds::defaults['gamedir'],
  $filesdir      = 'c:\steam',
  $beta          = '',
  $exemode       = '0755',
) {
  Exec { path => $::path, }
  File { source_permissions => ignore, }
  file { $steamcmd_path: ensure => directory, } ->
  file { $filesdir: ensure => directory, } ->

  file { "${steamcmd_path}/steamcmd.exe": source => "puppet:///modules/srcds/steamcmd.exe", mode => $exemode, } ->
  file { "${steamcmd_path}/update-${gamedir}.txt": content => template('srcds/steamcmd-script.erb'), } ->

  exec { 'install-srcds': command => "steamcmd +runscript update-${gamedir}.txt", cwd => $steamcmd_path, path => $steamcmd_path, creates => "${filesdir}/${gamedir}", timeout => 3600, }
}
