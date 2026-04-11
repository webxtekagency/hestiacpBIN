#!/bin/bash

TOOL_VERSION="1.0.0"
TOOL_NAME="v-security-audit"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
WHITE='\033[1;37m'
GRAY='\033[0;90m'
BOLD='\033[1m'
NC='\033[0m'

SCORE=100
TOTAL_CRITICAL=0
TOTAL_FAIL=0
TOTAL_WARN=0
TOTAL_PASS=0
TOTAL_INFO=0
TOTAL_SKIP=0

LOG_FILE=""
LOG_DIR="/var/log/hestia/security-audit"
JSON_RESULTS=()
CURRENT_SECTION=""

MODE_QUIET=false
MODE_VERBOSE=false
MODE_JSON=false
MODE_HTML=false
MODE_MD=false
MODE_NO_COLOR=false
MODE_EMAIL=""

init_logging() {
    mkdir -p "$LOG_DIR" 2>/dev/null
    local timestamp
    timestamp=$(date +%Y%m%d-%H%M%S)
    LOG_FILE="${LOG_DIR}/${timestamp}.log"
    echo "# v-security-audit v${TOOL_VERSION} — $(date)" > "$LOG_FILE"
    echo "# Host: $(hostname)" >> "$LOG_FILE"
    echo "# Mode: $1" >> "$LOG_FILE"
    echo "---" >> "$LOG_FILE"
}

disable_colors() {
    RED='' GREEN='' YELLOW='' BLUE='' CYAN='' MAGENTA='' WHITE='' GRAY='' BOLD='' NC=''
}

print_banner() {
    if $MODE_QUIET; then return; fi
    echo ""
    echo -e "${BOLD}${CYAN}════════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}${WHITE} v-security-audit v${TOOL_VERSION}${NC}"
    echo -e "${BOLD}${WHITE} HestiaCP Security Audit Tool${NC}"
    echo -e "${GRAY} Date: $(date)${NC}"
    if [ -f /etc/os-release ]; then
        source /etc/os-release
        echo -e "${GRAY} OS: ${PRETTY_NAME}${NC}"
    fi
    if [ -f /usr/local/hestia/conf/hestia.conf ]; then
        local hv
        hv=$(grep '^VERSION=' /usr/local/hestia/conf/hestia.conf 2>/dev/null | cut -d"'" -f2)
        echo -e "${GRAY} HestiaCP: ${hv:-unknown}${NC}"
    fi
    echo -e "${GRAY} Hostname: $(hostname)${NC}"
    echo -e "${GRAY} Mode: $1${NC}"
    echo -e "${BOLD}${CYAN}════════════════════════════════════════════════════${NC}"
    echo ""
}

section() {
    CURRENT_SECTION="$1"
    local label="$2"
    if ! $MODE_QUIET; then
        echo ""
        echo -e "${BOLD}${BLUE}[$1]${NC} ${BOLD}${WHITE}${label}${NC}"
    fi
    echo "" >> "$LOG_FILE"
    echo "[$1] $label" >> "$LOG_FILE"
}

result_pass() {
    TOTAL_PASS=$((TOTAL_PASS + 1))
    local id="$1" msg="$2"
    echo "  PASS | $id | $msg" >> "$LOG_FILE"
    if $MODE_VERBOSE && ! $MODE_QUIET; then
        echo -e "  ${GREEN}[PASS]${NC} ${msg}"
    fi
    json_add "$id" "PASS" "$msg" 0
}

result_info() {
    TOTAL_INFO=$((TOTAL_INFO + 1))
    local id="$1" msg="$2"
    echo "  INFO | $id | $msg" >> "$LOG_FILE"
    if ! $MODE_QUIET; then
        echo -e "  ${CYAN}[INFO]${NC} ${msg}"
    fi
    json_add "$id" "INFO" "$msg" 0
}

result_warn() {
    TOTAL_WARN=$((TOTAL_WARN + 1))
    SCORE=$((SCORE - 2))
    local id="$1" msg="$2"
    echo "  WARN | $id | $msg" >> "$LOG_FILE"
    if ! $MODE_QUIET; then
        echo -e "  ${YELLOW}[WARN]${NC} ${msg}"
    fi
    json_add "$id" "WARN" "$msg" 2
}

