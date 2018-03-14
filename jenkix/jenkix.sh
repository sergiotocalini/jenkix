#!/usr/bin/env ksh
PATH=/usr/local/bin:${PATH}

#################################################################################

#################################################################################
#
#  Variable Definition
# ---------------------
#
APP_NAME=$(basename $0)
APP_DIR=$(dirname $0)
APP_VER="0.0.1"
APP_WEB="http://www.sergiotocalini.com.ar/"
TIMESTAMP=`date '+%s'`
CACHE_DIR=${APP_DIR}/tmp
CACHE_TTL=5                                      # IN MINUTES
#
#################################################################################

#################################################################################
#
#  Load Environment
# ------------------
#
[[ -f ${APP_DIR}/${APP_NAME%.*}.conf ]] && . ${APP_DIR}/${APP_NAME%.*}.conf

#
#################################################################################

#################################################################################
#
#  Function Definition
# ---------------------
#
usage() {
    echo "Usage: ${APP_NAME%.*} [Options]"
    echo ""
    echo "Options:"
    echo "  -a            Query arguments."
    echo "  -h            Displays this help message."
    echo "  -j            Jsonify output."
    echo "  -s ARG(str)   Section (default=stat)."
    echo "  -v            Show the script version."
    echo ""
    echo "Please send any bug reports to sergiotocalini@gmail.com"
    exit 1
}

version() {
    echo "${APP_NAME%.*} ${APP_VER}"
    exit 1
}

refresh_cache() {
    [[ -d ${CACHE_DIR} ]] || mkdir -p ${CACHE_DIR}
    file=${CACHE_DIR}/data.json
    if [[ $(( `stat -c '%Y' "${file}" 2>/dev/null`+60*${CACHE_TTL} )) -le ${TIMESTAMP} ]]; then
	RESOURCE="api/json?tree=jobs[name,description,url,healthReport[score]"
	RESOURCE+=",lastBuild[number,result,duration,timestamp]"
	RESOURCE+=",builds[number,result,duration,timestamp]]"
	if ! [[ -z ${JENKINS_USER} && -z ${JENKINS_PASS} ]]; then
	    CURL_AUTH_FLAG="--user"
	    CURL_AUTH_ATTR+="${JENKINS_USER}:${JENKINS_PASS}"
	fi
	curl -g -s ${CURL_AUTH_FLAG} "${CURL_AUTH_ATTR}" "${JENKINS_URL}/${RESOURCE}" | jq '.' > ${file}
    fi
    echo "${file}"
}

discovery() {
    resource=${1}
    json=$(refresh_cache)
    if [[ ${resource} == 'jobs' ]]; then
	for job in `jq -r '.jobs[].name' ${json}`; do
	    echo "${job}"
	done
    fi
    return 0
}

get_server_builds() {
    resource=${1}
    param1=${2}
    json=$(refresh_cache)
    if [[ ${resource} =~ ^(failure|success)$ ]]; then
	qfilter=`echo ${resource} | awk '{print toupper($0) }'`
	raw=`jq -r '.jobs[].builds[]|select(.result=="'${qfilter}'")|.timestamp' ${json}`
	res=0
	while read build; do
	    build_time=`echo $(( ${build} / 1000 ))`
	    if (( $(( (${TIMESTAMP}-${build_time})/60 )) < ${param1:-5} )); then
		let "res=res+1"
	    fi
	done <<< ${raw}	    
    fi
    echo ${res:-0}
}

