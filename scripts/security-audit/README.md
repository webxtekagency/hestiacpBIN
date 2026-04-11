# v-security-audit — HestiaCP Security Audit Tool

A comprehensive, zero-dependency security auditing tool for HestiaCP servers. Scans system hardening, per-domain file-level security, and external HTTP attack surfaces — producing a scored report with actionable findings.

Inspired by [Lynis](https://cisofy.com/lynis/), [testssl.sh](https://testssl.sh/), and the Webxtek Security Skill. Purpose-built for HestiaCP's architecture on Debian/Ubuntu.

---

## The Problem

Servers accumulate security debt over time through:
- Default SSH configs left unchanged after installation
- Fail2Ban jails not covering all attack vectors
- CMS plugins writing backdoors or leaving debug files
- `777` permissions from manual fixes or broken auto-updates
- Missing HTTP security headers exposing visitors to XSS/clickjacking
- Expired SSL certificates or legacy TLS 1.0/1.1 still enabled
- Database admin panels (adminer.php) forgotten in `public_html`
- PHP malware hiding in `.ico` files or `wp-content/uploads/`

Most sysadmins only discover these issues **after** a breach. This tool surfaces them **before** attackers do.

---

## Modular Architecture

The tool is highly modular to allow infinite scaling without bloating. Core tests are separated into `lib/system/`, `lib/backend/`, `lib/frontend/`, and `lib/pentest/`, where each folder contains multiple targeted files instead of a single massive bash script.

---

## Scan Layers

### Layer 1: `--system` (OS & Service Hardening)
Audits the server infrastructure as root. Independent of any website.

| Category | Checks |
|---|---|
| Kernel & OS | Supported OS, kernel updates, pending reboot, auto-updates |
| SSH Hardening | Root login, password auth, port, max tries, idle timeout |
| Firewall & Fail2Ban | Service status, SSH/recidive jails, HestiaCP firewall, open ports |
| HestiaCP Panel | Port, SSL certificate, admin 2FA, session timeout, version |
| Services | Nginx, PHP-FPM, MariaDB status, root process detection |
| Database | Root auth method, anonymous users, remote root access, test DB |
| Mail | Open relay, ClamAV freshness, DKIM, SPF records |
| Kernel Hardening | ASLR, SYN cookies, IP forwarding, ICMP redirects, source routing, core dumps |
| Filesystem Security | /etc/shadow & /etc/passwd perms, /tmp mount options, sticky bit, Hestia bin/ integrity, crontab perms |
| User Accounts | UID 0 audit, empty passwords, login shell count, password policy, NTP sync, AppArmor |
| DNS & Mail Advanced | DMARC records, hostname resolution |

### Layer 2: `--backend` (Per-Domain File-Level Scan)
Scans the filesystem inside each domain's `public_html/`. Detects malware, leaked credentials, dangerous permissions, and CMS misconfiguration.

| Category | Checks |
|---|---|
| File Exposure | `.env`, `.git/`, SQL dumps, config backups, debug files, private keys, adminer.php, Docker/composer/npm files |
| PHP Malware | `eval(base64_decode())`, webshell signatures, PHP in uploads, cron injection, ClamAV directory-level scanner |
| CMS Hardening | WordPress (wp-config perms, debug.log, file editing, table prefix, upload execution), Laravel (APP_DEBUG, APP_KEY), Drupal, Joomla, Magento, PrestaShop config permissions |
| Permissions | World-writable items, ownership mismatch, SUID/SGID binaries, executable uploads, .htpasswd perms |
| Integrity | .user.ini abuse (auto_prepend), recently modified PHP, hidden files, timthumb.php, symlinks outside home, large file dumps, error logs in public_html |

### Layer 3: `--frontend` (External HTTP/HTTPS Scan)
Simulates an external attacker probing the website via HTTP. Uses only `curl` and `openssl`.

| Category | Checks |
|---|---|
| SSL/TLS | Certificate validity, chain completeness, TLS 1.0/1.1 disabled, HSTS, HTTP/2, OCSP stapling |
| Security Headers | X-Frame-Options, X-Content-Type-Options, CSP, Permissions-Policy, Referrer-Policy, debug headers |
| Info Disclosure | `.env`/`.git`/`wp-config.php` accessible, path traversal, PHP errors, directory listing, generator meta tag |
| WordPress-Specific | xmlrpc.php, REST API user enumeration, ?author= enumeration, wp-login.php exposure, wp-cron.php abuse |
| Cookies | HttpOnly, Secure, SameSite flags on session cookies |
| Misconfiguration | Open redirects, robots.txt sensitive paths, CORS wildcards, CAA DNS, mixed content, backup paths |

### Layer 4: `--pentest` (Offensive Self-Attack Simulation)
Simulates a real hacker attacking the website. Actively attempts exploitation using `curl`, `openssl`, `dig`, and `nc`.

| Category | Checks |
|---|---|
| SQL Injection | Error-based, time-based blind, parameter fuzzing across GET params |
| XSS | Reflected via query/search/UA/referer headers, SSTI detection |
| LFI/RFI | 9 payloads × 7 params (path traversal, null byte, php:// wrappers, double encoding) |
| Command Injection | GET + POST with `;id`, `\|id`, `$(id)` across common params, phpinfo.php check |
| Auth Attacks | Admin panel discovery (12 paths), default credential testing, WP user enumeration |
| HTTP Methods | TRACE (XST), PUT (file write), DELETE, OPTIONS, verb tampering |
| Header Injection | CRLF (URL + params), Host poisoning, X-Forwarded-Host reflection, XFF bypass |
| SSRF | Internal IPs + cloud metadata endpoints × 6 params |
| Brute-Force | Login rate-limit test (10 attempts), XMLRPC multicall amplification |
| Upload Bypass | Directory listing, alternative PHP extensions (.phtml/.php5/.phar) |
| Rate Limiting | 20-request flood test, REST API throttle test |
| XXE | XML entity injection via root, xmlrpc.php, and SOAP endpoints |
| WAF Evasion | WAF detection + 5 encoding-based bypass attempts |
| Backup Fuzzing | 73 paths: `.bak`, `.old`, `.swp`, `.sql`, `.zip`, `.git`, `.svn`, SSH keys, IDE files |
| Error Disclosure | Null bytes, array injection, 404/500 info leakage, stack traces |
| Session Attacks | Session fixation, password reset poisoning via Host header |
| Parameter Tampering | HTTP Parameter Pollution, verb tampering, IDOR via REST API user IDs |
| WordPress Deep | install.php, upgrade.php, registration, AJAX auth, plugin/theme listing, vulnerable plugin paths |
| DNS Attacks | Zone transfer (AXFR), subdomain enumeration (22 common), CNAME takeover |
| Cache Poisoning | X-Forwarded-Host reflection + cache header detection, HTTP request smuggling (CL+TE) |
| Clickjacking | Frame protection on root + form pages |
| Exposed Services | Redis (6379), Memcached (11211), Elasticsearch (9200), MongoDB (27017), MySQL (3306) |

---

## Usage

```bash
v-security-audit --system                           # OS & services only
v-security-audit --backend                          # All users, all domains
v-security-audit --backend johndoe               # All domains for one user
v-security-audit --backend johndoe example.com   # Single domain
v-security-audit --frontend https://example.com     # External scan (any URL)
v-security-audit --frontend johndoe              # All domains for one user
v-security-audit --pentest https://example.com      # Offensive self-attack
v-security-audit --pentest johndoe               # Pentest all user domains
v-security-audit --all                              # Full audit (all 4 layers)
v-security-audit --all johndoe                   # Full audit for one user
```

### Options

| Flag | Description |
|---|---|
| `--json` | Output results as JSON |
| `--quiet` | Only show FAIL and CRITICAL |
| `--verbose` | Show all checks including PASS |
| `--no-color` | Disable ANSI colours |
| `--skip-ssl` | Skip SSL/TLS checks |
| `--skip-malware` | Skip PHP malware scan (faster) |

---

## Scoring

| Severity | Points | Meaning |
|---|---|---|
| CRITICAL | -10 | Actively exploitable vulnerability |
| FAIL | -5 | Security gap, fix soon |
| WARN | -2 | Suboptimal, recommended to fix |
| INFO | 0 | Informational |
| PASS | 0 | Check passed |

| Score | Grade | Status |
|---|---|---|
| 90–100 | A | Production-hardened |
| 75–89 | B | Minor improvements needed |
| 60–74 | C | Several gaps to address |
| 40–59 | D | Significant risk |
| 0–39 | F | Actively vulnerable |

---

## Installation

```bash
chmod +x /root/hestiacp-useful-tools/scripts/security-audit/v-security-audit
ln -sf /root/hestiacp-useful-tools/scripts/security-audit/v-security-audit /usr/local/hestia/bin/v-security-audit
```

### Optional Dependencies

| Tool | Purpose | Install |
|---|---|---|
| `dig` | DNS checks (SPF, DKIM) | `apt install dnsutils` |
| `jq` | JSON formatting | `apt install jq` |
| `wp-cli` | WordPress user audit | Manual install |

---

## OS Compatibility

| OS | Version | Status |
|---|---|---|
| Debian | 11 (Bullseye) | Supported |
| Debian | 12 (Bookworm) | Primary target |
| Ubuntu | 20.04 LTS | Supported |
| Ubuntu | 22.04 LTS | Supported |
| Ubuntu | 24.04 LTS | Supported |

---

## OWASP Top 10:2025 Coverage

| OWASP Category | Our Checks |
|---|---|
| A01 — Broken Access Control | Path traversal, file disclosure, user enumeration, SUID |
| A02 — Security Misconfiguration | Headers, open ports, directory listing, PHP errors |
| A03 — Supply Chain | Exposed composer/npm files, package updates |
| A04 — Cryptographic Failures | SSL/TLS, HSTS, cookie security, private key exposure |
| A05 — Injection | PHP malware, eval patterns, webshells |
| A06 — Insecure Design | Admin 2FA, file editing, user separation |
| A07 — Auth Failures | SSH config, DB auth, cookie flags |
| A08 — Integrity Failures | Malware, SUID binaries, cron injection |
| A09 — Logging Failures | Fail2Ban, debug.log exposure |
| A10 — Exceptional Conditions | PHP error display, info disclosure |

---

## Recommended Workflow

```bash
# 1. First audit (read-only, always safe)
v-security-audit --all --verbose

# 2. Fix critical issues first
v-security-audit --all --quiet  # shows only FAIL/CRITICAL

# 3. Weekly cron (email report)
# 0 3 * * 1 /usr/local/hestia/bin/v-security-audit --all --json --quiet --no-color >> /var/log/hestia/security-audit/weekly.log 2>&1
```

---

## Disclaimer

This tool performs **read-only** audits. It never modifies files, changes permissions, or alters configurations. However, the frontend scan sends HTTP requests to your domains — ensure you have authorization before scanning external targets.
