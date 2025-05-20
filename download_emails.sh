#!/bin/bash

# Function to prompt for input if value is empty
prompt_if_empty() {
    local var_name=$1
    local prompt_text=$2
    local is_password=$3

    if [ -z "${!var_name}" ]; then
        if [ "$is_password" = "true" ]; then
            read -sp "$prompt_text: " input
            echo
        else
            read -p "$prompt_text: " input
        fi
        eval "$var_name='$input'"
    fi
}

# Default values
EMAIL=""
PASSWORD=""
SERVER="secure.emailsrvr.com"  # Default to Rackspace
PORT="993"                     # Default IMAP SSL port

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -e|--email)
            EMAIL="$2"
            shift 2
            ;;
        -p|--password)
            PASSWORD="$2"
            shift 2
            ;;
        -s|--server)
            SERVER="$2"
            shift 2
            ;;
        -P|--port)
            PORT="$2"
            shift 2
            ;;
        -h|--help)
            echo "Usage: $0 [options]"
            echo "Options:"
            echo "  -e, --email EMAIL     Email address"
            echo "  -p, --password PASS   Email password"
            echo "  -s, --server SERVER   IMAP server (default: secure.emailsrvr.com)"
            echo "  -P, --port PORT       IMAP port (default: 993)"
            echo "  -h, --help            Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use -h or --help for usage information"
            exit 1
            ;;
    esac
done

# Prompt for any missing values
prompt_if_empty "EMAIL" "Enter email address" "false"
prompt_if_empty "PASSWORD" "Enter email password" "true"
prompt_if_empty "SERVER" "Enter IMAP server (press Enter for default: secure.emailsrvr.com)" "false"
prompt_if_empty "PORT" "Enter IMAP port (press Enter for default: 993)" "false"

# Create output directory
OUTPUT_DIR="downloaded_emails"
mkdir -p "$OUTPUT_DIR"

echo "Listing available mailboxes..."
echo "----------------------------------------"

# List mailboxes and capture output
MAILBOXES=($(python3 imapgrab3.py -l -S -s "$SERVER" -P "$PORT" -u "$EMAIL" -p "$PASSWORD" | grep -v "IMAP Grab" | grep -v "\-\-\-" | tr -d "b'" | tr -d "'"))

if [ ${#MAILBOXES[@]} -eq 0 ]; then
    echo "Failed to list mailboxes or no mailboxes found. Please check your connection settings."
    exit 1
fi

echo "Found ${#MAILBOXES[@]} mailboxes:"
printf '%s\n' "${MAILBOXES[@]}"
echo "----------------------------------------"
echo "Starting download of mailboxes..."
echo "----------------------------------------"

# Download each mailbox
for mailbox in "${MAILBOXES[@]}"; do
    echo "Downloading mailbox: $mailbox"
    python3 imapgrab3.py -d -S -s "$SERVER" -P "$PORT" -u "$EMAIL" -p "$PASSWORD" -m "$mailbox" -f "$OUTPUT_DIR"

    if [ $? -eq 0 ]; then
        echo "Successfully downloaded $mailbox"
    else
        echo "Failed to download $mailbox"
    fi
    echo "----------------------------------------"
done

echo "Download process completed. Check the $OUTPUT_DIR directory for downloaded mailboxes."
