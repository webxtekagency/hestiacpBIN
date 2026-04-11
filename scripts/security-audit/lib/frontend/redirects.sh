#!/bin/bash


check_redirects() {
    local url="$1" domain="$2"

    local redirect_test
    redirect_test=$(curl -sI -m 5 "${url}/?redirect=https://evil.com" 2>/dev/null)
    local redirect_loc
    redirect_loc=$(echo "$redirect_test" | grep -i "^location:" | tr -d '\r')
    if echo "$redirect_loc" | grep -qi "evil.com"; then
        result_fail "F31" "Open redirect vulnerability detected [${domain}]"
    else
        result_pass "F31" "No open redirect found [${domain}]"
    fi

    local robots
    robots=$(curl -s -m 5 "${url}/robots.txt" 2>/dev/null)
    if echo "$robots" | grep -qiE "Disallow:.*(admin|backup|config|database|install|private|secret)"; then
        result_warn "F32" "robots.txt reveals sensitive paths [${domain}]"
    else
        result_pass "F32" "robots.txt clean (no sensitive paths exposed) [${domain}]"
    fi

    local sitemap_status
    sitemap_status=$(curl -sI -m 5 "${url}/sitemap.xml" 2>/dev/null | head -1 | awk '{print $2}')
    if [ "$sitemap_status" = "200" ]; then
        result_pass "F33" "sitemap.xml is accessible [${domain}]"
    else
        result_info "F33" "No sitemap.xml found [${domain}]"
    fi

    local cors_test
    cors_test=$(curl -sI -m 5 -H "Origin: https://evil.com" "${url}/" 2>/dev/null | grep -i "^access-control-allow-origin:" | tr -d '\r')
    if echo "$cors_test" | grep -q "\*"; then
        result_warn "F34" "CORS allows any origin (Access-Control-Allow-Origin: *) [${domain}]"
    elif echo "$cors_test" | grep -qi "evil.com"; then
        result_fail "F34" "CORS reflects arbitrary origin [${domain}]"
    else
        result_pass "F34" "CORS properly configured [${domain}]"
    fi
}



