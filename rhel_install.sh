#!/bin/bash

#######################################
# User customization
#######################################
DESTINATION=/$HOME/VirtualMachines/

# specify a bridge device to force its usage 
# comment the variable or set BRIDGE to "" to use the default network
# ex: BRIDGE=virbr0
# BRIDGE=virbr0

#######################################
# Main procedure
#######################################

# Check if images directory exists and contains images
if [ ! -d images ]
then
  mkdir images
fi

if [ "$(ls images)" == "" ]
then
  echo "images/ is empty"
  echo "put Virtualization Images from https://access.redhat.com/downloads/content/rhel in it"
  exit 1
fi

# Do some cleaning
if [ -d iso ]
then
  rm -rf iso
fi
mkdir iso

#### Choose arch
echo "Architecture"
select arch in x86_64 aarch64 ; do break ; done
ARCH=${arch=x86_64}

#### Choose distribution
echo "Distribution :"
cd images
select imagefile in $(ls *.qcow2 | grep ${ARCH} | sort ) ; do  break ; done
cd ..
IMAGE=${imagefile}

# Set rhel release
# type "virt-install --osinfo list | grep rhel" to view supported ones
RELEASE=$(echo ${IMAGE} | cut -d '.' -f 1 | tr -d '-')-unknown

#### Set hostname
echo
echo -n "Hostname [rhel]:"
read user_hostname

LOCALHOSTNAME=${user_hostname:-rhel}
INSTANCEID=${LOCALHOSTNAME}

#### Machine 
echo -n "Memory [2048]:"
read user_memory
MEMORY=${user_memory:-2048}

echo -n "Cpu [2]:"
read user_cpu
CPU=${user_cpu:-2}

echo -n "Disk size [10G]:"
read user_disksize
DISKSIZE=${user_disksize:-10G}

#### User 
echo "Choose SSH pubkey"
select user_pubkey in $(ls $HOME/.ssh/id*.pub) ; do break ; done
SSHKEY=$(cat ${user_pubkey})

echo
echo -n "User [redhat]:"
read user_login
USER=${user_login:-redhat}

echo
echo -n "Password [redhat123]:"
read user_password
PASSWORD=${user_password:-redhat123}

### Coud init files creation
cat > iso/meta-data << EOF
instance-id: ${INSTANCEID}
local-hostname: ${LOCALHOSTNAME}
EOF

cat > iso/user-data << EOF
#cloud-config
user: ${USER}
password: ${PASSWORD}
chpasswd: {expire: False}
ssh_pwauth: True
ssh_authorized_keys:
- ${SSHKEY}
EOF

genisoimage -output iso/cloud-init.iso -volid cidata -joliet -rock iso/user-data iso/meta-data

cp images/${IMAGE} $HOME/VirtualMachines/${LOCALHOSTNAME}.qcow2
qemu-img resize $HOME/VirtualMachines/${LOCALHOSTNAME}.qcow2 ${DISKSIZE}

# Bridge device
if [ "${BRIDGE}" == "" ]
then
  BRIDGE_OPTION=""
else
  BRIDGE_OPTION="--bridge ${BRIDGE}"
fi

echo
echo "####################"
echo " Ready to go!" 
echo "####################"
echo "Use Ctrl-] to exit console"
echo "use \"sudo virsh list --all\" to view VMs"
echo "run the following command to install your VM:"
echo
echo sudo virt-install --memory ${MEMORY} --vcpus ${CPU} --name ${LOCALHOSTNAME} --disk $HOME/VirtualMachines/${LOCALHOSTNAME}.qcow2,device=disk,bus=virtio,format=qcow2 --disk iso/cloud-init.iso,device=cdrom --os-variant ${RELEASE} --virt-type qemu --graphics none ${BRIDGE_OPTION} --arch ${ARCH} --import
