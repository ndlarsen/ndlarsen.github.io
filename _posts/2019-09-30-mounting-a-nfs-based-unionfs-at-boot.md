---
layout: post
title: "Mounting a NFS based UnionFS at boot"
date: 2019-09-30 20:30:46 +0200
categories: [linux,systemd,overlayfs,unionfs]
---

## Preface
---
A while back at work we ran into a problem on our dev environments that I was tasked with finding a solution for. Some might say I shamelessly hogged the issue but you really shouldn't listen to that...

## The problem
---
Now, in order to access production data on out remote development environments, the production data is shared and mounted read only via NFS. While this initially is fine, we really need some sort of write capabilities in order to properly test. This was in turn accomplished by supplying a shell script that when executed creates symbolic links to all but the current month's worth of production data and subsequently rsync the rest. There are two things wrong with this approach. First, we have to manually run this script in order to have current test data and second, the further into a month we are the larger the amount of data is. The first issue is having to manually synchronize production data in order to ensure it's current. The second issue is that the amount is often large enough to consume all available disk space on the given server and thus effectively bringing it to its knees. So to summerize the twofold problem:
1. synchronization is not automated
2. synchronization often consumes all available disk space

## Possible solutions and their shortcommings
---
So, we talked about a few different ways to solve the problem, some quick and easy, others a little more complicated. Add to that, while we do have some (tiny) degree of autonomy with regards to configuring our development environment more substantial chagens must go through our operations department.

### Approach #1: Modify and extend
We considered just editing the exsisting shell script to only rsync the current day's worth of data (or slightly more) and add a [Cron job](https://en.wikipedia.org/wiki/Cron) to execute it at night. While this would work it felt like a dirty hack and an old school system adminitrator's approach. To be fair, if the amount of data continues to grow, we're just pissing our pants to keep warm and if it fails, we need to run it manually anyway. Realizing the current approach was suboptimal and that any modification of it would be as well, I started to consider other options thought that perhaps we needed a solution closer to the filesystem.

