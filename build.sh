#!/bin/bash -ex
### SOURCE: https://github.com/docker-32bit/ubuntu/blob/master/build-image.sh
### Build a docker image for ubuntu i386.

### settings
arch=i386
suite=trusty
chroot_dir='/var/chroot/trusty'
apt_mirror='http://archive.ubuntu.com/ubuntu'
docker_image='32bit/ubuntu:14.04'

### make sure that the required tools are installed
apt-get install -y docker.io debootstrap dchroot

### install a minbase system with debootstrap
export DEBIAN_FRONTEND=noninteractive
debootstrap --variant=minbase --arch=$arch $suite $chroot_dir $apt_mirror

### update the list of package sources
cat <<EOF > $chroot_dir/etc/apt/sources.list
deb $apt_mirror $suite main restricted universe multiverse
deb $apt_mirror $suite-updates main restricted universe multiverse
deb $apt_mirror $suite-backports main restricted universe multiverse
deb http://security.ubuntu.com/ubuntu $suite-security main restricted universe multiverse
deb http://extras.ubuntu.com/ubuntu $suite main
EOF

### install ubuntu-minimal
cp /etc/resolv.conf $chroot_dir/etc/resolv.conf
mount -o bind /proc $chroot_dir/proc
chroot $chroot_dir apt-get update
chroot $chroot_dir apt-get -y install ubuntu-minimal

### cleanup and unmount /proc
chroot $chroot_dir apt-get autoclean
chroot $chroot_dir apt-get clean
chroot $chroot_dir apt-get autoremove
rm $chroot_dir/etc/resolv.conf
umount $chroot_dir/proc

### create a tar archive from the chroot directory
tar cfz ubuntu.tgz -C $chroot_dir .

### import this tar archive into a docker image but save the id:
IMAGEID=$(cat ubuntu.tgz | docker import - $docker_image)

### Generate the dockerfile
echo "FROM "$NAME > images/Dockerfile
cat image/Dockertemplate >> images/Dockerfile

### Finally add the baseimage-docker components
docker build -t $1:$2 --rm image

### Remove the dockerfile
rm images/Dockerfile
