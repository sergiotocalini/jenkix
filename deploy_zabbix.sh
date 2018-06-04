#!/usr/bin/env ksh
SOURCE_DIR=$(dirname $0)
ZABBIX_DIR=/etc/zabbix

JENKINS_URL=${1:-http://localhost:8080}
JENKINS_USER=${2}
JENKINS_PASS=${3}

mkdir -p ${ZABBIX_DIR}/scripts/agentd/jenkix

ZABBIX_SCRIPT_CONFIG=${ZABBIX_DIR}/scripts/agentd/jenkix/jenkix.conf
if [[ -f ${ZABBIX_DIR}/scripts/agentd/jenkix/jenkix.conf ]]; then
    ZABBIX_SCRIPT_CONFIG=${ZABBIX_DIR}/scripts/agentd/jenkix/jenkix.conf.new
fi

cp -rpv ${SOURCE_DIR}/jenkix/jenkix.conf.example  ${ZABBIX_SCRIPT_CONFIG}
cp -rpv ${SOURCE_DIR}/jenkix/jenkix.sh            ${ZABBIX_DIR}/scripts/agentd/jenkix/
cp -rpv ${SOURCE_DIR}/jenkix/zabbix_agentd.conf   ${ZABBIX_DIR}/zabbix_agentd.d/jenkix.conf

regex_array[0]="s|JENKINS_URL=.*|JENKINS_URL=\"${JENKINS_URL}\"|g"
regex_array[1]="s|JENKINS_USER=.*|JENKINS_USER=\"${JENKINS_USER}\"|g"
regex_array[1]="s|JENKINS_PASS=.*|JENKINS_PASS=\"${JENKINS_PASS}\"|g"
for index in ${!regex_array[*]}; do
    sed -i "${regex_array[${index}]}" ${ZABBIX_SCRIPT_CONFIG}
done
