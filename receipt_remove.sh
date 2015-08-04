#!/bin/bash
# First jamf input is receipt name
receiptName="$4"
rm "/Library/Application Support/JAMF/Receipts/${receiptName}"
jamf recon
exit 0