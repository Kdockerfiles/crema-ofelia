#!/usr/bin/env sh
set -e

cgdir="/sys/fs/cgroup/"
sd="systemd"
cgtype=$(stat -fc'%T' $cgdir)
if [ "$cgtype" != "cgroup2fs" ]; then
    sudo mkdir $cgdir$sd
    sudo mount -n -t cgroup -o "none,nodev,noexec,nosuid,name=$sd" $sd $cgdir$sd
fi

ofelia daemon --config /home/crema/ofelia.ini
