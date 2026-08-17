#!/usr/bin/env bash
set -euo pipefail

echo "Fortress OS leak-test checklist"
echo
echo "1. Verify the application namespace has no default route to the WAN."
echo "2. Verify direct TCP connections from the application namespace fail."
echo "3. Verify DNS requests cannot leave except through the Tor path."
echo "4. Stop Tor and verify application networking becomes unavailable."
echo "5. Start Tor and verify traffic resumes through the intended path."
echo
echo "Automated packet-capture assertions will be added in the networking milestone."
