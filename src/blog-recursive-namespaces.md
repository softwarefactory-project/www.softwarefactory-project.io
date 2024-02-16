# Recursive namespaces to run containers inside a container

This post explores the challenge of safely running a container inside a container.
In three parts, I present:

- User namespaces.
- Required capabilities.
- Procfs kernel limitation.

> The examples in this post are using the following packages:
> - kernel-6.6.11-200.fc39.x86_64
> - selinux-policy-39.3-1.fc39.noarch
> - util-linux-core-2.39.3-1.fc39.x86_64
> - bubblewrap-0.8.0-1.fc39.x86_64
> - podman-4.8.3-1.fc39.x86_64

## Context and problem statement

We would like to deploy a containerized workload that creates nested containers to isolate individual tasks.
In our case, a service named `zuul-executor` leverages the bubblewrap tool to create temporary namespaces for running Ansible playbooks as part of a CI build system.

The problem is that creating new namespaces is considered as a privileged action by container runtime.


## User namespaces

Since RHEL8, regular users are allowed to create namespaces. Previously, such action required admin (root) privilege.
We can explore this feature using the standard `unshare` utility.
As a regular user, we can create new namespaces that are isolated from the host.

```ShellSession
[tristanc@fedora ~]$ unshare --user --mount --net --pid --fork --map-root-user --mount-proc
root@fedora:~# id
uid=0(root) gid=65534(nfsnobody) groups=65534(nfsnobody) context=unconfined_u:unconfined_r:unconfined_t:s0-s0:c0.c1023
root@fedora:~# ip a
1: lo: <LOOPBACK> mtu 65536 qdisc noop state DOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
root@fedora:~# ps afx
    PID TTY      STAT   TIME COMMAND
      1 pts/5    S      0:00 -bash
     79 pts/5    R+     0:00 ps afx
```

Above we can see that:

- `--user` creates a new uid maps which let us become root.
- `--net` creates a new network stack which only have the loopback.
- `--pid` creates a new procfs which hide the host's processes.

To create these namespaces, the process uses the `CLONE_NEWNS|CLONE_NEWUSER|CLONE_NEWPID|CLONE_NEWNET` flags (either for the `unshare(2)` or `clone(2)` syscall).

Note that it is necessary here to create a new user namespace (with `--user`), otherwise we don't get the capabilities that enables creating the other namespaces.

We can also create nested namespaces:

```ShellSession
root@fedora:~# sleep 1001 &
[1] 23
root@fedora:~# unshare --user --mount --net --pid --fork --map-root-user --mount-proc
root@fedora:~# ps afx
    PID TTY      STAT   TIME COMMAND
      1 pts/8    S      0:00 -bash
     23 pts/8    R+     0:00 ps afx
root@fedora:~# exit
root@fedora:~# ps afx
    PID TTY      STAT   TIME COMMAND
      1 pts/8    S      0:00 -bash
     23 pts/8    S      0:00 sleep 1001
     48 pts/8    R+     0:00 ps afx
```

We can also use the `bwrap` command from the bubblewrap package to achieve the same kind of isolation:

```ShellSession
[tristanc@fedora ~]$ bwrap --ro-bind /usr /usr --symlink usr/lib64 /lib64 --proc /proc --dev /dev --tmpfs /tmp --unshare-all --new-session --cap-add all --uid 0 bash
bash: cannot set terminal process group (1): Inappropriate ioctl for device
bash: no job control in this shell
bash-5.2# sleep 4242 &
[1] 7
bash-5.2# bwrap --ro-bind /usr /usr --symlink usr/lib64 /lib64 --proc /proc --dev /dev --tmpfs /tmp --unshare-all --new-session --cap-add all --uid 0 bash
bash: cannot set terminal process group (1): Inappropriate ioctl for device
bash: no job control in this shell
bash-5.2# ps afx
    PID TTY      STAT   TIME COMMAND
      1 ?        Ss     0:00 bwrap --ro-bind /usr /usr --symlink usr/lib64 /lib64 --proc /proc --dev /dev --tmpfs /tmp --unshare-all --new-session --cap-add all --uid 0 bash
      2 ?        S      0:00 bash
      3 ?        R      0:00  \_ ps afx
```

And we can confirm from the host that the namespaces are indeed nested:

```ShellSession
[tristanc@fedora ~]$ ps afx
...
 165104 pts/8    Ss     0:00  |   \_ /bin/bash --posix
 170707 pts/8    S+     0:00  |       \_ bwrap --ro-bind /usr /usr --symlink usr/lib64 /lib64 --proc /proc --dev /dev --tmpfs /tmp --unshare-all --new-session --cap-add all --uid 0 bash
 170708 ?        Ss     0:00  |           \_ bwrap --ro-bind /usr /usr --symlink usr/lib64 /lib64 --proc /proc --dev /dev --tmpfs /tmp --unshare-all --new-session --cap-add all --uid 0 bash
 170709 ?        S      0:00  |               \_ bash
 170826 ?        S      0:00  |                   \_ sleep 4242
 170827 ?        S      0:00  |                   \_ bwrap --ro-bind /usr /usr --symlink usr/lib64 /lib64 --proc /proc --dev /dev --tmpfs /tmp --unshare-all --new-session --cap-add all --uid 0 bash
 170828 ?        Ss     0:00  |                       \_ bwrap --ro-bind /usr /usr --symlink usr/lib64 /lib64 --proc /proc --dev /dev --tmpfs /tmp --unshare-all --new-session --cap-add all --uid 0 bash
 170829 ?        S      0:00  |                           \_ bash
```

