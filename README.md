# NC24rs_v3 Infiniband setup poc scripts


https://docs.microsoft.com/en-us/azure/virtual-machines/workloads/hpc/enable-infiniband

## Enable Infiniband

https://docs.microsoft.com/en-us/azure/virtual-machines/extensions/hpc-compute-infiniband-linux#azure-cli

```
az vm extension set \
  --resource-group vm-poc-rg \
  --vm-name ibhost01 \
  --name InfiniBandDriverLinux \
  --publisher Microsoft.HpcCompute \
  --version 1.1 
```

https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/8/html/configuring_infiniband_and_rdma_networks/testing-infiniband-networks_configuring-and-managing-networking

```
azuser@ibhost01:~$ sudo ibv_devices
    device                 node GUID
    ------              ----------------
    mlx4_0              00155dfffe33ff13
azuser@ibhost01:~$
```

### Troubleshooting, Debugging & Connection Test

Troubleshooting InfiniBand connection issues using OFED tools
https://software.intel.com/content/www/us/en/develop/articles/troubleshooting-infiniband-connection-issues-using-ofed-tools.html?wapkw=(sl)

InfiniBand Command Examples
https://docs.oracle.com/cd/E19914-01/820-6705-10/appendix2.html

CHAPTER 6. TESTING INFINIBAND NETWORKS
https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/8/html/configuring_infiniband_and_rdma_networks/testing-infiniband-networks_configuring-and-managing-networking