result_fail() {
    TOTAL_FAIL=$((TOTAL_FAIL + 1))
    SCORE=$((SCORE - 5))
    local id="$1" msg="$2"
    echo "  FAIL | $id | $msg" >> "$LOG_FILE"
    echo -e "  ${RED}[FAIL]${NC} ${msg}"
    json_add "$id" "FAIL" "$msg" 5
}

result_critical() {
    TOTAL_CRITICAL=$((TOTAL_CRITICAL + 1))
    SCORE=$((SCORE - 10))
    local id="$1" msg="$2"
    echo "  CRIT | $id | $msg" >> "$LOG_FILE"
    echo -e "  ${RED}${BOLD}[CRITICAL]${NC} ${msg}"
    json_add "$id" "CRITICAL" "$msg" 10
}

result_skip() {
    TOTAL_SKIP=$((TOTAL_SKIP + 1))
    local id="$1" msg="$2"
    echo "  SKIP | $id | $msg" >> "$LOG_FILE"
    if $MODE_VERBOSE && ! $MODE_QUIET; then
        echo -e "  ${GRAY}[SKIP]${NC} ${msg}"
    fi
}

RAW_RESULTS=()
json_add() {
    local id="$1" severity="$2" message="$3" points="$4"
    local escaped_msg
    escaped_msg=$(echo "$message" | sed 's/"/\\"/g')
    JSON_RESULTS+=("{\"id\":\"$id\",\"section\":\"$CURRENT_SECTION\",\"severity\":\"$severity\",\"message\":\"$escaped_msg\",\"points\":$points}")
    RAW_RESULTS+=("${id}	${CURRENT_SECTION}	${severity}	${message}	${points}")
}

get_grade() {
    local s=$1
    if [ $s -lt 0 ]; then s=0; fi
    if [ $s -ge 90 ]; then echo "A"
    elif [ $s -ge 75 ]; then echo "B"
    elif [ $s -ge 60 ]; then echo "C"
    elif [ $s -ge 40 ]; then echo "D"
    else echo "F"
    fi
}

get_grade_color() {
    local grade="$1"
    case "$grade" in
        A) echo "${GREEN}" ;;
        B) echo "${CYAN}" ;;
        C) echo "${YELLOW}" ;;
        D) echo "${RED}" ;;
        F) echo "${RED}${BOLD}" ;;
    esac
}

print_summary() {
    if [ $SCORE -lt 0 ]; then SCORE=0; fi
    local grade
    grade=$(get_grade $SCORE)
    local grade_color
    grade_color=$(get_grade_color "$grade")

    echo "" >> "$LOG_FILE"
    echo "════════════════════════════════════════════" >> "$LOG_FILE"
    echo " SCORE: ${SCORE}/100 (Grade ${grade})" >> "$LOG_FILE"
    echo " CRITICAL: $TOTAL_CRITICAL | FAIL: $TOTAL_FAIL | WARN: $TOTAL_WARN | PASS: $TOTAL_PASS | INFO: $TOTAL_INFO | SKIP: $TOTAL_SKIP" >> "$LOG_FILE"
    echo " Log: $LOG_FILE" >> "$LOG_FILE"
    echo "════════════════════════════════════════════" >> "$LOG_FILE"

    echo ""
    echo -e "${BOLD}${CYAN}════════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}${WHITE} SCORE: ${grade_color}${SCORE}/100 (Grade ${grade})${NC}"
    echo -e "${BOLD}${CYAN}════════════════════════════════════════════════════${NC}"
    echo -e " ${RED}${BOLD}CRITICAL:${NC} ${TOTAL_CRITICAL}  |  ${RED}FAIL:${NC} ${TOTAL_FAIL}  |  ${YELLOW}WARN:${NC} ${TOTAL_WARN}  |  ${GREEN}PASS:${NC} ${TOTAL_PASS}  |  ${CYAN}INFO:${NC} ${TOTAL_INFO}"
    if [ $TOTAL_SKIP -gt 0 ]; then
        echo -e " ${GRAY}SKIPPED:${NC} ${TOTAL_SKIP}"
    fi
    echo -e "${BOLD}${CYAN}════════════════════════════════════════════════════${NC}"
    echo -e " ${GRAY}Full log: ${LOG_FILE}${NC}"

    if $MODE_JSON; then
        local json_file="${LOG_FILE%.log}.json"
        write_json_report "$json_file"
        echo -e " ${GRAY}JSON report: ${json_file}${NC}"
    fi

    if $MODE_HTML; then
        local html_file="${LOG_FILE%.log}.html"
        write_html_report "$html_file"
        echo -e " ${GRAY}HTML report: ${html_file}${NC}"
    fi
    
    if $MODE_MD; then
        local md_file="${LOG_FILE%.log}.md"
        write_markdown_report "$md_file"
        echo -e " ${GRAY}Markdown report: ${md_file}${NC}"
    fi

    # Native HestiaCP System Log Integration
    if [ -x /usr/local/hestia/bin/v-log-action ]; then
        local hestia_level="Info"
        if [ "$grade" = "C" ] || [ "$grade" = "D" ]; then hestia_level="Warning"; fi
        if [ "$grade" = "F" ]; then hestia_level="Error"; fi
        /usr/local/hestia/bin/v-log-action "system" "$hestia_level" "System" "Security Audit Score: $SCORE/100 (Grade $grade). Details: $LOG_FILE" 2>/dev/null || true
    fi

    if [ -n "$MODE_EMAIL" ]; then
        send_email_report
    fi

    echo -e "${BOLD}${CYAN}════════════════════════════════════════════════════${NC}"
    echo ""
}