### Approach #2: Filesystem snapshots
A not uncommon backup strategy is filesystem snapshotting. Snapshotting provides a point-in-time image of a filessystem or data set. The approach is tried and true and comes in many different implementations with variants such as full and incremential. Filesystems such as [ZFS](https://en.wikipedia.org/wiki/ZFS), [XFS](https://en.wikipedia.org/wiki/XFS) and [Btrfs](https://en.wikipedia.org/wiki/Btrfs) implement this and the [Volume Shadow Copy Service (VSS)](https://en.wikipedia.org/wiki/Shadow_Copy) on Windows as well. Our development environments being Linux based, VSS is not an option and at the time same could be said for ZFS. Btrfs is available, though not even remotely close to being mature enough for our environments and same goes for XFS snapshotting. Even if any of these filesystems were stable and mature, it still leaves the issue of operations having to redo servers to implement it and that of not having sufficient disk space.

### Approach #3: Filesystem abstraction
At this point I started wondering what if we could manipulate or combine the fileystems on a more overall and abstract level? What if we can combine several different filesystems and display them as one? I'm mean, we can already manipulate mount points and filesystems via binds. Enter [union mounts](https://en.wikipedia.org/wiki/Union_mount) which appearently is a thing and I didn't even know. There seems to be three major implementations, [UnionFS](https://en.wikipedia.org/wiki/UnionFS), [aufs](https://en.wikipedia.org/wiki/Aufs) and [OverlayFS](https://en.wikipedia.org/wiki/OverlayFS). The latter which was included in the Linux kernel a few years back. I dug a little deeper into this and it turned out that OverlayFS was perfect for our needs.

## Union mounts
---
Before getting into OerlayFS it's worth mentioning that as far as I can see there are two ways arranging union mounts. Keep in mind that this may not be neither the correct, academical nor official categorization but merely a way for me to visualize it in order to better understand. I think them as horizontal unions and vertical unions. Now, some might argue that there is only one and they might just be right.

### Horizontal unions
This arrangement is conceptually fairly straightforward. Different filesystems are arranged side by side and combined into one united filesystem.
```

         FsA               FsB            fsC           FsA ∪ FsB ∪ FsC
   ┏━━━━━━━━━━━━━┓  ┏━━━━━━━━━━━━━┓  ┏━━━━━━━━━━━━━┓  ┏━━━━━━━━━━━━━━━━━┓
   ┃             ┃  ┃             ┃  ┃             ┃  ┃                 ┃
   ┃             ┃  ┃             ┃  ┃             ┃  ┃   /dirA/        ┃
   ┃             ┃  ┃             ┃  ┃             ┃  ┃      ├-fileA    ┃
   ┃ /dirA/fileA ┃  ┃ /dirA/fileB ┃  ┃   /fileC    ┃  ┃      └-fileB    ┃
   ┃             ┃  ┃             ┃  ┃             ┃  ┃   /fileC        ┃
   ┃             ┃  ┃             ┃  ┃             ┃  ┃                 ┃
   ┃             ┃  ┃             ┃  ┃             ┃  ┃                 ┃
   ┗━━━━━━━━━━━━━┛  ┗━━━━━━━━━━━━━┛  ┗━━━━━━━━━━━━━┛  ┗━━━━━━━━━━━━━━━━━┛

```

### Vertical unions
This one is conceptually a little trickier. Different filesystems are stacked atop each other and are combined into one united filesystem. Imagine each layer being transparent and thus you'll be able to see the combination of all layers.
```

    FsA ∪ FsB ∪ FsC
  ┏━━━━━━━━━━━━━━━━━┓
  ┃   /dirA/        ┃
  ┃      ├-fileA    ┃
  ┃      └-fileB    ┃
  ┃   /fileC        ┃
  ┗━━━━━━━━━━━━━━━━━┛

         FsC
  ┏━━━━━━━━━━━━━━━━━┓
  ┃     /fileC      ┃
  ┗━━━━━━━━━━━━━━━━━┛

         FsB
  ┏━━━━━━━━━━━━━━━━━┓
  ┃   /dirA/fileB   ┃
  ┗━━━━━━━━━━━━━━━━━┛

         FsA
  ┏━━━━━━━━━━━━━━━━┓
  ┃  /dirA/fileA   ┃
  ┗━━━━━━━━━━━━━━━━┛

```

### OverlayFS
OverlayFS is both a bit wierd and truly awesome. It's not really a filesystem but more of an filesystem abstraction and it seems to utilize the vertical approach. There is a quick introduction to it [here](https://www.datalight.com/blog/2016/01/27/explaining-overlayfs-%E2%80%93-what-it-does-and-how-it-works/) and a decent, more in-depth read about it in the [docker docs](https://docs.docker.com/storage/storagedriver/overlayfs-driver/), so I won't go too much into details about it. Looking into this initially, I felt I had to trawl the internet in order to find some proper documentation on OverlayFS without mush success. As with other filesystems the united filesystem can to mounted read only or read/write but the nice part is that it can be done independent of the attributes of the underlaying filesystems. So, if the buttom most is read only and when written to, attempts to write are made from bottom up and written to the lowest writeable layer. Deleting works in a similar way by attempting to delete and if it's not possible the overlay will maintain a diff directory marking files as deleted and then just hide the files from sight. This means you can sustain the illusion of having a fully read/write filesystem when you really don't. This is why OverlayFS is so usefull for us at work as we are provided with read only data but need read/write capabilities or at least the illusion of such in order to test thoroughly and compared to the current solution it will consume far less disk space as we do not need rsync data.
While the cost in terms af disk space of using OverlayFS is negligible the unavoidable performance hit is worth considering if that is a priority to you.

## The struggle
---
Implementing a solution should be simple and easy by now, right? I figured I just needed to add an automounting entry to */etc/fstab* and be done with it. Mmm, not quite.

### Edit, reboot, profi.... oh, fml
Well, as I mentioned earlier, this is not particularly well documented and the error messages from the OverlayFS module are nondescriptive at best. Adding to that I made some incorrect assumptions and did not think of a few very simple things I already knew so I ended actually struggling a bit with this. Eventually I managed to mount an overlay manually
```
mount -t overlay overlayfs -o lowerdir=/mnt/proddata,upperdir=/mnt/data/diff,workdir=/mnt/data/work /mnt/data/testdata
```
and converted the command into an filesystem table entry.
```
overlayfs /mnt/data/testdata lowerdir=/mnt/proddata,upperdir=/mnt/data/diff,workdir=/mnt/data/work 0 0
```
For good measure I ran a `mount -a` to verify the entry and as expected it worked. **Stuff works, I am 1337...** At this point I was proud as a peacock and confidence made me blind. I ran a `sudo reboot`. After this point I was no longer able reach the server via SSH. *Sigh....* Crestfallen I had to contact our operations deparment, reluctantly notify them that I broke a server and beg them to fix my toys as I no longer had any to play with.

### The cause
It turned out that the filsystem table entry I added caused the server to halt during boot even though it seemingly worked. It took me quite some time while fiddling about with mount options as well as a few additional failed reboots to figure out the cause. As often before it was very simple and came down to [NFS](https://en.wikipedia.org/wiki/Network_File_System), [systemd](https://en.wikipedia.org/wiki/Systemd) and [parallelism](https://wiki.haskell.org/Parallelism_vs._Concurrency). On a system utilizing systemd the filesystem table is really just a placeholder by now as systemd translates all entries in the of it into systemd device units and attempts to mount them in parallel. Under normal circumstances this is not a problem but mounting a NFS share is inevitably slower that mounting a local device which in turn probably is slower that mounting a filesystem abstraction. Ultimately, systemd attempted to mount the overlay before the NFS share was ready which is a bit like trying to get out of bed before you're awake, nothing good comes from that. 

## The solution
---
Having finally located the cause a solution proper could be made. Rather than attempting to figure out what mount options was needed to ensure the filesystem table entry actually would work, I chose a different approach. Since the systemd is a de facto standard by now and the filesystem table is translated into systemd device units anyway, I thought writing one of those would be cleaner. This would also allow me to control when the overlay would actually be mounted as the definiton can define other mount points as dependencies.

### The implementation
The final result is the file `/etc/systemd/system/mnt-data-testdata.mount` with content below
```
[Unit]
Description=Multimedia data mounted under UnionFS
After=network.target nfs.service mnt-proddata.mount

[Mount]
What=overlayfs
Where=/mnt/data/testdata
Type=overlay
Options=nofail,lowerdir=/mnt/prod_data,upperdir=/mnt/data/diff,workdir=/mnt/data/work

[Install]
WantedBy=multi-user.target
```
Systemd still needs to detect the unit so run:
```
systemctrl daemon-reload
```
to enable the device right away:
```
sudo systemctl start mnt-data-testdata.mount
```
and finally to enable mounting at boot:
```
systemctl enable mnt-data-testdata.mount
```
