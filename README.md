# jenkix
Zabbix Agent - Jenkins

# Dependencies
## Packages
* ksh
* jq
* curl

### Debian/Ubuntu

    #~ sudo apt install ksh jq curl
    #~

### Red Hat

    #~ sudo yum install ksh curl jq
    #~

# Deploy
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

*Note: this variables has to be saved in the config file (jenkix.conf) in the same directory than the script.*

## Zabbix
```
~# git clone https://github.com/sergiotocalini/jenkix.git
~# ./deploy_zabbix.sh -h
Usage:  [Options]

Options:
  -c            Configuration key CACHE_DIR.
  -h            Displays this help message.
  -i            Installation prefix (SCRIPT_DIR).
  -j            Configuration key JENKINS_URL.
  -p            Configuration key JENKINS_PASS.
  -t            Configuration key CACHE_TTL.
  -u            Configuration key JENKINS_USER.
  -z            Zabbix agent include files directory (ZABBIX_INC).

Please send any bug reports to sergiotocalini@gmail.com
~# sudo ./jenkix/deploy_zabbix.sh -j "<JENKINS_URL>" \
   				  -u "<JENKINS_USER>" \
				  -p "<JENKINS_PASS>"
~# sudo systemctl restart zabbix-agent
```

*Note: the installation has to be executed on the zabbix agent host and you have to import the template on the zabbix web. The default installation directory is /etc/zabbix/scripts/agentd/jenkix*
