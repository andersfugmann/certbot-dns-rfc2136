#!/bin/bash

## Program for certbot authenthication using DNS as specificed in rfc2136.
## The program makes as few updates to the zone as possible to reduce
## increments to the zone serial The program is intended to be used as
## a manual hook for certbot to do authencication as a replacement for
## the dns_rfc2136 plugin which does not handle redirections (CNAMES)
## for authentication.
##
## Author: Anders Fugmann <anders .at. fugmann .dot. net>
## License: MIT

DEBUG=false
DEBUG_FILE=/tmp/certbot_dns_rfc2136.log

CREDENTIALS_INI=/etc/letsencrypt/rfc2136-credentials.ini

TTL=1

PARENT=$(ps -o ppid= -p $PPID)
${DEBUG} && echo "Parent: $(ps ax | grep ${PARENT})" >> ${DEBUG_FILE}
NSUPDATE_ROOT="/tmp/certbot_dns_rfc2136.${PARENT}.nsupdate.${CERTBOT_ALL_DOMAINS}"
NSUPDATE_FILE="${NSUPDATE_ROOT}.$(( CERTBOT_REMAINING_CHALLENGES ))"
NSUPDATE_FILE_NEXT="${NSUPDATE_ROOT}.$(( CERTBOT_REMAINING_CHALLENGES - 1 ))"

${DEBUG} && date >> ${DEBUG_FILE}
${DEBUG} && echo nsupdatefile: ${NSUPDATE_FILE} >> ${DEBUG_FILE}

# Source credentials, but remove spaces around equal and quote values
source <(cat ${CREDENTIALS_INI} | sed -E 's/([^ =]+)[ ]*=[ ]*(.*)/\1="\2"/' | grep -v '^#')
AUTH=${dns_rfc2136_algorithm}:${dns_rfc2136_name}:${dns_rfc2136_secret}


if [ ! -f ${NSUPDATE_FILE} ]; then
    touch ${NSUPDATE_FILE}
    chmod 600 ${NSUPDATE_FILE}
    echo "server ${dns_rfc2136_server}" > ${NSUPDATE_FILE}
fi

function get_record () {
    DOMAIN=$1
    read _ _ _ _ _ CNAME < <(host -t CNAME ${DOMAIN} ${dns_rfc2136_server} | tail -n 1)
    if [ "$CNAME" = "" ]; then
	echo ${DOMAIN}
    else
	## Resolve recursively.
	get_record ${CNAME%.}
    fi
}

RECORD_TO_UPDATE=$(get_record _acme-challenge.${CERTBOT_DOMAIN})
case "$1" in
    auth)
	ACTION=add
	;;
    cleanup)
	ACTION=delete
	## No need to wait for record deletion propergation time
	dns_rfc2136_propagation_time=0
	;;
esac

echo "update ${ACTION} ${RECORD_TO_UPDATE}. $TTL TXT ${CERTBOT_VALIDATION}" >> ${NSUPDATE_FILE}
if [ "${CERTBOT_REMAINING_CHALLENGES}" = "0" ]; then
    echo "send" >> ${NSUPDATE_FILE}
    ${DEBUG} && echo nsupdate -y ${AUTH} ${NSUPDATE_FILE} >> ${DEBUG_FILE}
    nsupdate -y ${AUTH} ${NSUPDATE_FILE}
    ${DEBUG} && mv ${NSUPDATE_FILE} ${NSUPDATE_FILE}.$(date +%s)
    ${DEBUG} || rm -f ${NSUPDATE_FILE}
    sleep ${dns_rfc2136_propagation_time}
else
    mv ${NSUPDATE_FILE} ${NSUPDATE_FILE_NEXT}
fi
