class kandra::profile::zulipbot_zulip_org inherits kandra::profile::base {

  kandra::firewall_allow { 'http': }
  kandra::firewall_allow { 'https': }

  # This host has only 1GB of RAM; without swap, the nightly
  # unattended-upgrades run can starve zulipbot of memory until the
  # OOM killer intervenes.
  $swapfile = '/swapfile'
  exec { 'create swapfile':
    command => "/usr/bin/fallocate -l 1G ${swapfile}",
    creates => $swapfile,
  }
  file { $swapfile:
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0600',
    require => Exec['create swapfile'],
  }
  exec { 'mkswap swapfile':
    command => "/sbin/mkswap ${swapfile}",
    unless  => "/sbin/blkid -t TYPE=swap ${swapfile}",
    require => File[$swapfile],
  }
  mount { 'swap':
    ensure  => present,
    device  => $swapfile,
    fstype  => 'swap',
    options => 'sw',
    dump    => 0,
    pass    => 0,
    require => Exec['mkswap swapfile'],
  }
  exec { 'swapon swapfile':
    command => "/sbin/swapon ${swapfile}",
    unless  => "/bin/grep -q '^${swapfile} ' /proc/swaps",
    require => Mount['swap'],
  }
  zulip::sysctl { 'zulipbot-swappiness':
    key   => 'vm.swappiness',
    value => '10',
  }

  # TODO: This does not do any configuration of zulipbot itself, or of
  # caddy.
}
