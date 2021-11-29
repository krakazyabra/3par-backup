# 3par-backup

Script to backing up 3par volumes


## Requirements

- `nbdcopy` from [libnbd](https://gitlab.com/nbdkit/libnbd)
- `qemu-img` from [qemu-utils](https://gitlab.com/qemu-project/qemu)


## Example

Example usage with restic:

```bash
export RESTIC_PASSWORD="aeseiNgamaiyei6Aelah"
export CMD='set -x; export RESTIC_REPOSITORY="/backups/$VV"; restic init 2>/dev/null; timeout 3h restic backup --no-cache --stdin'
export JOBS=8
export FIRST_LUN=100
3par-backup 10.9.8.7 'dev.one.*.vv'
```
