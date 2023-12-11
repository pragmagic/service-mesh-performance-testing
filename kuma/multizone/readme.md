# Kuma multi-zone deployment

Kuma deployment was generated from commit `b74e154c94e69ef672aac747161a88b703ccbf9e`, using the following command:

```bash
helm repo list
helm repo update kuma
helm search repo kuma/kuma --versions | head
helm template \
    kuma \
    kuma/kuma \
    --version 2.4.3 \
    --namespace kuma-global-cp \
    --set controlPlane.mode=global \
    --set controlPlane.environment=universal \
    > ./kuma/multizone/configs-k8s/c1/kuma-global-cp-universal.yaml
```

The result was modified:
- Move `kuma-global-zone-sync` service into `./kuma/multizone/prepare/global-cp-svc.yaml`
- Remove control plane init container `migration`
- Set `KUMA_STORE_TYPE` to `memory`, remove `KUMA_STORE_POSTGRES_PORT` env
