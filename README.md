# RHEL-KVM-cloud-init

Script to automaticaly create VMs with RHEL KVM Guest Image 

Tested on RHEL 10.0, 10.1, 9.7, 9.6 and 8.10

1. clone the depot
2. customize DESTINATION and BRIDGE variables in the script
3. make the script executable
4. create an `images/` subdirectory
5. go to section "Virtualization Images" at https://access.redhat.com/downloads/content/rhel
6. download qcow images or put images generated with image-builder in the `images/`  directory
7. run the script
