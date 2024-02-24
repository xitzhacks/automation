#!/bin/bash

# Function to perform subdomain enumeration for a single domain
enumerate_single_domain() {
    domain="$1"
    echo "Enumerating subdomains for $domain..."
    
    # Run subfinder to enumerate subdomains for the provided domain
    subfinder -d "$domain" | tee "$domain.txt"

    # Use httpx to find live subdomains
    echo "Finding live subdomains for $domain..."
    cat "$domain.txt" | httpx -silent >> "${domain}_live.txt"
    
    echo "Subdomain enumeration and live subdomain discovery for $domain complete. Results saved to $domain.txt and ${domain}_live.txt"
}

# Function to perform subdomain enumeration for domains listed in a file
enumerate_domains_in_file() {
    file="$1"
    echo "Enumerating subdomains for domains listed in $file..."
    
    # Loop through each domain listed in the file
    while IFS= read -r domain; do
        echo "Enumerating subdomains for $domain..."
        
        # Run subfinder to enumerate subdomains for the current domain
        subfinder -d "$domain" | tee -a "${file}_results.txt"

        # Use httpx to find live subdomains
        echo "Finding live subdomains for $domain..."
        cat "${domain}_results.txt" | httpx -silent >> "${domain}_live.txt"
        
        echo "Subdomain enumeration and live subdomain discovery for $domain complete."
    done < "$file"
    
    echo "Subdomain enumeration for domains listed in $file complete."
}

# Function to find URLs using waybackurls for each live subdomain
find_urls_from_live_subdomains() {
    domain="$1"
    echo "Finding URLs from live subdomains for $domain..."

    # Use waybackurls to find URLs for each live subdomain
    cat "${domain}_live.txt" | waybackurls > "${domain}_urls.txt"
    
    echo "URL discovery from live subdomains for $domain complete. Results saved to ${domain}_urls.txt"
}

# Using GF tools to get URLS 

extract_vulnerability_urls() {
    domain="$1"
    echo "Extracting URLs for vulnerabilities from $domain..."

    # Use GF (GrepFuzz) to extract URLs for various vulnerabilities
    gf xss "${domain}_urls.txt" | tee "${domain}_xss.txt"
    gf sqli "${domain}_urls.txt" | tee "${domain}_sqli.txt"
    gf lfi "${domain}_urls.txt" | tee "${domain}_lfi.txt"
    gf redirect "${domain}_urls.txt" | tee "${domain}_redirect.txt"

    echo "URL extraction for vulnerabilities from $domain complete."
}

# Check if no arguments are provided
if [ $# -eq 0 ]; then
    echo "Usage: $0 <domain | file>"
    exit 1
fi

# Main script execution

# Check if subfinder, httpx, and waybackurls are installed
if ! command -v subfinder &> /dev/null || ! command -v httpx &> /dev/null || ! command -v waybackurls &> /dev/null || ! command -v gf &> /dev/null; then
    echo "Error: Required tools (subfinder, httpx, waybackurls , gf) are not installed. Please install them and make sure they're in your PATH."
    exit 1
fi

# Check if the input is a single domain or a file
if [ -f "$1" ]; then
    enumerate_domains_in_file "$1"
    # Iterate over each domain in the file and find URLs from live subdomains
    while IFS= read -r domain; do
        find_urls_from_live_subdomains "$domain"
    done < "$1"
else
    enumerate_single_domain "$1"
    # Find URLs from live subdomains for the single domain
    find_urls_from_live_subdomains "$1"
    extract_vulnerability_urls "$1"
fi

