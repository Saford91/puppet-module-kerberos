# == Class: kerberos::base
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
class kerberos::base (
  $pkinit_anchors = $kerberos::pkinit_anchors,
  $pkinit_packages = $kerberos::pkinit_packages,
) inherits kerberos {
  if $pkinit_anchors {
    package { $pkinit_packages:
      ensure => present,
      tag    => 'krb5-pkinit-packages',
    }
  }
}
