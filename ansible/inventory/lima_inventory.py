#!/usr/bin/env python3
"""Dynamic inventory for a named Lima instance on the controller host."""

import json
import os
import subprocess
import sys
from pathlib import Path


def fail(message: str) -> None:
    print(message, file=sys.stderr)
    raise SystemExit(2)


def instance() -> dict:
    name = os.environ.get("DEVBOX_INSTANCE")
    if not name:
        fail("DEVBOX_INSTANCE is required")
    result = subprocess.run(
        ["limactl", "list", "--json"], check=True, capture_output=True, text=True
    )
    try:
        decoded = [json.loads(line) for line in result.stdout.splitlines() if line.strip()]
    except json.JSONDecodeError as error:
        fail(f"Unable to parse limactl JSON: {error}")
    instances = decoded
    if isinstance(instances, dict):
        instances = [instances]
    if not isinstance(instances, list):
        fail("Unexpected limactl JSON structure")
    for candidate in instances:
        if candidate.get("name") == name:
            return candidate
    fail(f"Lima instance not found: {name}")


def main() -> int:
    if "--host" in sys.argv:
        print("{}")
        return 0
    if "--list" not in sys.argv:
        fail("Usage: lima_inventory.py --list")
    target = instance()
    if target.get("status") != "Running":
        fail(f"Lima instance is not running: {target.get('name')}")
    runtime = Path(os.environ["DEVBOX_RUNTIME_DIR"]).resolve()
    known_hosts = runtime / "known_hosts"
    if not known_hosts.is_file():
        fail(f"Missing runtime known_hosts file: {known_hosts}")
    required = ("sshAddress", "sshLocalPort", "IdentityFile")
    missing = [key for key in required if not target.get(key)]
    if missing:
        fail(f"Lima connection metadata is incomplete: {', '.join(missing)}")
    user = target.get("config", {}).get("user", {}).get("name")
    if not user:
        fail("Lima guest user is missing from instance metadata")
    common_args = (
        f"-o StrictHostKeyChecking=accept-new "
        f"-o UserKnownHostsFile={known_hosts} "
        "-o IdentitiesOnly=yes"
    )
    hostvars = {
        target["name"]: {
            "ansible_host": target["sshAddress"],
            "ansible_port": target["sshLocalPort"],
            "ansible_user": user,
            "ansible_ssh_private_key_file": target["IdentityFile"],
            "ansible_ssh_common_args": common_args,
        }
    }
    print(json.dumps({"_meta": {"hostvars": hostvars}, "devbox": {"hosts": [target["name"]]}}))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
