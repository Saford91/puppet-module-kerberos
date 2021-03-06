# === Class: kerberos::server::kpropd
#
# Kerberos kpropd service. Installs and starts the kpropd service on a slave
# KDC.
#
# === Authors
#
# Jason Edgecombe <jason@rampaginggeek.com>
# Additions by Michael Weiser <michael.weiser@gmx.de>
#
# === Copyright
#
# Copyright 2013 Jason Edgecombe, unless otherwise noted.
#
class kerberos::server::kpropd (
  $kdc_database_path = $kerberos::kdc_database_path,

  $kpropd_acl_path = $kerberos::kpropd_acl_path,
  $kpropd_master_principal = $kerberos::kpropd_master_principal_cfg,
  $kpropd_service_name = $kerberos::kpropd_service_name,
  $kpropd_keytab = $kerberos::kpropd_keytab,
  $kpropd_principal = $kerberos::kpropd_principal,

  $pkinit_anchors = $kerberos::pkinit_anchors,
  $host_ticket_cache_ccname = $kerberos::host_ticket_cache_ccname,

  # facter fact
  $kerberos_bootstrap = $::kerberos_bootstrap,
) inherits kerberos {
  include kerberos::server::kdc

  if $kerberos_bootstrap {
    $kadmin_try_sleep = 60
  } else {
    $kadmin_try_sleep = 10
  }

  # if we have pkinit we can automatically create the keytab
  $ktadd = "${kpropd_keytab}@${kpropd_principal}"

  notify { "ktadd = ${kpropd_keytab}@${kpropd_principal}" : }
  notify { "pkinit_anchors = ${pkinit_anchors}" : }

  if $pkinit_anchors and !defined(Kerberos::Addprinc_keytab_ktadd[$ktadd]) {
    kerberos::addprinc_keytab_ktadd { $ktadd:
      local            => false,
      kadmin_ccache    => $host_ticket_cache_ccname,
      # if we're bootstrapping the master might not be up yet and even if not
      # it might just be rebooting
      kadmin_tries     => 30,
      kadmin_try_sleep => $kadmin_try_sleep,
    } -> Service['kpropd']
  }

  file { 'kpropd.acl':
    ensure  => file,
    path    => $kpropd_acl_path,
    content => template('kerberos/kpropd.acl.erb'),
    mode    => '0600',
    owner   => 0,
    group   => 0,
  }

  require stdlib
  $kdc_database_dir = dirname($kdc_database_path)

  service { 'kpropd':
    ensure     => running,
    name       => $kpropd_service_name,
    enable     => true,
    hasrestart => true,
    hasstatus  => true,
    subscribe  => File['kdc.conf', 'kpropd.acl', $kpropd_keytab],
    # kpropd needs its keytab to work
    require    => [ Kerberos::Ktadd[$ktadd], File[$kdc_database_dir] ]
  }
}