get_server_jobs() {
    resource=${1}
    param1=${2}
    json=$(refresh_cache)
    if [[ ${resource} == 'health_score_avg' ]]; then
	raw=`jq -r ".jobs[].healthReport[].score" ${json}`
	all=`echo "${raw}" | wc -l | awk '{$1=$1};1'`
	sum=`echo "${raw}" | paste -sd+ - | bc`
	res=`echo "${sum}/${all}" | bc`
    elif [[ ${resource} == 'health_score_median' ]]; then
	raw=`jq -r ".jobs[].healthReport[].score" ${json} | sort -n`
	all=`echo "${raw}" | wc -l | awk '{$1=$1};1'`
	[ $((${all}%2)) -ne 0 ] && let "all=all+1"
	num=`echo $(( ${all} / 2))`
	res=`sed -n "${num}"p <<< "${raw}"`
    elif [[ ${resource} == 'health_score_mode' ]]; then
	raw=`jq -r ".jobs[].healthReport[].score" ${json} | sort -n`
	res=`echo "${raw}" | uniq -c | sort -k 1 | tail -1 | awk '{print $2}'`
    elif [[ ${resource} =~ ^(actives|inactives)$ ]]; then
	raw=`jq -r ".jobs[].lastBuild.timestamp" ${json}`
	actives=0
	inactives=0
	while read job; do
	    if [[ ${job} != 'null' ]]; then
		last=`echo $(( ${job} / 1000 ))`
		if (( $(( (${TIMESTAMP}-${last})/86400 )) < ${param1:-7} )); then
		    let "actives=actives+1"
		else
		    let "inactives=inactives+1"
		fi
	    fi
	done <<< ${raw}
	if [[ ${resource} == 'actives' ]]; then
	    res=${actives}
	else
	    res=${inactives}
	fi
    fi
    echo ${res:-0}
}

get_job_builds() {
    echo ${res:-0}
}

get_stats() {
    type=${1}
    name=${2}
    resource=${3}
    param1=${4}
    if [[ ${type} =~ ^server$ ]]; then
	if [[ ${name} == 'jobs' ]]; then
	    res=$( get_server_jobs ${resource} ${param1} )
	elif [[ ${name} == 'builds' ]]; then
	    res=$( get_server_builds ${resource} ${param1} )
	elif [[ ${name} == 'version' ]]; then
	    res=`curl -s -I ${JENKINS_URL} | awk 'BEGIN {FS=": "}/^X-Jenkins:/{print $2}'`
	fi
    elif [[ ${type} =~ ^job$ ]]; then
        res=`jq -r ".${type}.\"${name}\".${resource}" ${json}`
    fi
    echo ${res:-0}
}
#
#################################################################################

#################################################################################
while getopts "s::a:s:uphvj:" OPTION; do
    case ${OPTION} in
	h)
	    usage
	    ;;
	s)
	    SECTION="${OPTARG}"
	    ;;
        j)
            JSON=1
            IFS=":" JSON_ATTR=(${OPTARG//p=})
            ;;
	a)
	    ARGS[${#ARGS[*]}]=${OPTARG//p=}
	    ;;
	v)
	    version
	    ;;
         \?)
            exit 1
            ;;
    esac
done

if [[ ${JSON} -eq 1 ]]; then
    rval=$(discovery ${ARGS[*]})
    echo '{'
    echo '   "data":['
    count=1
    while read line; do
        IFS="|" values=(${line})
        output='{ '
        for val_index in ${!values[*]}; do
            output+='"'{#${JSON_ATTR[${val_index}]:-${val_index}}}'":"'${values[${val_index}]}'"'
            if (( ${val_index}+1 < ${#values[*]} )); then
                output="${output}, "
            fi
        done 
        output+=' }'
        if (( ${count} < `echo ${rval}|wc -l` )); then
            output="${output},"
        fi
        echo "      ${output}"
        let "count=count+1"
    done <<< ${rval}
    echo '   ]'
    echo '}'
else
    if [[ ${SECTION} == 'discovery' ]]; then
        rval=$(discovery ${ARGS[*]})
        rcode="${?}"
    else
	rval=$( get_stats ${SECTION} ${ARGS[*]} )
	rcode="${?}"
    fi
    echo ${rval:-0} | sed "s/null/0/g"
fi

exit ${rcode}
