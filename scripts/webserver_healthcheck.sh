#!/bin/bash

LOG_FILE="/var/log/webserver_healthcheck.log"
EXIT_CODE=0

log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

check_site() {
    local site_name="$1"
    local display_name="$2"
    local http_status

    http_status=$(curl --silent --output /dev/null --write-out "%{http_code}" \
        --connect-timeout 5 --header "Host: ${site_name}" http://localhost)

    if [ "$http_status" = "200" ]; then
        log_message "PASS: ${display_name} responded with HTTP 200"
    else
        log_message "FAIL: ${display_name} responded with HTTP ${http_status}"
        EXIT_CODE=1
    fi
}

log_message "==================== HEALTH CHECK START ===================="

if systemctl is-active --quiet nginx; then
    log_message "PASS: Nginx service is active"
else
    log_message "FAIL: Nginx service is NOT running"
    EXIT_CODE=1
fi

if ss -lnt | awk '{print $4}' | grep -Eq '(^|:|\])80$'; then
    log_message "PASS: Port 80 is listening"
else
    log_message "FAIL: Port 80 is NOT listening"
    EXIT_CODE=1
fi

check_site "site1.local" "Site 1"
check_site "site2.local" "Site 2"

if [ "$EXIT_CODE" -eq 0 ]; then
    log_message "OVERALL: HEALTHY"
else
    log_message "OVERALL: UNHEALTHY"
fi

log_message "===================== HEALTH CHECK END ====================="
echo | tee -a "$LOG_FILE"

exit "$EXIT_CODE"

