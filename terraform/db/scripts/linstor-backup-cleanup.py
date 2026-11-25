# Run by the linstor-backup-cleanup CronJob (db/garage.tf): drop backup snapshots that never reached the S3 remote.
import json
import os
import subprocess
import time

remote = os.environ["REMOTE"]
cutoff_ms = (time.time() - float(os.environ["MIN_AGE_HOURS"]) * 3600) * 1000


def linstor(*args):
    return subprocess.run(["linstor", *args], check=True, capture_output=True, text=True).stdout


uploaded = {k for k, v in json.loads(linstor("-m", "backup", "list", remote))["linstor"].items() if v.get("success")}

for snap in json.loads(linstor("-m", "snapshot", "list"))[0]:
    props = snap.get("snapshot_definition_props") or {}
    if props.get(f"BackupShipping/Source/{remote}/BackupTargetRemote") != remote:
        continue  # not a backup snapshot (e.g. CSI VolumeSnapshot)
    if any(k.startswith("BackupShipping/Target/") for k in props):
        continue  # created by a restore from the remote
    rsc, name = snap["resource_name"], snap["name"]
    if f"{rsc}_{name}" in uploaded:
        continue
    if min(s["create_timestamp"] for s in snap["snapshots"]) > cutoff_ms:
        continue  # may still be uploading
    print(f"dropping {rsc}/{name}: never uploaded to {remote}", flush=True)
    subprocess.run(["linstor", "backup", "abort", remote, "-r", rsc])
    linstor("snapshot", "delete", rsc, name)
