#!/bin/bash

NAMETOSET="noname"

function usage { 
    echo "Please specify hostname "
    exit 1
}

function el6server {
cat > /etc/sysconfig/network << EOF
NETWORKING=yes
HOSTNAME=$NAMETOSET
EOF
}

function el7server {
hostnamectl set-hostname $NAMETOSET
hostnamectl --pretty set-hostname $NAMETOSET
}

function updateyo {
yum clean all
rm -rf /var/cache/yum
yum update -y
}

function ldapuserz {
yum install sssd authconfig openldap oddjob oddjob-mkhomedir -y
authconfig --enablesssd --enablesssdauth --enablemkhomedir --update
cat > /etc/sssd/sssd.conf << EOF
[domain/esss.lu.se]
id_provider = ldap
cache_credentials = True
use_fully_qualified_names = False
fallback_homedir = /home/%u
override_shell = /bin/bash
 
ldap_schema = AD
ldap_search_base = dc=esss,dc=lu,dc=se
ldap_uri = ldap://esss.lu.se
ldap_id_use_start_tls = True
ldap_default_bind_dn = cn=ldapreadonly,cn=Users,dc=esss,dc=lu,dc=se
ldap_default_authtok_type = password
ldap_default_authtok = YOURSUPERSECRETPASSWORD
ldap_id_mapping = True
 
# This is bad. We allow all certificates (even self-signed)
ldap_tls_reqcert = never
 
[sssd]
debug_level = 5
domains = esss.lu.se
services = nss, pam
config_file_version = 2
 
[nss]
 
[pam]
 
[sudo]
 
[autofs]
 
[ssh]
 
[pac]

EOF

chmod 600 /etc/sssd/sssd.conf

systemctl enable sssd.service
systemctl start sssd.service
systemctl enable oddjobd.service
systemctl start oddjobd.service

}

#Start of eval of arguments
if [ $# -eq 0 ];then
    usage
fi

if [ $# -gt 1 ];then
    usage
fi

if [ ! -z $1 ];then
    NAMETOSET=$1
else
    usage
fi

if [[ $(grep "e 6" /etc/redhat-release) ]];then
    el6server
elif [[ $(grep "e 7" /etc/redhat-release) ]];then
    el7server
else
    echo not redhat based or to old
fi

yum clean all
rm -rf /var/cache/yum
yum update -y
#ldapuserz
reboot