send_email_report() {
    local target_email="$MODE_EMAIL"
    if [ "$target_email" = "auto" ]; then
        target_email=$(grep "^CONTACT=" /usr/local/hestia/conf/hestia.conf 2>/dev/null | cut -d"'" -f2)
        if [ -z "$target_email" ]; then
            echo -e " ${RED}[FAIL] Could not auto-detect admin email for reporting.${NC}"
            return 1
        fi
    fi

    local hostname=$(hostname -f 2>/dev/null || echo "Server")
    local subject="[Security Audit] $SCORE/100 (Grade $(get_grade $SCORE)) - $hostname"
    
    if $MODE_HTML; then
        local html_file="${LOG_FILE%.log}.html"
        if [ -f "$html_file" ]; then
            {
                echo "To: $target_email"
                echo "Subject: $subject"
                echo "Content-Type: text/html; charset=UTF-8"
                echo "MIME-Version: 1.0"
                echo ""
                cat "$html_file"
            } | /usr/sbin/sendmail -t "$target_email" 2>/dev/null
            echo -e " ${GREEN}[OK] HTML Email report sent to $target_email${NC}"
            return 0
        fi
    fi
    
    local body="Security Audit Report for $hostname"
    body+=$'\n'"Score: $SCORE/100 (Grade $(get_grade $SCORE))"
    body+=$'\n\n'"CRITICAL: $TOTAL_CRITICAL | FAIL: $TOTAL_FAIL | WARN: $TOTAL_WARN"
    body+=$'\n'"See full log at $LOG_FILE on the server."
    body+=$'\n\n'"Detailed Findings (Critical/Fail only):"
    
    local has_issues=false
    for row in "${RAW_RESULTS[@]}"; do
        IFS=$'\t' read -r r_id r_sec r_sev r_msg r_pts <<< "$row"
        if [ "$r_sev" = "CRITICAL" ] || [ "$r_sev" = "FAIL" ] || [ "$r_sev" = "WARN" ]; then
            body+=$'\n'"[$r_sev] $r_sec: $r_msg"
            has_issues=true
        fi
    done
    
    if [ "$has_issues" = false ]; then
        body+=$'\n'"No major issues found. System is secure."
    fi

    local SENDMAIL="/usr/local/hestia/web/inc/mail-wrapper.php"
    if [ -f "$SENDMAIL" ]; then
        echo "$body" | "$SENDMAIL" -s "$subject" "$target_email" 2>/dev/null
    else
        { echo "Subject: $subject"; echo ""; echo "$body"; } | /usr/sbin/sendmail "$target_email" 2>/dev/null
    fi
    echo -e " ${GREEN}[OK] Email report sent to $target_email${NC}"
}

write_json_report() {
    local outfile="$1"
    {
        echo "{"
        echo "  \"tool\": \"v-security-audit\","
        echo "  \"version\": \"${TOOL_VERSION}\","
        echo "  \"date\": \"$(date -Iseconds)\","
        echo "  \"hostname\": \"$(hostname)\","
        echo "  \"score\": $SCORE,"
        echo "  \"grade\": \"$(get_grade $SCORE)\","
        echo "  \"summary\": {"
        echo "    \"critical\": $TOTAL_CRITICAL,"
        echo "    \"fail\": $TOTAL_FAIL,"
        echo "    \"warn\": $TOTAL_WARN,"
        echo "    \"pass\": $TOTAL_PASS,"
        echo "    \"info\": $TOTAL_INFO,"
        echo "    \"skip\": $TOTAL_SKIP"
        echo "  },"
        echo "  \"results\": ["
        local first=true
        for r in "${JSON_RESULTS[@]}"; do
            if $first; then first=false; else echo ","; fi
            echo -n "    $r"
        done
        echo ""
        echo "  ]"
        echo "}"
    } > "$outfile"
}

