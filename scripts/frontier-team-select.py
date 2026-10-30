#!/usr/bin/env python3
"""Select actually advertised Claude and Codex T3 provider instance/model IDs."""
import json,sys
from pathlib import Path
data=json.loads(Path(sys.argv[1]).read_text())
providers=data.get("providers",[])
results=[]
for name in ("claude","codex"):
    matches=[p for p in providers if name in str(p.get("driverKind","")).lower() and p.get("models")]
    if not matches:
        print("NOT READY: {} provider missing or has no models".format(name),file=sys.stderr)
        for p in providers:
            print("  {} ({}) models={} constraints={}".format(
                p.get("providerInstanceId"),p.get("driverKind"),
                len(p.get("models",[])),p.get("constraints",[])),file=sys.stderr)
        sys.exit(2)
    provider=next((p for p in matches if p.get("providerInstanceId")==name),matches[0])
    results.extend((provider["providerInstanceId"],provider["models"][0]["id"]))
Path(sys.argv[2]).write_text("\n".join(results)+"\n")
