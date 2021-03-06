# === Type: kerberos::ktadd
#
# Adds a kerberos key to a keytab. Supports use of kadmin.local or kadmin. The
# latter supports use of a ticket cache or a keytab file.
#
# === Authors
#
# Michael Weiser <michael.weiser@gmx.de>
#

# infer principal and keytab file names from title if not given explicitly,
# syntax: <keytab>@<principal_possibly_containing_more_@s>
define kerberos::ktadd(
  $keytab = regsubst($title, '@.*$', ''),
  $principal = regsubst($title, '^[^@]*@', ''),
  $local = true, $reexport = false,
  $kadmin_ccache = undef, $kadmin_keytab = undef,
  $kadmin_tries = undef, $kadmin_try_sleep = undef,
  $kadmin_server_package = $kerberos::kadmin_server_package,
  $client_packages = $kerberos::client_packages,
  $krb5_conf_path = $kerberos::krb5_conf_path,
  $realm = $kerberos::realm,
) {
  $ktadd = "ktadd_${keytab}_${principal}"
  if $local {
    $kadmin = 'kadmin.local'
    Package[$kadmin_server_package] -> Exec[$ktadd]
    Exec['create_krb5kdc_principal'] -> Exec[$ktadd]
  } else {
    $kadmin = 'kadmin'

    $ccache_par = $kadmin_ccache ? {
      undef   => '',
      default => "-c '${kadmin_ccache}'"
    }

    $keytab_par = $kadmin_keytab ? {
      undef   => '',
      default => "-k '${kadmin_keytab}'"
    }

    Package[$client_packages] -> Exec[$ktadd]
    File['krb5.conf'] -> Exec[$ktadd]
  }

  if $reexport {
    $unless = undef
  } else {
    $unless = "klist -k '${keytab}' | grep ' ${principal}@${realm}'"
  }

  $cmd = "ktadd -k ${keytab} ${principal}"
  exec { "ktadd_${keytab}_${principal}":
    command     => "${kadmin} ${ccache_par} ${keytab_par} -q '${cmd}'",
    unless      => $unless,
    path        => [ '/bin', '/usr/bin', '/usr/bin', '/usr/sbin' ],
    environment => "KRB5_CONFIG=${krb5_conf_path}",
    require     => File[$keytab],
    tries       => $kadmin_tries,
    try_sleep   => $kadmin_try_sleep,
  }
}
