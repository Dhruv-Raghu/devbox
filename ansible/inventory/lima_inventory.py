#!/usr/bin/env python3
"""Future Lima dynamic inventory entry point.

This intentionally returns an empty inventory during scaffold phase. The final
implementation must use Lima-supported connection information, maintain a
per-instance known_hosts file under .runtime/, and never disable host-key
checking.
"""

import json
import sys


def main() -> int:
    if "--list" in sys.argv:
        print(json.dumps({"_meta": {"hostvars": {}}, "devbox": {"hosts": []}}))
        return 0
    if "--host" in sys.argv:
        print(json.dumps({}))
        return 0
    print("Usage: lima_inventory.py --list", file=sys.stderr)
    return 2


if __name__ == "__main__":
    raise SystemExit(main())
