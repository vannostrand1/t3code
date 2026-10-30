#!/usr/bin/env python3
import json, sys
from pathlib import Path

claude=json.loads(Path(sys.argv[1]).read_text())
codex=json.loads(Path(sys.argv[2]).read_text())
cid=sys.argv[3]
xid=sys.argv[4]
assert claude["thread"]["threadId"]==cid
assert codex["thread"]["threadId"]==xid
assert claude["thread"]["providerInstanceId"]!=codex["thread"]["providerInstanceId"]

def received(items, sender):
    return [i for i in items if i.get("senderThreadId")==sender and i.get("creationSource")=="mcp" and i.get("createdBy")=="agent"]

def answered(items, incoming):
    return bool(incoming) and any(i.get("type")=="assistant_message" and i.get("status")=="completed" and i.get("position",-1)>incoming[0].get("position",-1) for i in items)

ci=claude.get("items",[])
xi=codex.get("items",[])
from_claude=received(xi,cid)
from_codex=received(ci,xid)
checks={"claude_to_codex":bool(from_claude),"codex_to_claude":bool(from_codex),"codex_answer":answered(xi,from_claude),"claude_answer":answered(ci,from_codex),"bounded":len(from_claude)<=2 and len(from_codex)<=2}
status="PASS" if all(checks.values()) else "PENDING"
print(json.dumps({"status":status,"checks":checks,"claudeThread":cid,"codexThread":xid,"claudeProvider":claude["thread"]["providerInstanceId"],"codexProvider":codex["thread"]["providerInstanceId"]},indent=2))
sys.exit(0 if status=="PASS" else 2)
