#!/bin/bash
# jamf input 1 = receipt name
receiptName="$4"
touch "/Library/Application Support/JAMF/Receipts/${receiptName}"
jamf recon
exit 0