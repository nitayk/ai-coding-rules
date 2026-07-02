# GKE Cluster Conventions

GKE has too many knobs. The defaults below — distilled from the CFT `terraform-google-kubernetes-engine` module and CIS-GKE benchmark — are the right starting point for almost every cluster. Deviate only with a documented reason.

Source: [CFT GKE module](https://github.com/terraform-google-modules/terraform-google-kubernetes-engine), [GCP — GKE best practices](https://docs.cloud.google.com/kubernetes-engine/docs/best-practices).

---

## The Defaults

| Setting | Value | Why |
|---|---|---|
| **Cluster topology** | Regional (3+ zones) | Survives a zone outage; control plane is HA. Costs ~3× a zonal cluster but eliminates the largest single failure mode. |
| **Endpoint** | Private (no public master) | Reduces attack surface; force kubectl access via VPN / bastion / IAP. |
| **Master authorized networks** | Whitelist only — never `0.0.0.0/0` | Compensating control if `private_endpoint` is `false`. |
| **Release channel** | `REGULAR` (production) / `RAPID` (dev) | Pin to a channel; never `UNSPECIFIED` (= "static" version that never gets security patches without manual upgrade). |
| **Workload Identity** | Enabled (`workload_pool = "<project>.svc.id.goog"`) | The only sane way for pods to call GCP APIs. See `gcp/workload-identity-federation.md`. |
| **Shielded nodes** | Enabled | Secure boot + integrity monitoring; trivial cost, real benefit. |
| **Network policy** | Enabled (Calico or Dataplane V2) | Default-deny-able pod-to-pod traffic. |
| **Binary Authorization** | Enforced for prod | Cryptographically verify images before pods start. |
| **Logging / monitoring** | `SYSTEM_COMPONENTS,WORKLOADS` | Default to full observability; tune off only with reason. |
| **Node auto-upgrade** | On | Channel pinning handles the velocity; auto-upgrade closes CVEs. |
| **Node auto-repair** | On | Almost no downside. |

---

## ✅ Good: A Production GKE Cluster via CFT

```hcl
# ✅ Good: opinionated production cluster
module "gke" {
  source  = "terraform-google-modules/kubernetes-engine/google//modules/private-cluster"
  version = "~> 32.0"

  project_id        = var.project_id
  name              = "prod-us-central1"
  region            = "us-central1"
  network           = module.network.network_name
  subnetwork        = module.network.subnets_names[0]
  ip_range_pods     = "pods"
  ip_range_services = "services"

  # Private cluster
  enable_private_endpoint = false  # set true if you have IAP/VPN; false = master is public, nodes are private
  enable_private_nodes    = true
  master_ipv4_cidr_block  = "172.16.0.0/28"

  master_authorized_networks = [
    { cidr_block = "10.0.0.0/8", display_name = "corp-vpn" },
  ]

  # Channel & versioning
  release_channel = "REGULAR"
  # NOTE: do NOT set kubernetes_version when using release channels

  # Identity & security
  identity_namespace        = "${var.project_id}.svc.id.goog"  # Workload Identity
  enable_shielded_nodes     = true
  enable_binary_authorization = true
  network_policy            = true
  network_policy_provider   = "CALICO"

  # Observability
  logging_service    = "logging.googleapis.com/kubernetes"
  monitoring_service = "monitoring.googleapis.com/kubernetes"

  # Node pools — regional, autoscaled, surge-upgrade
  node_pools = [
    {
      name               = "default"
      machine_type       = "e2-standard-4"
      min_count          = 1
      max_count          = 5
      disk_size_gb       = 100
      disk_type          = "pd-standard"
      image_type         = "COS_CONTAINERD"
      auto_repair        = true
      auto_upgrade       = true
      preemptible        = false
      initial_node_count = 1
      max_surge          = 1
      max_unavailable    = 0
    },
  ]

  node_pools_oauth_scopes = {
    all = ["https://www.googleapis.com/auth/cloud-platform"]
  }
}
```

---

## Topology: Regional vs Zonal

A **regional cluster** runs the control plane in 3 zones; node pools are *also* regional by default (one node per pool per zone × replicas).

- Cost: ~3× a zonal cluster (control plane is free, but you'll have 3× the nodes for the same `node_count`).
- Resilience: survives a full zone outage.

A **zonal cluster** runs everything in one zone. Cheaper, but a single AZ outage takes the whole cluster down. Acceptable for dev/staging; **not** for production.

```hcl
# ✅ Good: regional cluster
region = "us-central1"

# Zonal — only for non-prod
# zone = "us-central1-a"
```

---

## Release Channels — Pin to One

A release channel governs which GKE versions are eligible for upgrade.

| Channel | Use for | Upgrade cadence |
|---|---|---|
| `RAPID` | Dev / experimentation | Newest features, less bake time |
| `REGULAR` | **Production default** | Stable, tested, default for most orgs |
| `STABLE` | Compliance-heavy / risk-averse | Slowest cadence, longest bake |

```hcl
# ✅ Good: pin the channel
release_channel = "REGULAR"

# ❌ Bad: pin an exact version → security CVEs require manual upgrade
release_channel    = "UNSPECIFIED"
kubernetes_version = "1.29.4-gke.1024000"
```

Pinning a version takes you off the channel entirely. You then own every upgrade — including security ones — manually. Almost no one wants this.

---

## Node Pools: Smaller, More

Prefer **multiple small node pools** over one large one:

- Workload isolation (taint/toleration to keep system pods off batch nodes).
- Targeted upgrades (drain one pool at a time).
- Mixed machine types per pool (`e2-standard-4` for general, `n2d-highmem-8` for cache).
- Independent autoscaler tuning per workload.

```hcl
node_pools = [
  { name = "system",  machine_type = "e2-standard-2", min_count = 1, max_count = 3 },
  { name = "general", machine_type = "e2-standard-4", min_count = 1, max_count = 10 },
  { name = "memory",  machine_type = "n2d-highmem-8", min_count = 0, max_count = 5 },
]
```

Pair with `node_pools_taints` to keep workloads on the right pool.

---

## Surge Upgrades

Configure `max_surge` and `max_unavailable` per node pool to control upgrade speed/safety:

```hcl
max_surge        = 1   # add this many extra nodes during upgrade
max_unavailable  = 0   # never have fewer than current capacity
```

`max_unavailable = 0` + `max_surge = 1` is the safest — slow but never reduces capacity. For large pools, `max_surge = 25%` is a common faster setting.

---

## Anti-patterns

```hcl
# ❌ Bad: public cluster, no master authorized networks
enable_private_nodes        = false
master_authorized_networks  = []
```

```hcl
# ❌ Bad: ABAC instead of Workload Identity
# (no identity_namespace set → pods use the node's SA, which has Compute API access)
identity_namespace = ""
```

```hcl
# ❌ Bad: one massive node pool, no surge limits
node_pools = [
  { name = "default", min_count = 1, max_count = 100 }
]
# rolling upgrade can drop arbitrary numbers of nodes mid-flight
```

---

## Related Rules

- [`terraform-google-modules` Preference](terraform-google-modules-preference.md) — why we're using the CFT GKE module at all.
- [Workload Identity Federation](workload-identity-federation.md) — pod-to-GCP-API auth.
- [Kubernetes / Helm / Vault](../providers/kubernetes-helm-vault.md) — how to talk to the cluster from Terraform once it exists.

---

## References

- [CFT GKE module — private-cluster submodule](https://github.com/terraform-google-modules/terraform-google-kubernetes-engine/tree/master/modules/private-cluster)
- [GCP — GKE best practices](https://docs.cloud.google.com/kubernetes-engine/docs/best-practices)
- [CIS Google Kubernetes Engine Benchmark](https://www.cisecurity.org/benchmark/kubernetes/)

<!-- Cross-platform: see AGENTS.md in the repository root for Cursor, Claude Code, and Copilot paths. -->