In this section, we demonstrated that a regular unprivileged user is able to create namespace recursively (up to 32 layers).
And even though the user appears to be root in the namespace, it is still a regular user from the host perspective, and the user didn't gain additional privileged.


## Container runtime

Let's install some tool inside the container image first:

```
[tristanc@fedora ~]$ CTX=$(buildah from fedora)
[tristanc@fedora ~]$ buildah run $CTX dnf install -y util-linux procps-ng bubblewrap
[tristanc@fedora ~]$ buildah commit --rm $CTX fedora
```

Using a minimal container does not work because it can't create the user namespace:

```
[tristanc@fedora ~]$ podman run --cap-drop setfcap -it --rm fedora unshare --user --mount --net --pid --fork --map-root-user --mount-proc
unshare: write failed /proc/self/uid_map: Operation not permitted
```

So we need the setfcap capabilities, but that is not enough:

```
[tristanc@fedora ~]$ podman run -it --rm fedora unshare --user --mount --net --pid --fork --map-root-user --mount-proc
unshare: mount /proc failed: Permission denied
```

It appears that we need to provide the `--privileged` flag:

```
[tristanc@fedora ~]$ podman run --privileged -it --rm fedora unshare --user --mount --net --pid --fork --map-root-user --mount-proc
-sh-5.2# unshare --user --mount --net --pid --fork --map-root-user --mount-proc
-sh-5.2#
```

Podman and other container runtime like cri-o provides additional isolation than what we saw in the first section.
In the next section we'll try to understand what is happening.


## procfs limitation

It appears that, for the purpose of this nested containerization, the `--privileged` argument simply keep the /proc untainted from any mountpoints.
Indeed, we can observe that a regular container does not have access to the full `/proc`:

```
[tristanc@fedora ~]$ podman run -it --rm fedora grep "^tmpfs /proc" /proc/mounts
tmpfs /proc/acpi tmpfs ro,context="system_u:object_r:container_file_t:s0:c373,c905",relatime,size=0k,uid=1000,gid=1000,inode64 0 0
tmpfs /proc/scsi tmpfs ro,context="system_u:object_r:container_file_t:s0:c373,c905",relatime,size=0k,uid=1000,gid=1000,inode64 0 0
[tristanc@fedora ~]$ podman run --privileged -it --rm fedora grep "^tmpfs /proc" /proc/mounts | wc -l
0
```

We can observe the same behavior on the host, for example the initial example no longer works in that situation:

```
[tristanc@fedora ~]$ sudo mount -t tmpfs none /proc/scsi
[sudo] password for tristanc:
[tristanc@fedora ~]$ unshare --user --mount --net --pid --fork --map-root-user --mount-proc
unshare: mount /proc failed: Operation not permitted
```

The same happens inside a privileged pod:

```
[tristanc@fedora ~]$ podman run --tmpfs /proc/scsi --privileged -it --rm fedora unshare --user --mount --net --pid --fork --map-root-user --mount-proc
unshare: mount /proc failed: Operation not permitted
```

However, podman is still able to create its namespaces:

```
[tristanc@fedora ~]$ podman run -it --rm fedora ps afx
    PID TTY      STAT   TIME COMMAND
      1 pts/0    Rs+    0:00 ps afx
[tristanc@fedora ~]$ bwrap --ro-bind /usr /usr --symlink usr/lib64 /lib64 --proc /proc --dev /dev --tmpfs /tmp --unshare-all --new-session --cap-add all --uid 0 ps afx
bwrap: Can't mount proc on /newroot/proc: Operation not permitted
[tristanc@fedora ~]$ sudo umount /proc/scsi
```

So we are left with two interrogations:

- How podman is able to create a pid namespace with a fresh procfs when the host has a tmpfs mounted in /proc/scsi ?

- Why are we able to create a CLONE_NEWPID but we can't mount a fresh procfs when the parent one has a tmpfs mounted in /proc/scsi ?
  Is this an over-sight from the kernel, where the creation of a fresh procfs is denied because it would reveal the files previously hidden with a tmpfs?


## Conclusion

In conclusion, we saw that creating recursive namespace is possible under normal condition,
but because the container runtime are tainting the /proc with tmpfs,
it is no longer possible to create nested namespace, even though we don't need additional
privileges than the one already granted to a regular container.
