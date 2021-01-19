# NC24rs_v3 Infiniband setup poc scripts


https://docs.microsoft.com/en-us/azure/virtual-machines/workloads/hpc/enable-infiniband

## Enable Infiniband
Configuring InfiniBand for Ubuntu HPC and GPU VMs
https://techcommunity.microsoft.com/t5/azure-compute/configuring-infiniband-for-ubuntu-hpc-and-gpu-vms/ba-p/1221351

For Azure DSVM, it's better to follow the procedure of "SR-IOV enabled VMs with inbox driver" section.

https://docs.microsoft.com/en-us/azure/virtual-machines/workloads/hpc/setup-mpi

### Intel MPI
Download your choice of version of Intel MPI. Change the I_MPI_FABRICS environment variable depending on the version. For Intel MPI 2018, use I_MPI_FABRICS=shm:ofa and for 2019, use I_MPI_FABRICS=shm:ofi.


### Troubleshooting, Debugging & Connection Test

Use ibstat, ibstatus and/or ibv_devices.

https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/8/html/configuring_infiniband_and_rdma_networks/testing-infiniband-networks_configuring-and-managing-networking

```
azuser@ibhost01:~$ sudo ibv_devices
    device                 node GUID
    ------              ----------------
    mlx4_0              00155dfffe33ff13
azuser@ibhost01:~$
```

Troubleshooting InfiniBand connection issues using OFED tools
https://software.intel.com/content/www/us/en/develop/articles/troubleshooting-infiniband-connection-issues-using-ofed-tools.html?wapkw=(sl)

InfiniBand Command Examples
https://docs.oracle.com/cd/E19914-01/820-6705-10/appendix2.html

CHAPTER 6. TESTING INFINIBAND NETWORKS
https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/8/html/configuring_infiniband_and_rdma_networks/testing-infiniband-networks_configuring-and-managing-networking

Tips for Working with OFED 1.4 (Old version)
https://www.openfabrics.org/downloads/OFED/archive/ofed-1.4/OFED-1.4-docs/OFED_tips.txt


```
$ cat /sys/class/infiniband/mlx4_0/ports/1/pkeys/
0  1
$ cat /sys/class/infiniband/mlx4_0/ports/1/pkeys/0
0x8005
$ cat /sys/class/infiniband/mlx4_0/ports/1/pkeys/1
0x7fff
$ I_MPI_FABRICS=shm:ofi
$ I_MPI_DEBUG=6 mpirun -v -n 2 -host skt-hpc-test01,skt-hpc-test02 IMB-MPI1 pingpong
$ I_MPI_DEBUG=4 I_MPI_HYDRA_DEBUG=on FI_LOG_LEVEL=debug mpirun hostname
```

### MISC attempts (didn't work as expected)
https://docs.microsoft.com/en-us/azure/virtual-machines/extensions/hpc-compute-infiniband-linux#azure-cli

```
az vm extension set \
  --resource-group vm-poc-rg \
  --vm-name ibhost01 \
  --name InfiniBandDriverLinux \
  --publisher Microsoft.HpcCompute \
  --version 1.1 
```

#### Ubuntu Module Tips for IMPI
```
source /etc/profile.d/modules.sh # in case of "command not found"

module load mpi/impi-2019
...
module unload mpi/impi-2019
 ```
### References

 MLNX_OFED: Firmware - Driver Compatibility Matrix
 https://www.mellanox.com/support/mlnx-ofed-matrix
 
 For Azure VMs, we can choose 5.0-2.1.8.0 or 5.0-1.0.0.0. But, for my case, rather one installed/ran successfully for vm of ubuntu 18.04 LTS image.
 
 
AzureML Distributed Learning Utilities
https://azure.github.io/azureml-examples/docs/cheatsheet/distributed-training/#azureml-distributed-learning-utilities

Environment Variables from OpenMPI
https://azure.github.io/azureml-examples/docs/cheatsheet/distributed-training/#environment-variables-from-openmpi

```
I_MPI_DEBUG=4 I_MPI_HYDRA_DEBUG=on FI_LOG_LEVEL=debug mpirun  -v -n 2 -ppn 1 -host skt-hpc-test01,skt-hpc-test02 IMB-MPI1 pingpong

mpirun -np 2 --map-by node --hostfile ~/hostfile -mca pml ucx --mca btl ^vader,tcp,openib -x UCX_NET_DEVICES=mlx4_0:1  -x UCX_IB_PKEY=0x0003  ./osu_latency


https://docs.microsoft.com/en-us/azure/virtual-machines/workloads/hpc/setup-mpi

mpirun -v -np 4 --map-by node -H skt-dsvm01:2,skt-dsvm02:2  -mca pml ucx --mca btl ^vader,tcp,openib -x UCX_NET_DEVICES=mlx4_0:1  -x UCX_IB_PKEY=0x0004,0x0005 uname -r
mpirun --verbose -np 4 --map-by node -H skt-dsvm01:2,skt-dsvm02:2  -mca pml ucx --mca btl ^vader,tcp,openib -x UCX_NET_DEVICES=mlx4_0:1 hostname

https://docs.microsoft.com/en-us/azure/virtual-machines/workloads/hpc/setup-mpi#discover-partition-keys

dsvm01:~$ cat /sys/class/infiniband/mlx4_0/ports/1/pkeys/0
0x8004
dsvm01:~$ cat /sys/class/infiniband/mlx4_0/ports/1/pkeys/1
0x7fff

dsvm02:~$ cat /sys/class/infiniband/mlx4_0/ports/1/pkeys/0
0x8005
dsvm02:~$ cat /sys/class/infiniband/mlx4_0/ports/1/pkeys/1
0x7fff

https://docs.oracle.com/cd/E19923-01/820-6793-10/mca-params.html


mpirun -np 8 \
    -H skt-dsvm01:4,skt-dsvm01:4 \
    -bind-to none -map-by slot \
    -x NCCL_DEBUG=INFO -x LD_LIBRARY_PATH -x HOROVOD_MPI_THREADS_DISABLE=1 -x PATH \
    -mca pml ob1 \
    python ~/horovod/test/parallel/test_adasum_pytorch.py

HOROVOD_GPU_OPERATIONS=NCCL 

HOROVOD_WITH_PYTORCH=1 pip install --no-cache-dir horovod


mpirun -np 8 \
    -H skt-dsvm01:4,skt-dsvm02:4 \
    -bind-to none -map-by slot \
    -x NCCL_DEBUG=INFO -x LD_LIBRARY_PATH -x HOROVOD_MPI_THREADS_DISABLE=1 -x PATH \
    -mca pml ob1 \
    python ~/horovod/examples/pytorch/pytorch_mnist.py

mpirun -np 8 \
    -H skt-dsvm01:4,skt-dsvm02:4 \
    -bind-to none -map-by slot \
    -x NCCL_DEBUG=INFO -x LD_LIBRARY_PATH -x HOROVOD_MPI_THREADS_DISABLE=1 -x PATH \
    -mca pml ob1 \
    python ~/horovod/examples/tensorflow2/tensorflow2_mnist.py

export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/cuda-10.2/lib64
```
