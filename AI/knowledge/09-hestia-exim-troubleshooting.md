# Exim4 Troubleshooting Guide for HestiaCP

## 1. Quick Diagnostics
**Service Status:**
```bash
systemctl status exim4
```

**Queue Status:**
```bash
exim -bpc  # Count
exim -bp   # List details
```

**Log Analysis (The Source of Truth):**
*   **Received Emails:** `grep "<=" /var/log/exim4/mainlog`
*   **Delivered Emails:** `grep "=>" /var/log/exim4/mainlog`
*   **Failed Emails:** `grep "**" /var/log/exim4/mainlog`
*   **Specific Address:** `exigrep "user@domain.com" /var/log/exim4/mainlog`

**Domain Ownership Lookup:**
To find which HestiaCP user owns a domain (and thus where its config lives):
```bash
/usr/local/hestia/bin/v-search-domain-owner example.com
# Output: username
```

## 2. Common Issues
### "Unroutable address"
*   Check if the domain exists in HestiaCP: `v-list-mail-domains [USER]`
*   Check DNS: `dig +short MX domain.com`

### "Connection refused"
*   Check if Exim is listening: `netstat -plnt | grep :25`
*   Check Firewall: `v-list-firewall`

## 4. Advanced Diagnostics (Rejections & Blocks)

### Why was an email rejected?
Check the `rejectlog` for detailed reasons (SPF, DNSBL, Relay denied):
```bash
grep "user@domain.com" /var/log/exim4/rejectlog
```

### Common Rejection Codes
*   **550 Unrouteable address:** The destination domain is not in HestiaCP or DNS is failing.
*   **550 Relay not permitted:** You are trying to send email *through* this server without authentication.
*   **550 Administrative prohibition:** Blocked by a custom rule or DNSBL.

### Check if IP is Blocked (DNSBL/Blacklist)
If you see "JunkMail rejected" or "SpamAssassin" blocks:
```bash
grep "rejected after DATA" /var/log/exim4/mainlog | grep "user@domain.com"
```

### Trace a Conversation (SMTP Debug)
To see exactly what happened during the SMTP handshake:
```bash
exigrep "user@domain.com" /var/log/exim4/mainlog
```

## 5. Queue Management (Frozen/Stuck Emails)
Sometimes emails get stuck. Here is how to manage them.

**List Frozen Messages:**
```bash
exim -bpr | grep frozen
```

**Force Delivery (Try to send now):**
```bash
exim -M [MESSAGE_ID]
# Example: exim -M 1xQyZz-000000-00
```

**View Message Headers (Who sent it?):**
```bash
exim -Mvh [MESSAGE_ID]
```

**View Message Body (What is inside?):**
```bash
exim -Mvb [MESSAGE_ID]
```

**View Delivery Log (Why is it stuck?):**
```bash
exim -Mvl [MESSAGE_ID]
```

**Remove/Delete a Message:**
```bash
exim -Mrm [MESSAGE_ID]
```

**Remove ALL Frozen Messages (Cleanup):**
```bash
exiqgrep -z -i | xargs exim -Mrm
```

## 6. Spam & Security Analysis
**Find Top Senders (Potential Spammers):**
```bash
exim -bp | awk '{print $4}' | sort | uniq -c | sort -nr | head
```

**Check for Compromised Scripts (PHP Mail):**
Look for emails sent by `www-data` or the user ID, not an SMTP login:
```bash
grep "U=www-data" /var/log/exim4/mainlog | head
```

