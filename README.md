# Local Drive Scripts

## How To Install

```bash
sh -c "$(curl -fsSL https://raw.github.com/zenjabba/zendrive-local-scripts/master/install/preinstall.sh)"
```
following files need to be copied and edited (if necessary) from `filename.sample`
```
./zenpoller/config.yml
./.env
./backup-restore/backupbtrfs_files.txt
./backup-restore/backupbtrfs.conf
./plex-scripts/scanfolder.conf
./backup-restore/plexstandard_restore.conf
./config.conf
```