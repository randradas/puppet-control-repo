#!/bin/bash
FILE_DEBIAN_TIMEZONE="/etc/timezone"
FILE_DEBIAN_LOCALTIME="/etc/localtime"
FILE_DEBIAN_ZONEINFO_UTC="/usr/share/zoneinfo/UTC"
PUPPET_DEBIAN_INITD_DEFAULTS="/etc/default/puppet"
PUPPET_DEBIAN_CONF="/etc/puppet/puppet.conf"
PUPPET_DEBIAN_APT_OPTS="/etc/apt/preferences.d/00-puppet.pref"
PUPPET_DEBIAN_VERSION="3.8.4-1puppetlabs1"
PUPPET_DEBIAN_REPOS_URL="https://apt.puppetlabs.com/puppetlabs-release-wheezy.deb"
# following line gets .deb file full name from $PUPPET_DEBIAN_REPOS_URL
PUPPET_DEBIAN_REPOS="$(echo $PUPPET_DEBIAN_REPOS_URL | rev | cut -d'/' -f 1 | rev)"
DIR_TMP="/tmp/"
DIR_FACTS="/etc/facter/facts.d/"
FILE_FACTS="$DIR_FACTS/provisioned_facts.json"
FILE_LOG="/var/log/provisioning"
DOMAIN="xagent.dev.es.infrastructure.bbvadata.int"
PROJECT="$(echo $DOMAIN | cut -d'.' -f 4)"
LOCATION="$(echo $DOMAIN | cut -d'.' -f 3)"
APPLICATION_TIER="$(echo $DOMAIN | cut -d'.' -f 2)"
ROLE="$(echo $DOMAIN | cut -d'.' -f 1)"


# COMMANDS
MKDIR="$(which mkdir)"
SED="$(which sed) -i --"
CAT="$(which cat)"
DATE="$(which date)"
ECHO="$(which echo)"
DPKG="$(which dpkg)"
APTGET="$(which apt-get) -y"
WGET="$(which wget)"

configure_timezone() {
  # timezone is UTC (as recommended for cloud environments).
  cp $FILE_DEBIAN_ZONEINFO_UTC $FILE_DEBIAN_LOCALTIME
  $ECHO 'UTC' > $FILE_DEBIAN_TIMEZONE
  $ECHO "$($DATE) - timezone is configured" >> $FILE_LOG
  return 0
}


install_packages() {
  # install basic stuff
  $ECHO "$($DATE) - updating repositories" >> $FILE_LOG
  $APTGET update 2>&1 >> $FILE_LOG
  $APTGET install ruby-dev git
  local GEM="$(which gem)"
  $GEM install librarian-puppet
  [ $? -eq 0 ] && $ECHO "$($DATE) - librarian-puppet installed" >> $FILE_LOG || return 1
  return 0
}


install_puppet() {
  #install puppet agent, pin version (matching puppetmaster version is mandatory), configure it
  pushd .
  cd $DIR_TMP
  $ECHO "$($DATE) - enabling puppetlabs repositories" >> $FILE_LOG
  $WGET $PUPPET_DEBIAN_REPOS_URL 2>&1 >> $FILE_LOG
  $DPKG -i ./$PUPPET_DEBIAN_REPOS 2>&1 >> $FILE_LOG
  [ $? -eq 0 ] && $ECHO "$($DATE) - puppetlabs repositories enabled" >> $FILE_LOG || return 1

  $APTGET update 2>&1 >> $FILE_LOG
  $APTGET install puppet=$PUPPET_DEBIAN_VERSION puppet-common=$PUPPET_DEBIAN_VERSION 2>&1 >> $FILE_LOG
  [ $? -eq 0 ] && $ECHO "$($DATE) - puppet agent installed" >> $FILE_LOG || return 1
  popd

# pin puppet version
$CAT > $PUPPET_DEBIAN_APT_OPTS << EOF
Package: puppet puppet-common
Pin: version $PUPPET_DEBIAN_VERSION
Pin-Priority: 501
EOF
  $ECHO "$($DATE) - puppet agent version pinned" >> $FILE_LOG
}


configure_puppet() {
  # puppet.conf file
$CAT > $PUPPET_DEBIAN_CONF << EOF
[main]
logdir=/var/log/puppet
vardir=/var/lib/puppet
ssldir=/var/lib/puppet/ssl
rundir=/var/run/puppet
factpath=\$vardir/lib/facter
runinterval=18000
EOF
  $ECHO "$($DATE) - puppet agent configured" >> $FILE_LOG

  $SED 's/START=no/START=yes/' $PUPPET_DEBIAN_INITD_DEFAULTS
  $ECHO "$($DATE) - puppet starting defaults at boot time set to 'yes'" >> $FILE_LOG
  return 0
}


deploy_modules() {
  pushd /vagrant/
  librarian-puppet install
  rsync -avz --progress /vagrant/site/* /vagrant/modules/
  popd
}


configure_facts() {
  # set provisionedfacts,json
  $MKDIR -p $DIR_FACTS
$CAT > $FILE_FACTS << EOF
{
    "project": "$PROJECT",
    "location": "$LOCATION",
    "application_tier": "$APPLICATION_TIER",
    "role": "$ROLE"
}
EOF
  $ECHO "$($DATE) - $FILE_FACTS configured" >> $FILE_LOG
  return 0
}


main() {
  configure_timezone
  [ $? -eq 0 ] && install_packages || return 1
  [ $? -eq 0 ] && install_puppet || return 1
  [ $? -eq 0 ] && configure_puppet || return 1
  [ $? -eq 0 ] && deploy_modules || return 1
  [ $? -eq 0 ] && configure_facts || return 1
  return 0
}


main
[ $? -eq 0 ] && exit 0 || exit 1
