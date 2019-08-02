#!/usr/bin/env ksh
SOURCE_DIR=$(dirname $0)
ZABBIX_DIR=/etc/zabbix

usage() {
    echo "Usage: ${APP_NAME%.*} [Options]"
    echo ""
    echo "Options:"
    echo "  -c            Configuration key CACHE_DIR."
    echo "  -h            Displays this help message."
    echo "  -i            Installation prefix (SCRIPT_DIR)."
    echo "  -j            Configuration key JENKINS_URL."
    echo "  -p            Configuration key JENKINS_PASS."
    echo "  -t            Configuration key CACHE_TTL."
    echo "  -u            Configuration key JENKINS_USER."
    echo "  -z            Zabbix agent include files directory (ZABBIX_INC)."
    echo ""
    echo "Please send any bug reports to sergiotocalini@gmail.com"
    exit 1
}

while getopts ":cfitz:hjpu" OPTION; do
    case ${OPTION} in
	c)
	    CACHE_DIR="${OPTARG}"
	    ;;
	h)
	    usage
	    ;;
	i)
	    SCRIPT_DIR="${OPTARG}"
	    if [[ ! "${SCRIPT_DIR}" =~ .*jenkix ]]; then
		SCRIPT_DIR="${SCRIPT_DIR}/jenkix"
	    fi
	    ;;
	j)
	    JENKINS_URL="${OPTARG}"
	    ;;
        p)
            JENKINS_PASS="${OPTARG}"
            ;;
	t)
	    CACHE_TTL="${OPTARG}"
	    ;;
	u)
	    JENKINS_USER="${OPTARG}"
	    ;;
	z)
	    ZABBIX_INC="${OPTARG}"
	    ;;
        \?)
	    exit 1
            ;;
    esac
done

[ -n "${JENKINS_URL}" ] || JENKINS_URL="http://localhost:8080"
[ -n "${SCRIPT_DIR}"  ] || SCRIPT_DIR="${ZABBIX_DIR}/scripts/agentd/jenkix"
[ -n "${ZABBIX_INC}"  ] || ZABBIX_INC="${ZABBIX_DIR}/zabbix_agentd.d"
[ -n "${CACHE_DIR}"   ] || CACHE_DIR="${SCRIPT_DIR}/tmp"
[ -n "${CACHE_TTL}"   ] || CACHE_TTL=5

mkdir -p "${SCRIPT_DIR}" "${ZABBIX_INC}" 2>/dev/null
# Copying the main script
cp -rpv "${SOURCE_DIR}/jenkix/jenkix.sh"            "${SCRIPT_DIR}/jenkix.sh"

# Provisioning script configuration
SCRIPT_CFG="${SCRIPT_DIR}/jenkix.conf"
cp -rpv "${SOURCE_DIR}/jenkix/jenkix.conf.example"  "${SCRIPT_CFG}.new"
regex_cfg[0]="s|JENKINS_URL=.*|JENKINS_URL=\"${JENKINS_URL}\"|g"
regex_cfg[1]="s|JENKINS_USER=.*|JENKINS_USER=\"${JENKINS_USER}\"|g"
regex_cfg[2]="s|JENKINS_PASS=.*|JENKINS_PASS=\"${JENKINS_PASS}\"|g"
regex_cfg[3]="s|CACHE_DIR=.*|CACHE_DIR=\"${CACHE_DIR}\"|g"
regex_cfg[4]="s|CACHE_TTL=.*|CACHE_TTL=\"${CACHE_TTL}\"|g"
for index in ${!regex_cfg[*]}; do
    sed -i '' -e "${regex_cfg[${index}]}" "${SCRIPT_CFG}.new"
done
if [[ -f "${SCRIPT_CFG}" ]]; then
    state=$(cmp --silent "${SCRIPT_CFG}" "${SCRIPT_CFG}.new")
    if [[ ${?} == 0 ]]; then
	rm "${SCRIPT_CFG}.new" 2>/dev/null
    fi
else
    mv "${SCRIPT_CFG}.new" "${SCRIPT_CFG}" 2>/dev/null
fi

# Provisioning zabbix_agentd configuration
SCRIPT_ZBX="${ZABBIX_INC}/jenkix.conf"
cp -rpv "${SOURCE_DIR}/jenkix/zabbix_agentd.conf"   "${SCRIPT_ZBX}.new"
regex_inc[0]="s|{PREFIX}|${SCRIPT_DIR}|g"
for index in ${!regex_inc[*]}; do
    sed -i '' -e "${regex_inc[${index}]}" "${SCRIPT_ZBX}.new"
done
if [[ -f "${SCRIPT_ZBX}" ]]; then
    state=$(cmp --silent "${SCRIPT_ZBX}" "${SCRIPT_ZBX}.new")
    if [[ ${?} == 0 ]]; then
	rm "${SCRIPT_ZBX}.new" 2>/dev/null
    fi
else
    mv "${SCRIPT_ZBX}.new" "${SCRIPT_ZBX}" 2>/dev/null
fi

