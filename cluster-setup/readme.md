# Node count and taints

These tests are meant to be run in clusters with only one worker node,
to ensure consistent performance for all service meshes.

Some clusters, like AWS, don't have distinct control plane nodes.
Other clusters may have them.

Before running tests make sure that your control plane nodes are tainted
to avoid splitting pods between nodes.

```bash
k1 taint node -l node-role.kubernetes.io/control-plane node-role.kubernetes.io/master:NoSchedule
k2 taint node -l node-role.kubernetes.io/control-plane node-role.kubernetes.io/master:NoSchedule
```

# Troubleshooting

If there are problems auto installing `istioctl` or `kumactl`, download the archive with the required version (specified in the `ISTIO_VERSION` or `KUMA_VERSION` variable) from the [Istio download page](https://istio.io/latest/docs/setup/getting-started/) or [Kuma download page](https://kuma.io/docs/2.4.x/production/install-kumactl/), unzip the archive and export the `/bin` subdir path, for example:

```bash
tar -xzvf kuma-2.4.3-darwin-amd64.tar.gz
cd kuma-2.4.3/bin
export PATH=$(pwd):$PATH
```

If there are problems loading docker images to local kind clusters, they can be pooled locally and uploaded to the cluster manually, for example:

```bash
docker pull fortio/fortio:1.40.0
kind load docker-image fortio/fortio:1.40.0 --name kind-2 --nodes kind-2-worker
```
