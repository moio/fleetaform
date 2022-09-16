# FAQ

## 'Too many open files' error is produced

This could be due to the number of open filesystem handle limit or the number of inotify instances/watches.

To raise the first:

```shell
export NEW_LIMIT=67108864
sysctl -w fs.nr_open=$NEW_LIMIT
echo "fs.nr_open = $NEW_LIMIT" >/etc/sysctl.d/allow_more_open_files.conf

cat >/etc/systemd/system/docker.service.d/allow_more_open_files.conf <<EOF
[Service]
LimitNOFILE=$NEW_LIMIT
EOF
systemctl daemon-reload
systemctl restart docker
```

To raise the second:

```shell
export NEW_LIMIT=1000000
sysctl -w fs.inotify.max_user_instances=$NEW_LIMIT
echo "fs.inotify.max_user_instances = $NEW_LIMIT" >/etc/sysctl.d/allow_more_inotify_instances.conf

sysctl -w fs.inotify.max_user_watches=$NEW_LIMIT
echo "fs.inotify.max_user_watches = $NEW_LIMIT" >/etc/sysctl.d/allow_more_inotify_watches.conf
```