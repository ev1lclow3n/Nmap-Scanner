#!/bin/bash

# Function to check if a tool is installed
check_tool() {
  command -v $1 >/dev/null 2>&1 || { echo "$1 is required but not installed. Exiting."; exit 1; }
}

# Check if required tools are installed
check_tool "dig"
check_tool "nmap"
check_tool "curl"

# Check if a target was provided
if [ -z "$1" ]; then
  # If not, prompt for a target
  read -p "Enter a target domain or IP address: " TARGET
else
  # If one was provided, use it
  TARGET=$1
fi

# Perform domain enumeration with multiple record types
echo "Gathering DNS records for $TARGET..."
dig +short $TARGET
dig $TARGET SOA
dig $TARGET MX
dig $TARGET NS
dig $TARGET TXT

# Perform a more comprehensive port scan (TCP and UDP)
echo "Scanning for open TCP and UDP ports on $TARGET..."
nmap -sS -sU -T4 -A $TARGET

# Perform vulnerability scanning with more checks
echo "Checking for known vulnerabilities on $TARGET..."
nmap -sV --script=vuln $TARGET

# SSL/TLS Configuration Check
echo "Checking SSL/TLS configuration for $TARGET..."
echo | openssl s_client -connect $TARGET:443 2>/dev/null | openssl x509 -noout -text

# Analyze URL parameters and check for SQLi and XSS vulnerabilities
echo "Analyzing URL parameters on $TARGET for potential vulnerabilities..."
PARAMS=$(curl -s http://$TARGET/ | grep -oE '<input type="[^"]+" name="[^"]+"')
if [ ! -z "$PARAMS" ]; then
  echo "Found parameters: $PARAMS"
  echo "Testing for SQL Injection vulnerability..."
  curl -s "http://$TARGET/$PARAMS' OR 1=1--" | grep -i "error"
  echo "Testing for XSS vulnerability..."
  curl -s "http://$TARGET/$PARAMS<script>alert('XSS')</script>" | grep -i "<script>alert('XSS')</script>"
else
  echo "No URL parameters found."
fi

# OS Fingerprinting (OS Detection)
echo "Attempting to detect OS for $TARGET..."
nmap -O $TARGET

# Check for HTTP headers and security configurations
echo "Analyzing HTTP headers for security misconfigurations..."
curl -s -I http://$TARGET | grep -i 'server\|x-frame-options\|strict-transport-security\|content-security-policy\|x-xss-protection\|x-content-type-options'

echo "Scan complete!"
