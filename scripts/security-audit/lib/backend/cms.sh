#!/bin/bash


check_cms_hardening() {
    local docroot="$1" user="$2" domain="$3" cms="$4"
    local project_root
    project_root=$(dirname "$docroot")

    case "$cms" in
        wordpress) check_wordpress "$docroot" "$user" "$domain" ;;
        laravel) check_laravel "$docroot" "$user" "$domain" "$project_root" ;;
        drupal) check_drupal "$docroot" "$user" "$domain" ;;
        joomla) check_joomla "$docroot" "$user" "$domain" ;;
        magento) check_magento "$docroot" "$user" "$domain" "$project_root" ;;
        prestashop) check_prestashop "$docroot" "$user" "$domain" ;;
    esac
}



