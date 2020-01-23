# jenkix
Zabbix Agent - Jenkins

# Dependencies
## Packages
* ksh
* jq
* curl
* sudo

### Debian/Ubuntu
```
~# sudo apt install ksh jq curl sudo
~#
```
### Red Hat
```
~# sudo yum install ksh curl jq sudo
~#
```
# Deploy
## Sudoers
The deploy script is not intended to advise which approach you should implemented nor
deploy the sudoers configuration but the user that will run the script needs be running
with sudo privileges.

There are two options to setting up sudoers for the user:
1. Provided sudo all
```bash
~# cat /etc/sudoers.d/user_zabbix
Defaults:zabbix !syslog
Defaults:zabbix !requiretty

zabbix	ALL=(ALL)  NOPASSWD:ALL
~#
```
2. Limited acccess to run command with sudo
```bash
~# cat /etc/sudoers.d/user_zabbix
Defaults:zabbix !syslog
Defaults:zabbix !requiretty

zabbix ALL=(ALL) NOPASSWD: /usr/bin/lsof *
~#
```
## Parameters
The username and the password can be empty if jenkins has the read only option enable.
Default variables:

NAME|VALUE
----|-----
JENKINS_URL|http://localhost:8080
JENKINS_USER|<empty>
JENKINS_PASS|<empty>
CACHE_DIR|/etc/zabbix/scripts/agentd/jenkix/tmp
CACHE_TTL|5
SCRIPT_DIR|/etc/zabbix/scripts/agentd/jenkix
ZABBIX_INC|/etc/zabbix/zabbix_agentd.d

*__Note:__ this variables has to be saved in the config file (jenkix.conf) in the same directory than the script.*

## Demo
```
~# git clone https://github.com/sergiotocalini/jenkix.git
~# ./jenkix/deploy_zabbix.sh -H
Usage:  [Options]

Options:
  -F            Force configuration overwrite.
  -H            Displays this help message.
  -P            Installation prefix (SCRIPT_DIR).
  -Z            Zabbix agent include files directory (ZABBIX_INC).
  -c            Configuration key CACHE_DIR.
  -j            Configuration key JENKINS_URL.
  -p            Configuration key JENKINS_PASS.
  -t            Configuration key CACHE_TTL.
  -u            Configuration key JENKINS_USER.

Please send any bug reports to sergiotocalini@gmail.com
~# sudo ./jenkix/deploy_zabbix.sh -j "<JENKINS_URL>" \
   				  -u "<JENKINS_USER>" \
				  -p "<JENKINS_PASS>"
~# sudo systemctl restart zabbix-agent
```

*__Note:__ the installation has to be executed on the zabbix agent host and you have to import the template on the zabbix web. The default installation directory is /etc/zabbix/scripts/agentd/jenkix*
