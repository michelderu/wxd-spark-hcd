# Manual installation of watsonx.data Developer Edition
These instructions allow you to set up wx.d manually without using the provided IBM installer. This can come in handy if you want to understand the mechanics below or if you want to adjust operational aspects.

---

## Provision container runtime

Ensure you have your runtime of choice set-up. Refer to [Containder Fundamentals](https://github.com/michelderu/container-fundamentals) and the specific setup instructions for your architecture [here](https://github.com/michelderu/container-fundamentals/blob/main/course/08-setup-linux-macos-windows.md).

Below is an overview of the local stack components required to manually run watsonx.data Developer Edition, from the container runtime layer to the Kubernetes Kind cluster:

| Stack Layer      | Description                                                                                       | Example Choices      |
|------------------|---------------------------------------------------------------------------------------------------|----------------------|
| **Host Machine** | Your local physical or virtual machine, where all components will run.                            | macOS, Linux, Windows|
| **Container Runtime** | Software that runs containers, emulating an OCI-compatible environment.                     | Docker, Podman       |
| **Kind**         | "Kubernetes IN Docker" - creates a local Kubernetes cluster running inside containers.             | Kind                 |
| **Kubernetes Cluster** | An orchestrated collection of nodes, managed by Kind, on which you will deploy watsonx.data. | Kind-managed control-plane and worker nodes |
| **kubectl**      | Command-line tool to administer your Kind cluster and deploy workloads like watsonx.data.          | kubectl              |
| **Helm**         | Package manager for Kubernetes, used to install watsonx.data and manage configuration.             | Helm                 |

> [!TIP]
> Ensure each layer is working before proceeding to the next step. This stack allows you to simulate a full-featured Kubernetes environment for local watsonx.data deployments—ideal for demos and testing.

### Validate host readiness first
After setting up your environment according to the instructions above, it's helpful to assess host readiness using the provided scrpt.
```bash
./scripts/host_readiness.sh
```

---

## Create and validate your Kind cluster
Create the local cluster:

```bash
kind create cluster --name wxd
kubectl config use-context kind-wxd
```

Check Kubernetes readiness:

```bash
kubectl get nodes
watch kubectl get pods -n kube-system -o wide
```

What to look for:
- `kubectl get nodes` should show all nodes as `Ready`.
- In `kube-system`, core pods should settle to `Running` or `Completed`.
- If pods remain in `Pending`, `CrashLoopBackOff`, or similar, fix that before Helm install.

---

## Install watsonx.data Developer Edition
Even in manual mode, get the official package from IBM docs:

- Start from **[Installing watsonx.data Standard](https://www.ibm.com/docs/en/watsonxdata/standard/2.3.x?topic=version-installing)**.
- Follow the package download/extract guidance in **[Installing watsonx.data developer edition on Linux(RHEL)](https://www.ibm.com/docs/en/watsonxdata/standard/2.3.x?topic=installing-watsonxdata-developer-edition-linuxrhel)** (also use this path for manual installation on Windows or macOS).

Then install with Helm from the extracted `watsonx.data-developer-edition-installer` directory:

```bash
helm dependency update
helm upgrade --install wxd . \
  -f values.yaml \
  -f values-secret.yaml \
  --namespace wxd \
  --create-namespace \
  --timeout 10m
```

> [!NOTE]
> Adjust `values.yaml` and `values-secret.yaml` before install if you need custom resources, storage, or credentials.

### Check watsonx.data readiness 🧪

```bash
watch kubectl get pods -n wxd
```

After a while, depending on your system this can take anything between a few minutes and 10's of minutes, you should see a similar status:

```text
NAME                                              READY   STATUS      RESTARTS   AGE
generate-certs-and-truststore-lwmm6               0/1     Completed   0          11m
ibm-lh-control-plane-prereq-45hl9                 0/1     Completed   0          10m
ibm-lh-mds-rest-7cc9bd5c9b-px5xw                  1/1     Running     0          8m52s
ibm-lh-mds-thrift-679698fd56-22ldx                1/1     Running     0          8m52s
ibm-lh-minio-7b6dfc69f8-88xgh                     1/1     Running     0          8m52s
ibm-lh-presto-5d8bfdbd77-892cw                    1/1     Running     0          8m52s
ibm-lh-validator-7877c94d95-j47qx                 1/1     Running     0          8m52s
image-pull-job-wzxfv                              0/1     Completed   0          8m51s
lhams-api-64874857bc-wndfz                        1/1     Running     0          8m53s
lhconsole-api-6767df9d79-xjxq4                    1/1     Running     0          8m53s
lhconsole-nodeclient-84fbc5b998-kb4pj             1/1     Running     0          8m53s
lhconsole-ui-79bd784dc9-zxmz2                     1/1     Running     0          8m52s
lhingestion-api-846498cb98-ntlm5                  1/1     Running     0          8m52s
spark-hb-control-plane-975c76d8-qmkd9             2/2     Running     0          8m51s
spark-hb-create-trust-store-9d577b768-2gsds       1/1     Running     0          9m9s
spark-hb-deployer-agent-c5444448c-kpzmd           2/2     Running     0          8m51s
spark-hb-load-postgres-db-specs-vgwrz             0/1     Completed   0          9m9s
spark-hb-nginx-8647978c8-g69fv                    1/1     Running     0          8m51s
spark-hb-register-hb-dataplane-6dd49b8f84-v9lbd   1/1     Running     0          5m36s
spark-hb-ui-c5bb88ccd-vjmhf                       1/1     Running     0          8m51s
wxd-pg-postgres-0                                 1/1     Running     0          10m
```

### Port-forward UI and dependencies 🌐

Forwarding on `0.0.0.0` lets other hosts reference your machine IP:

```bash
nohup kubectl port-forward -n wxd service/lhconsole-ui-svc 6443:443 --address 0.0.0.0 2>&1 &
nohup kubectl port-forward -n wxd service/ibm-lh-minio-svc 9001:9001 --address 0.0.0.0 2>&1 &
nohup kubectl port-forward -n wxd service/ibm-lh-mds-thrift-svc 8381:8381 --address 0.0.0.0 2>&1 &
```

> [!TIP]
> - **lhconsole-ui-svc (6443:443)** — The main watsonx.data UI; exposes the admin console for managing data, queries, and configuration.
> - **ibm-lh-minio-svc (9001:9001)** — MinIO object storage admin console, where you can observe and manage the underlying storage buckets used by the lakehouse.
> - **ibm-lh-mds-thrift-svc (8381:8381)** — Metadata Service endpoint, used internally by watsonx.data for catalog and privilege operations (not typically needed for direct user interaction).

Open **`https://localhost:6443/`**. Expect a browser warning for the Development/TLS certificate—continue for local demos only (`ibmlhadmin` / `password` unless you changed defaults).