write_markdown_report() {
    local outfile="$1"
    {
        echo "# Security Audit Report: $(hostname)"
        echo "**Date:** $(date) | **Version:** v${TOOL_VERSION}"
        echo ""
        echo "## Final Score: $SCORE/100 (Grade $(get_grade $SCORE))"
        echo ""
        echo "### Summary"
        echo "- **CRITICAL:** $TOTAL_CRITICAL"
        echo "- **FAIL:** $TOTAL_FAIL"
        echo "- **WARN:** $TOTAL_WARN"
        echo "- **PASS:** $TOTAL_PASS"
        echo "- **INFO:** $TOTAL_INFO"
        echo ""
        echo "### Detailed Findings"
        echo "| Section | Severity | ID | Message |"
        echo "|---|---|---|---|"
        for row in "${RAW_RESULTS[@]}"; do
            IFS=$'\t' read -r r_id r_sec r_sev r_msg r_pts <<< "$row"
            echo "| $r_sec | **$r_sev** | $r_id | $r_msg |"
        done
    } > "$outfile"
}

write_html_report() {
    local outfile="$1"
    local grade_color="#10b981" # Green
    local grade=$(get_grade $SCORE)
    if [ "$grade" = "C" ] || [ "$grade" = "D" ]; then grade_color="#f59e0b"; fi
    if [ "$grade" = "F" ]; then grade_color="#ef4444"; fi

    {
        cat <<EOF
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Security Audit - $(hostname)</title>
    <style>
        :root { --bg: #0f172a; --card: #1e293b; --text: #f8fafc; --muted: #94a3b8; --border: #334155; }
        body { font-family: -apple-system, system-ui, sans-serif; background: var(--bg); color: var(--text); padding: 2rem; margin: 0; line-height: 1.6; }
        .container { max-width: 1000px; margin: 0 auto; }
        header { border-bottom: 2px solid var(--border); padding-bottom: 1rem; margin-bottom: 2rem; display: flex; justify-content: space-between; align-items: center; }
        h1 { margin: 0; color: #38bdf8; }
        .score-box { background: var(--card); padding: 1.5rem 3rem; border-radius: 12px; border: 2px solid $grade_color; text-align: center; }
        .score-value { font-size: 3rem; font-weight: 800; color: $grade_color; line-height: 1; }
        .score-grade { font-size: 1.2rem; font-weight: 600; color: var(--muted); margin-top: 0.5rem; }
        .summary-grid { display: grid; grid-template-columns: repeat(5, 1fr); gap: 1rem; margin-bottom: 2rem; }
        .stat-card { background: var(--card); padding: 1rem; border-radius: 8px; text-align: center; border: 1px solid var(--border); }
        .stat-value { font-size: 1.8rem; font-weight: 700; }
        .text-crit { color: #f43f5e; } .text-fail { color: #ef4444; } .text-warn { color: #f59e0b; } .text-pass { color: #10b981; } .text-info { color: #38bdf8; }
        table { width: 100%; border-collapse: collapse; margin-top: 2rem; background: var(--card); border-radius: 8px; overflow: hidden; }
        th, td { padding: 1rem; text-align: left; border-bottom: 1px solid var(--border); }
        th { background: rgba(0,0,0,0.2); font-weight: 600; color: var(--muted); text-transform: uppercase; font-size: 0.85rem; }
        tr:last-child td { border-bottom: none; }
        .tag { font-size: 0.75rem; font-weight: 700; padding: 0.25rem 0.6rem; border-radius: 99px; display: inline-block; }
        .tag-CRITICAL { background: rgba(244, 63, 94, 0.2); color: #f43f5e; border: 1px solid #f43f5e; }
        .tag-FAIL { background: rgba(239, 68, 68, 0.2); color: #ef4444; border: 1px solid #ef4444; }
        .tag-WARN { background: rgba(245, 158, 11, 0.2); color: #f59e0b; border: 1px solid #f59e0b; }
        .tag-PASS { background: rgba(16, 185, 129, 0.2); color: #10b981; border: 1px solid #10b981; }
        .tag-INFO { background: rgba(56, 189, 248, 0.2); color: #38bdf8; border: 1px solid #38bdf8; }
        .tag-SKIP { background: rgba(148, 163, 184, 0.2); color: #94a3b8; border: 1px solid #94a3b8; }
    </style>
</head>
<body>
    <div class="container">
        <header>
            <div>
                <h1>Security Audit Report</h1>
                <p style="color: var(--muted); margin: 0.5rem 0 0 0;">Generated on $(date) | Target: <strong>$(hostname)</strong></p>
            </div>
            <div class="score-box">
                <div class="score-value">${SCORE}/100</div>
                <div class="score-grade">GRADE $grade</div>
            </div>
        </header>

        <div class="summary-grid">
            <div class="stat-card"><div class="stat-value text-crit">$TOTAL_CRITICAL</div><div style="font-size: 0.85rem; color: var(--muted);">CRITICAL</div></div>
            <div class="stat-card"><div class="stat-value text-fail">$TOTAL_FAIL</div><div style="font-size: 0.85rem; color: var(--muted);">FAILED</div></div>
            <div class="stat-card"><div class="stat-value text-warn">$TOTAL_WARN</div><div style="font-size: 0.85rem; color: var(--muted);">WARNINGS</div></div>
            <div class="stat-card"><div class="stat-value text-pass">$TOTAL_PASS</div><div style="font-size: 0.85rem; color: var(--muted);">PASSED</div></div>
            <div class="stat-card"><div class="stat-value text-info">$TOTAL_INFO</div><div style="font-size: 0.85rem; color: var(--muted);">INFO</div></div>
        </div>

        <table>
            <thead>
                <tr>
                    <th style="width: 15%">Severity</th>
                    <th style="width: 25%">Section</th>
                    <th>Message</th>
                </tr>
            </thead>
            <tbody>
EOF
    } > "$outfile"

    for row in "${RAW_RESULTS[@]}"; do
        IFS=$'\t' read -r r_id r_sec r_sev r_msg r_pts <<< "$row"
        echo "                <tr>" >> "$outfile"
        echo "                    <td><span class=\"tag tag-${r_sev}\">${r_sev}</span></td>" >> "$outfile"
        echo "                    <td style=\"color: var(--muted); font-size: 0.9rem;\">${r_sec}</td>" >> "$outfile"
        echo "                    <td>${r_msg}</td>" >> "$outfile"
        echo "                </tr>" >> "$outfile"
    done

    cat <<EOF >> "$outfile"
            </tbody>
        </table>
        <footer style="margin-top: 3rem; text-align: center; color: var(--muted); font-size: 0.85rem;">
            Generated by HestiaCP v-security-audit Tool v${TOOL_VERSION}
        </footer>
    </div>
</body>
</html>
EOF
}

check_root() {
    if [ "$(id -u)" -ne 0 ]; then
        echo -e "${RED}[ERROR]${NC} This tool must be run as root."
        exit 1
    fi
}

hestia_user_list() {
    if [ -d /usr/local/hestia/data/users ]; then
        for u in /usr/local/hestia/data/users/*/; do
            basename "$u"
        done
    fi
}

hestia_domain_list() {
    local user="$1"
    local web_conf="/usr/local/hestia/data/users/${user}/web.conf"
    if [ -f "$web_conf" ]; then
        grep "^DOMAIN=" "$web_conf" | cut -d"'" -f2
    fi
}

is_service_active() {
    systemctl is-active --quiet "$1" 2>/dev/null
}

command_exists() {
    command -v "$1" &>/dev/null
}

file_age_days() {
    local file="$1"
    if [ ! -f "$file" ]; then echo 9999; return; fi
    local now file_mod
    now=$(date +%s)
    file_mod=$(stat -c %Y "$file" 2>/dev/null || echo 0)
    echo $(( (now - file_mod) / 86400 ))
}

parse_sshd_config() {
    local key="$1"
    local val
    val=$(grep -iE "^\s*${key}\s+" /etc/ssh/sshd_config 2>/dev/null | tail -1 | awk '{print $2}')
    echo "${val:-__unset__}"
}

is_more_permissive_than() {
    local current="$1" target="$2"
    local cu=$((8#$current)) tu=$((8#$target))
    [ $((cu & ~tu)) -ne 0 ]
}
