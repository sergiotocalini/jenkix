#!/usr/bin/env ksh
SOURCE_DIR=$(dirname $0)
ZABBIX_DIR=/etc/zabbix

JENKINS_URL=${1:-http://localhost:8080}
JENKINS_USER=${2}
JENKINS_PASS=${3}

mkdir -p ${ZABBIX_DIR}/scripts/agentd/jenkix
cp ${SOURCE_DIR}/jenkix/jenkix.conf.example ${ZABBIX_DIR}/scripts/agentd/jenkix/jenkix.conf
cp ${SOURCE_DIR}/jenkix/jenkix.sh ${ZABBIX_DIR}/scripts/agentd/jenkix/
cp ${SOURCE_DIR}/jenkix/zabbix_agentd.conf ${ZABBIX_DIR}/zabbix_agentd.d/jenkix.conf
sed -i "s|JENKINS_URL=.*|JENKINS_URL=\"${JENKINS_URL}\"|g" ${ZABBIX_DIR}/scripts/agentd/jenkix/jenkix.conf
sed -i "s|JENKINS_USER=.*|JENKINS_USER=\"${JENKINS_USER}\"|g" ${ZABBIX_DIR}/scripts/agentd/jenkix/jenkix.conf
sed -i "s|JENKINS_PASS=.*|JENKINS_PASS=\"${JENKINS_PASS}\"|g" ${ZABBIX_DIR}/scripts/agentd/jenkix/jenkix.conf
