#!/bin/sh
# Prints the UDID of the first connected physical iPhone.
OUT=$(mktemp)
trap 'rm -f "$OUT"' EXIT
xcrun devicectl list devices --json-output "$OUT" >/dev/null 2>&1
python3 - "$OUT" <<'PY'
import json, sys
devices = json.load(open(sys.argv[1]))["result"]["devices"]
for d in devices:
    hw, conn = d.get("hardwareProperties", {}), d.get("connectionProperties", {})
    if hw.get("reality") == "physical" and hw.get("deviceType") == "iPhone" \
            and conn.get("tunnelState") != "unavailable":
        print(hw["udid"])
        sys.exit(0)
sys.stderr.write("No connected iPhone found. Plug it in, unlock it, and tap Trust.\n")
sys.exit(1)
PY
