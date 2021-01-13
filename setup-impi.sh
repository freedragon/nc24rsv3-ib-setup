#!/bin/bash
set -ex

# install utils
apt-get update
apt-get -y install build-essential
apt-get -y install numactl \
                   rpm \
                   libnuma-dev \
                   libmpc-dev \
                   libmpfr-dev \
                   libxml2-dev \
                   m4 \
                   byacc \
                   python-dev \
                   python-setuptools \
                   tcl \
                   environment-modules \
                   tk \
                   texinfo \
                   libudev-dev \
                   binutils \
                   binutils-dev \
                   selinux-policy-dev \
                   flex \
                   libnl-3-dev \
                   libnl-route-3-dev \
                   libnl-3-200 \
                   bison \
                   libnl-route-3-200 \
                   gfortran

# install mellanox ofed
MLNX_OFED_DOWNLOAD_URL=http://content.mellanox.com/ofed/MLNX_OFED-5.0-1.0.0.0/MLNX_OFED_LINUX-5.0-1.0.0.0-ubuntu18.04-x86_64.tgz
TARBALL=$(basename ${MLNX_OFED_DOWNLOAD_URL})
MOFED_FOLDER=$(basename ${MLNX_OFED_DOWNLOAD_URL} .tgz)
wget --retry-connrefused --tries=3 --waitretry=5  $MLNX_OFED_DOWNLOAD_URL
tar zxvf ${TARBALL}
./${MOFED_FOLDER}/mlnxofedinstall --add-kernel-support --skip-unsupported-devices-check

# install mpi libraries
INSTALL_PREFIX=/opt

# Intel MPI 2019 (update 8)
IMPI_2019_VERSION="2019.8.254"
IMPI_2019_DOWNLOAD_URL=http://registrationcenter-download.intel.com/akdlm/irc_nas/tec/16814/l_mpi_${IMPI_2019_VERSION}.tgz
wget --retry-connrefused --tries=3 --waitretry=5 $IMPI_2019_DOWNLOAD_URL
tar -xvf l_mpi_${IMPI_2019_VERSION}.tgz
cd l_mpi_${IMPI_2019_VERSION}
sed -i -e 's/ACCEPT_EULA=decline/ACCEPT_EULA=accept/g' silent.cfg
./install.sh --silent ./silent.cfg
cd ..

# Module Files
MODULE_FILES_DIRECTORY=/usr/share/modules/modulefiles/mpi
mkdir -p ${MODULE_FILES_DIRECTORY}

# Intel 2019
cat << EOF >> ${MODULE_FILES_DIRECTORY}/impi_${IMPI_2019_VERSION}
#%Module 1.0
#
#  Intel MPI ${IMPI_2019_VERSION}
#
conflict        mpi
module load /opt/intel/impi/${IMPI_2019_VERSION}/intel64/modulefiles/mpi
setenv          MPI_BIN         /opt/intel/impi/${IMPI_2019_VERSION}/intel64/bin
setenv          MPI_INCLUDE     /opt/intel/impi/${IMPI_2019_VERSION}/intel64/include
setenv          MPI_LIB         /opt/intel/impi/${IMPI_2019_VERSION}/intel64/lib
setenv          MPI_MAN         /opt/intel/impi/${IMPI_2019_VERSION}/man
setenv          MPI_HOME        /opt/intel/impi/${IMPI_2019_VERSION}/intel64
EOF

ln -s ${MODULE_FILES_DIRECTORY}/impi_${IMPI_2019_VERSION} ${MODULE_FILES_DIRECTORY}/impi-2019

# install Intel libraries
MKL_DOWNLOAD_URL=http://registrationcenter-download.intel.com/akdlm/irc_nas/tec/15816/l_mkl_2019.5.281.tgz
wget --retry-connrefused --tries=3 --waitretry=5 $MKL_DOWNLOAD_URL
tar -xvf l_mkl_2019.5.281.tgz
cd l_mkl_2019.5.281
sed -i -e 's/ACCEPT_EULA=decline/ACCEPT_EULA=accept/g' silent.cfg
./install.sh --silent ./silent.cfg
cd ..

# optimizations
# Disable some unneeded services by default (administrators can re-enable if desired)
systemctl disable ufw

# Disable cloud-init
echo network: {config: disabled} | sudo tee /etc/cloud/cloud.cfg.d/99-disable-network-config.cfg
sudo bash -c "cat > /etc/netplan/50-cloud-init.yaml" <<'EOF'
network:
    ethernets:
        eth0:
            dhcp4: true
    version: 2
EOF
netplan apply

# Update memory limits
cat << EOF >> /etc/security/limits.conf
*               hard    memlock         unlimited
*               soft    memlock         unlimited
*               hard    nofile          65535
*               soft    nofile          65535
*               hard    stack           unlimited
*               soft    stack           unlimited
EOF

echo "vm.zone_reclaim_mode = 1" >> /etc/sysctl.conf
sysctl -p

# Configure WALinuxAgent
sudo sed -i -e 's/# OS.EnableRDMA=y/OS.EnableRDMA=y/g' /etc/waagent.conf
echo "Extensions.GoalStatePeriod=300" | sudo tee -a /etc/waagent.conf
echo "OS.EnableFirewallPeriod=300" | sudo tee -a /etc/waagent.conf
echo "OS.RemovePersistentNetRulesPeriod=300" | sudo tee -a /etc/waagent.conf
echo "OS.RootDeviceScsiTimeoutPeriod=300" | sudo tee -a /etc/waagent.conf
echo "OS.MonitorDhcpClientRestartPeriod=60" | sudo tee -a /etc/waagent.conf
echo "Provisioning.MonitorHostNamePeriod=60" | sudo tee -a /etc/waagent.conf
sudo systemctl restart walinuxagent
