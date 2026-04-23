# Build and Registry — Reference Documentation

> **Provenance (not runtime dependencies):**
> These docs are bundled from [Unity-Technologies/github-actions-workflows](https://github.com/Unity-Technologies/github-actions-workflows).
> If upstream docs change, refresh this file to match; do not improvise new workflow YAML.
> Last synced: 2026-04-09

---

## build-docker-image (action)

### Description

Composite action that builds a Docker image, tags it with the current commit SHA, and pushes it to a container registry. Supports GCP (GCR/GAR), Azure (ACR), and AWS (ECR), as well as multi-architecture builds for amd64 and arm64.

### Prerequisites

- **GCP:** Supports GCR and GAR. To push to `unity-source`, add your repo [here](https://github.com/Unity-Technologies/pre-terraform-unity-source-workspace/blob/master/iam.tf#L7). For the ads ecosystem shared `ci-deploy`/`ci-push` account, add your repo [here](https://github.com/Unity-Technologies/mz-terraform-common-workspace/blob/a9792ee52ed6515a15c3c151a5a92b2c4d909d64/variables-local.tf#L130). Otherwise, set up WIF for your service account (see `guides-wif-vault-practices.md`).
- **Azure:** See `guides-wif-vault-practices.md` for WIF setup.
- **AWS:** [OIDC example](https://github.com/Unity-Technologies/pre-terraform-services-workspace/tree/main/aws/modules/github-actions-oidc)

### Inputs

| parameter                  | description                                                                                                                                                     | required | default                           |
|----------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------|----------|-----------------------------------|
| cloud                      | Cloud (GCP or Azure or AWS)                                                                                                                                     | `false`  | `GCP`                             |
| image_name                 | Image name e.g. gcr.io/my-registry/my-image                                                                                                                     | `true`   |                                   |
| image_tag                  | Tags of the image, separated by commas in the string                                                                                                            | `false`  | `${GITHUB_SHA},${GITHUB_REF##*/}` |
| dockerfile_path            | Dockerfile Path                                                                                                                                                 | `false`  | `Dockerfile`                      |
| dockerfile_context         | Dockerfile Context                                                                                                                                              | `false`  | `.`                               |
| docker_build_extra_args    | Extra arguments for `docker build` command                                                                                                                      | `false`  |                                   |
| platforms                  | Comma-separated list of target platforms for multi-arch builds (e.g., `linux/amd64,linux/arm64`). Leave empty for single-arch build.                           | `false`  |                                   |
| lint                       | Whether to run Hadolint on the Dockerfile                                                                                                                       | `false`  | `true`                            |
| push                       | Whether to push the image to an image registry                                                                                                                  | `false`  | `true`                            |
| workload_identity_provider | Workload identity provider (Deprecated. Uses [PRE Centralized Workload Identity Provider](https://docs.internal.unity.com/pre-unity-identity-pools) by default) | `false`  |                                   |
| service_account            | Service Account used by workload identity provider (required for GCP)                                                                                           | `true`   |                                   |
| client-id                  | Client ID (required for Azure)                                                                                                                                  | `false`  |                                   |
| tenant-id                  | Tenant ID                                                                                                                                                       | `false`  |                                   |
| subscription-id            | Subscription ID (required for Azure)                                                                                                                            | `false`  |                                   |
| registry                   | ACR registry name (required for Azure)                                                                                                                          | `false`  |                                   |
| role-to-assume             | role to assume. should look like this: arn:aws:iam::111111111111:role/my-github-actions-role-test (required for AWS)                                            | `true`   |                                   |
| aws-region                 | AWS region defaults to us-east-1  (required for AWS)                                                                                                            | `false`  | `us-east-1`                       |
| install_cli                | If set to true, will attempt to install the Azure CLI.                                                                                                          | `false`  | `false`                           |

### Outputs

| parameter            | description                                                             |
| -------------------- | ----------------------------------------------------------------------- |
| docker_command_debug | Outputs the whole docker build command that was executed. Used by tests |

### Usage Examples

#### GCP example

```yaml
name: Build
on: [push, workflow_dispatch]
jobs:
  build:
    name: Build Image
    runs-on: [unity-linux-runner]
    permissions: write-all
    steps:
      - name: Checkout
        uses: actions/checkout@v3

      - name: Build
        uses: Unity-Technologies/github-actions-workflows/actions/build-docker-image@main
        with:
          # required

          # Use these values if you are pushing to unity-source
          image_name: gcr.io/unity-source/my-service
          service_account: ci-push@unity-source.iam.gserviceaccount.com

          # Use these values if you are pushing to unity-ads-common-prd
          image_name: gcr.io/unity-ads-common-prd/my-service
          service_account: ci-push@unity-ads-common-prd.iam.gserviceaccount.com

          # optional with default values
          dockerfile_path: Dockerfile
          dockerfile_context: .
          image_tag: ${GITHUB_SHA},${GITHUB_REF##*/}
          lint: "true"
          push: ${{ github.ref == 'refs/heads/main' }} # This will only push the image when you merge to main. You can also specify some other branch name or replace the whole expression with true or false
          # you can use this to e.g. pass arguments for docker build
          docker_build_extra_args: ""
```

#### Multi-architecture build example (GCP)

Build images for both amd64 and arm64 architectures. This is useful for supporting both x86 and ARM-based hosts (e.g., AWS Graviton, Apple Silicon).

```yaml
name: Build Multi-Arch
on: [push, workflow_dispatch]
jobs:
  build:
    name: Build Multi-Arch Image
    runs-on: [unity-linux-runner]
    permissions: write-all
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Build
        uses: Unity-Technologies/github-actions-workflows/actions/build-docker-image@main
        with:
          image_name: gcr.io/unity-source/my-service
          service_account: ci-push@unity-source.iam.gserviceaccount.com
          # Build for both amd64 and arm64
          platforms: linux/amd64,linux/arm64
          push: ${{ github.ref == 'refs/heads/main' }}
```

**Important notes for multi-arch builds:**

- Your Dockerfile must support cross-compilation. For Go applications, use `--platform=$BUILDPLATFORM` in the builder stage and set `GOOS`/`GOARCH` from `TARGETOS`/`TARGETARCH` build args.
- Multi-arch builds use QEMU emulation, so they may take longer than single-arch builds.
- When `push: false` with multi-arch, the build will only validate (no local image is created since multi-arch manifests can't be stored locally).

#### Fast multi-arch builds with native ARM runners (Recommended)

For significantly faster ARM builds, use native ARM runners instead of QEMU emulation. This approach builds each architecture in parallel on its native runner, then combines them into a multi-arch manifest.

Unity provides ARM runners (`unity-linux-runner-arm`) specifically for this purpose. Native ARM builds are typically **5-10x faster** than QEMU emulation.

See the [create-docker-manifest](#create-docker-manifest-action) section below for the complete workflow pattern, or use this example:

```yaml
name: Build Multi-Arch (Native Runners)
on: [push, workflow_dispatch]

env:
  IMAGE_NAME: gcr.io/unity-source/my-service
  SERVICE_ACCOUNT: ci-push@unity-source.iam.gserviceaccount.com

jobs:
  build-amd64:
    name: Build AMD64
    runs-on: [unity-linux-runner]
    permissions: write-all
    steps:
      - uses: actions/checkout@v4
      - uses: Unity-Technologies/github-actions-workflows/actions/build-docker-image@main
        with:
          image_name: ${{ env.IMAGE_NAME }}
          image_tag: ${{ github.sha }}-amd64
          service_account: ${{ env.SERVICE_ACCOUNT }}

  build-arm64:
    name: Build ARM64
    runs-on: [unity-linux-runner-arm]  # Native ARM runner - much faster!
    permissions: write-all
    steps:
      - uses: actions/checkout@v4
      - uses: Unity-Technologies/github-actions-workflows/actions/build-docker-image@main
        with:
          image_name: ${{ env.IMAGE_NAME }}
          image_tag: ${{ github.sha }}-arm64
          service_account: ${{ env.SERVICE_ACCOUNT }}

  create-manifest:
    name: Create Multi-Arch Manifest
    needs: [build-amd64, build-arm64]
    runs-on: [unity-linux-runner]
    permissions: write-all
    steps:
      - uses: Unity-Technologies/github-actions-workflows/actions/create-docker-manifest@main
        with:
          manifest_tag: ${{ env.IMAGE_NAME }}:${{ github.sha }}
          source_images: |
            ${{ env.IMAGE_NAME }}:${{ github.sha }}-amd64
            ${{ env.IMAGE_NAME }}:${{ github.sha }}-arm64
          service_account: ${{ env.SERVICE_ACCOUNT }}
```

#### Azure example

```yaml
name: Build
on: [push, workflow_dispatch]
jobs:
  build:
    name: Build Image
    runs-on: [unity-linux-runner]
    permissions: write-all
    steps:
      - name: Checkout
        uses: actions/checkout@v3

      - name: Build
        uses: Unity-Technologies/github-actions-workflows/actions/build-docker-image@main
        with:
          # required
          image_name: unitypreservices.azurecr.io/samples/github-actions-workflows
          cloud: Azure
          client-id: 72757a9c-a445-4746-b73f-1543dbcf3ef0
          subscription-id: 4ee421b8-272d-42f1-9d25-be0e8f33b9a8
          registry: unitypreservices

          # optional with default values
          dockerfile_path: Dockerfile
          dockerfile_context: .
          image_tag: ${GITHUB_SHA},${GITHUB_REF##*/}
          lint: "true"
          push: ${{ github.ref == 'refs/heads/main' }} # This will only push the image when you merge to main. You can also specify some other branch name or replace the whole expression with true or false

          # you can use this to e.g. pass arguments for docker build
          docker_build_extra_args: ""
```

#### AWS example

```yaml
name: Build
on: [push, workflow_dispatch]
jobs:
  build:
    name: Build Image
    runs-on: [unity-linux-runner]
    permissions: write-all
    steps:
      - name: Checkout
        uses: actions/checkout@v3

      - name: Build
        uses: Unity-Technologies/github-actions-workflows/actions/build-docker-image@main
        with:
          # required. Use your own values here.
          image_name: 866313802286.dkr.ecr.us-east-1.amazonaws.com/pre-services-test
          cloud: AWS
          role-to-assume: arn:aws:iam::866313802286:role/github-actions
          aws-region: us-east-1

          # optional with default values
          dockerfile_path: Dockerfile
          dockerfile_context: .
          image_tag: ${GITHUB_SHA},${GITHUB_REF##*/}
          lint: "true"
          push: ${{ github.ref == 'refs/heads/main' }} # This will only push the image when you merge to main. You can also specify some other branch name or replace the whole expression with true or false

          # you can use this to e.g. pass arguments for docker build
          docker_build_extra_args: ""
```

#### Caching image dependencies

Speed up builds by caching Dockerfile dependencies using the GitHub Actions cache. Example with yarn:

```yaml
name: Build
on: [push, workflow_dispatch]
jobs:
  build:
    name: Build Image
    runs-on: [unity-linux-runner]
    permissions: write-all
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      # Cache all the Dockerfile build dependencies
      - name: Actions Cache for docker cache mount
        id: cache
        uses: actions/cache@v4
        with:
          path: |
            /home/runner/_work/var-cache-apt/
            /home/runner/_work/var-lib-apt/
            /home/runner/_work/cache-pip/
            /home/runner/_work/yarn-berry-cache/
          key: docker-cache-${{ hashFiles('docker/base.Dockerfile') }}
          restore-keys: |
            docker-cache-

      # https://docs.docker.com/build/ci/github-actions/cache/#cache-mounts
      - name: Inject cache into docker
        uses: reproducible-containers/buildkit-cache-dance@5b6db76d1da5c8b307d5d2e0706d266521b710de # v3.1.2
        with:
          cache-map: |
            {
              "/home/runner/_work/var-cache-apt/": "/var/cache/apt",
              "/home/runner/_work/var-lib-apt/": "/var/lib/apt",
              "/home/runner/_work/cache-pip/": "/root/.cache/pip"
              "/home/runner/_work/yarn-berry-cache/": "/root/.yarn/berry/cache",
            }
          skip-extraction: ${{ steps.cache.outputs.cache-hit }}

      - name: Build
        uses: Unity-Technologies/github-actions-workflows/actions/build-docker-image@main
        with:
          # required. Use your own values here.
          image_name: gcr.io/unity-source/my-service
          service_account: ci-push@unity-source.iam.gserviceaccount.com

          # optional with default values
          dockerfile_path: Dockerfile
          dockerfile_context: .
          image_tag: ${GITHUB_SHA},${GITHUB_REF##*/}
          lint: "true"
          push: ${{ github.ref == 'refs/heads/main' }} # This will only push the image when you merge to main. You can also specify some other branch name or replace the whole expression with true or false

          # you can use this to e.g. pass arguments for docker build. Here we are using the cache-from and cache-to arguments to cache the image build.
          # This will cache the image build on the first run and use the cache on subsequent runs. The cache is stored in the GitHub Actions cache.
          docker_build_extra_args: |
            --cache-from type=gha
            --cache-to type=gha,mode=max
```

Use the [reproducible-containers/buildkit-cache-dance](https://github.com/reproducible-containers/buildkit-cache-dance) action to mount cache directories into the Docker build context. Then use `--mount=type=cache,target=/path/to/cache,sharing=locked` in your Dockerfile:

```Dockerfile
FROM node:22-bullseye-slim

WORKDIR /app

# Install Python and build-essential
# Use the cache mount to speed up the build
# Remove the docker-clean file to keep the downloaded packages
# echo to keep-cache file to ensure that we keep the downloaded packages
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    rm -f /etc/apt/apt.conf.d/docker-clean && \
    echo 'Binary::apt::APT::Keep-Downloaded-Packages "true";' >/etc/apt/apt.conf.d/keep-cache && \
    apt-get update && \
    apt-get install -y --no-install-recommends python3 build-essential
# Cleaning up is done in a separate step to ensure that the mounted cache is not removed
RUN rm -rf /var/lib/apt/lists/* && \
    apt-get clean

# Install pip dependencies
# Use the cache mount to speed up the build
RUN --mount=type=cache,target=/root/.cache/pip,sharing=locked \
    pip3 install mkdocs-techdocs-core==1.4.2
# Cleaning up is done in a separate step to ensure that the mounted cache is not removed
RUN pip3 cache purge

# Install yarn dependencies
# Use the cache mount to speed up the build
RUN --mount=type=cache,target=/root/.yarn/berry/cache,sharing=locked \
    yarn install --frozen-lockfile
# Cleaning up is done in a separate step to ensure that the mounted cache is not removed
RUN yarn cache clean
```

### Multi-architecture Dockerfile Example

When building multi-arch images, your Dockerfile needs to support cross-compilation. Here's an example for a Go application:

```Dockerfile
# syntax=docker/dockerfile:1
FROM --platform=$BUILDPLATFORM golang:1.21-alpine AS builder

# These ARGs are automatically provided by Docker Buildx
ARG TARGETOS
ARG TARGETARCH

WORKDIR /app
COPY . .

# Cross-compile for the target architecture
RUN CGO_ENABLED=0 GOOS=${TARGETOS:-linux} GOARCH=${TARGETARCH:-amd64} \
    go build -o /app/myservice .

# Use a multi-arch base image
FROM alpine:3.20
COPY --from=builder /app/myservice /usr/local/bin/myservice
ENTRYPOINT ["/usr/local/bin/myservice"]
```

Key points:
- Use `--platform=$BUILDPLATFORM` for the builder stage to run on the native architecture
- Use `TARGETOS` and `TARGETARCH` build args (provided by Buildx) for cross-compilation
- Use a multi-arch base image (like `alpine`, `debian`, `ubuntu`) for the final stage

### Recommended Usage

- Build your application outside Docker using language-specific tools; only copy runtime files into the image.
- Use [GitHub Actions cache](https://docs.github.com/en/actions/using-workflows/caching-dependencies-to-speed-up-workflows) for dependencies.
- Build an image on every commit to ensure image building always works.
- Disable pushing if you don't need to keep the image.
- Use continuous deployment and always deploy the image on main/master branch.
- Tag images with both the commit hash and the branch name (this is the default). Deploy using the commit hash tag for rollback clarity. Static tags like branch name are useful for test environments.
- Hadolint linting is enabled by default. Customize via `.hadolint.yaml` or disable by setting `lint: "false"`.

---

## create-docker-manifest (action)

### Description

Composite action that creates and pushes a multi-arch Docker manifest from architecture-specific images. Designed to work alongside the `build-docker-image` action to enable fast native multi-arch builds using architecture-specific runners.

### Why Native Builds Instead of QEMU Emulation?

| Approach | Pros | Cons |
|----------|------|------|
| QEMU (single job) | Simple setup, one job | Slow ARM builds (emulation) |
| Native (parallel jobs) | Fast builds, parallel execution | More workflow configuration |

For ARM builds, native runners are **significantly faster** than QEMU emulation. Unity provides ARM runners (`unity-linux-runner-arm`) specifically for this purpose.

### Inputs

| Name                       | Description                                                              | Required | Default                           |
| -------------------------- | ------------------------------------------------------------------------ | -------- | --------------------------------- |
| cloud                      | Cloud (GCP or Azure or AWS)                                              | `false`  | `GCP`                             |
| manifest_tag               | Tag for the multi-arch manifest (e.g., gcr.io/my-registry/my-image:v1.0) | `true`   |                                   |
| source_images              | Newline-separated list of source images to include in the manifest       | `true`   |                                   |
| workload_identity_provider | Workload identity provider (Deprecated. Uses PRE centralized by default) | `false`  |                                   |
| service_account            | Service Account used by workload identity provider (required for GCP)    | `false`  |                                   |
| client-id                  | Client ID (required for Azure)                                           | `false`  |                                   |
| tenant-id                  | Tenant ID                                                                | `false`  | `45b9a1d4-a8af-40da-8eca-96bebddf6fc7` |
| subscription-id            | Subscription ID (required for Azure)                                     | `false`  |                                   |
| registry                   | ACR registry name (required for Azure)                                   | `false`  |                                   |
| role-to-assume             | Role to assume for AWS                                                   | `false`  |                                   |
| aws-region                 | AWS region                                                               | `false`  | `us-east-1`                       |

### Outputs

| Name            | Description                        |
| --------------- | ---------------------------------- |
| manifest_digest | The digest of the created manifest |

### Usage Examples

#### Complete multi-arch build workflow (GCP)

```yaml
name: Build Multi-Arch (Native)
on: [push, workflow_dispatch]

env:
  IMAGE_NAME: gcr.io/my-project/my-service
  SERVICE_ACCOUNT: ci-push@my-project.iam.gserviceaccount.com

jobs:
  build-amd64:
    name: Build AMD64
    runs-on: [unity-linux-runner]
    permissions: write-all
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Build AMD64 Image
        uses: Unity-Technologies/github-actions-workflows/actions/build-docker-image@main
        with:
          image_name: ${{ env.IMAGE_NAME }}
          image_tag: ${{ github.sha }}-amd64
          service_account: ${{ env.SERVICE_ACCOUNT }}

  build-arm64:
    name: Build ARM64
    runs-on: [unity-linux-runner-arm]
    permissions: write-all
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Build ARM64 Image
        uses: Unity-Technologies/github-actions-workflows/actions/build-docker-image@main
        with:
          image_name: ${{ env.IMAGE_NAME }}
          image_tag: ${{ github.sha }}-arm64
          service_account: ${{ env.SERVICE_ACCOUNT }}

  create-manifest:
    name: Create Multi-Arch Manifest
    needs: [build-amd64, build-arm64]
    runs-on: [unity-linux-runner]
    permissions: write-all
    steps:
      - name: Create and push manifest
        uses: Unity-Technologies/github-actions-workflows/actions/create-docker-manifest@main
        with:
          manifest_tag: ${{ env.IMAGE_NAME }}:${{ github.sha }}
          source_images: |
            ${{ env.IMAGE_NAME }}:${{ github.sha }}-amd64
            ${{ env.IMAGE_NAME }}:${{ github.sha }}-arm64
          service_account: ${{ env.SERVICE_ACCOUNT }}
```

#### With multiple tags

To create manifests for multiple tags (e.g., commit SHA and branch name):

```yaml
  create-manifest:
    name: Create Multi-Arch Manifests
    needs: [build-amd64, build-arm64]
    runs-on: [unity-linux-runner]
    permissions: write-all
    strategy:
      matrix:
        tag:
          - ${{ github.sha }}
          - ${{ github.ref_name }}
    steps:
      - name: Create and push manifest
        uses: Unity-Technologies/github-actions-workflows/actions/create-docker-manifest@main
        with:
          manifest_tag: gcr.io/my-project/my-service:${{ matrix.tag }}
          source_images: |
            gcr.io/my-project/my-service:${{ github.sha }}-amd64
            gcr.io/my-project/my-service:${{ github.sha }}-arm64
          service_account: ci-push@my-project.iam.gserviceaccount.com
```

#### Azure example

```yaml
  create-manifest:
    name: Create Multi-Arch Manifest
    needs: [build-amd64, build-arm64]
    runs-on: [unity-linux-runner]
    permissions: write-all
    steps:
      - name: Create and push manifest
        uses: Unity-Technologies/github-actions-workflows/actions/create-docker-manifest@main
        with:
          cloud: Azure
          manifest_tag: myregistry.azurecr.io/my-service:${{ github.sha }}
          source_images: |
            myregistry.azurecr.io/my-service:${{ github.sha }}-amd64
            myregistry.azurecr.io/my-service:${{ github.sha }}-arm64
          client-id: ${{ vars.AZURE_CLIENT_ID }}
          subscription-id: ${{ vars.AZURE_SUBSCRIPTION_ID }}
          registry: myregistry
```

#### AWS example

```yaml
  create-manifest:
    name: Create Multi-Arch Manifest
    needs: [build-amd64, build-arm64]
    runs-on: [unity-linux-runner]
    permissions: write-all
    steps:
      - name: Create and push manifest
        uses: Unity-Technologies/github-actions-workflows/actions/create-docker-manifest@main
        with:
          cloud: AWS
          manifest_tag: 111111111111.dkr.ecr.us-east-1.amazonaws.com/my-service:${{ github.sha }}
          source_images: |
            111111111111.dkr.ecr.us-east-1.amazonaws.com/my-service:${{ github.sha }}-amd64
            111111111111.dkr.ecr.us-east-1.amazonaws.com/my-service:${{ github.sha }}-arm64
          role-to-assume: arn:aws:iam::111111111111:role/my-github-actions-role
          aws-region: us-east-1
```

---

## gcr-cleaner (action)

### Description

Composite action that cleans obsolete images from Google Container Registry (GCR) or Google Artifact Registry (GAR). Uses [gcr-cleaner](https://github.com/GoogleCloudPlatform/gcr-cleaner) underneath. Designed to run on a schedule to prevent unbounded image accumulation.

### Inputs

|         parameter          | description                                                                                                                                                     | required | default |
|:--------------------------:|:----------------------------------------------------------------------------------------------------------------------------------------------------------------|:--------:|:-------:|
|            repo            | The GCR or GAR repo, or any other registry                                                                                                                      |   Yes    |    -    |
|            keep            | Minimum most recent images to keep                                                                                                                              |    No    |   `0`   |
|           grace            | Relative duration in which to ignore references. This value is specified as a time duration value like "5s" or "3h".                                            |    No    |   `0`   |
|       tag_filter_any       | Delete images where any tag matches this regular expression                                                                                                     |    No    |  `''`   |
|       tag_filter_all       | Delete images where all tags match this regular expression                                                                                                      |    No    |  `''`   |
|          dry_run           | Do a noop on delete api call. Always `true` for PRs                                                                                                             |    No    | `false` |
| workload_identity_provider | Workload identity provider (Deprecated. Uses [PRE Centralized Workload Identity Provider](https://docs.internal.unity.com/pre-unity-identity-pools) by default) |    No    |  `''`   |
|      service_account       | Service Account used by workload identity provider.                                                                                                             |    No    |  `''`   |

### Key Notes

- The `recursive` gcr-cleaner option is ALWAYS `false`, to avoid accidentally deleting all repositories in a project.
- The `token` gcr-cleaner option is removed; authenticate using workload identity instead.
- It is **highly recommended** to use `dry-run: true` when first adding your repository and inspect the logs.
- Works with any project as long as you provide correct authentication. For WIF setup, see `guides-wif-vault-practices.md`.
- For `unity-source`: use `service_account: ci-push@unity-source.iam.gserviceaccount.com` and add your repo to the [IAM allowlist](https://github.com/Unity-Technologies/pre-terraform-unity-source-workspace/blob/53cb050a909e5432eaccea95626f8453016ea369/iam.tf#L498).
- For `unity-ads-common-prd`: use `service_account: ci-push@unity-ads-common-prd.iam.gserviceaccount.com` and add your repo [here](https://github.com/Unity-Technologies/mz-terraform-common-workspace/blob/b4bc1655ec933d8f00e514886c2984a6d85bc9e7/variables-local.tf#L155).
- Your workflow needs `permissions: write-all`.

### Usage Example

```yaml
name: GCR Cleaner

on:
  schedule:
    - cron: "0 0 * * *" # run daily

jobs:
  gcr-cleaner:
    runs-on: [unity-linux-runner]
    permissions: write-all
    steps:
      - uses: actions/checkout@v3

      - name: GCR Cleaner
        uses: Unity-Technologies/github-actions-workflows/actions/gcr-cleaner@main
        with:
          repo: gcr.io/unity-source/unity-services-dashboard
          keep: 50
          tag-filter-all: ^main-*
          dry-run: true
          service_account: ci-push@unity-source.iam.gserviceaccount.com
```

---

## vm-image-build (reusable workflow)

### Description

Reusable workflow that builds virtual machine and bare-metal images for GCP, AWS, and Azure using Packer. See the [quickstart guide](https://docs.internal.unity.com/pre-vm-images) for repository setup.

### Inputs

| parameter                      | description                                                                                                                                                                                          | required                                           | default                                                                                     |
|--------------------------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|----------------------------------------------------|---------------------------------------------------------------------------------------------|
| type                           | The type of images to build (Valid values: gcp, aws, azure, virtualbox)                                                                                                                              | `true`                                             |                                                                                             |
| directory                      | Directory containing Packer HCL files                                                                                                                                                                | `false`                                            | images/                                                                                     |
| debug                          | Enable debug logging for Packer                                                                                                                                                                      | `false`                                            | `false`                                                                                     |
| cost_center                    | Your cost center, used for billing purposes                                                                                                                                                          | `true`                                             |                                                                                             |
| skip_create_image              | Skip creating the image, will only validate and build the image without pushing it to the image registry                                                                                             | `false`                                            | `false`                                                                                     |
| aws_role_to_assume             | Role to assume for AWS                                                                                                                                                                               | `false` (Required for AWS)                         |                                                                                             |
| aws_region                     | AWS region to use when authenticating                                                                                                                                                                | `false` (Required for AWS)                         |                                                                                             |
| azure_client_id                | Client ID used to build images                                                                                                                                                                       | `false` (Required for Azure)                       | `97343d0c-9074-488e-96d7-1b670d45823a`                                                      |
| azure_client_secret_vault_path | Vault path to the client secret used to build images                                                                                                                                                 | `false` (Required for Azure)                       | `pre/data/github-actions-workflows/vm-image-build/azure/7022-pre-vm-image-builder password` |
| azure_subscription_id          | Subscription ID to build images in (**Note**: Images will be pushed to your own subscription ID specified in the Packer files)                                                                       | `false` (Required for Azure)                       | `d956f9cf-21bb-416d-a393-07f54c678128`                                                      |
| azure_tenant_id                | Tenant ID that the subscription is a part of                                                                                                                                                         | `false` (Required for Azure)                       | `45b9a1d4-a8af-40da-8eca-96bebddf6fc7`                                                      |
| gcp_workload_identity_provider | Workload identity provider to be used for authenticating to GCP (Deprecated. Uses [PRE Centralized Workload Identity Provider](https://docs.internal.unity.com/pre-unity-identity-pools) by default) | `false`                                            |                                                                                             |
| gcp_image_push_service_account | Account that can push to the image registry used by workload identity provider                                                                                                                       | `false` (Required for GCP)                         | `image-builder@unity-pre-vm-images-prd.iam.gserviceaccount.com`                             |
| install_cli                    | If set to true, will attempt to install the Azure CLI.                                                                                                                                               | `false`                                            | `false`                                                                                     |
| manifest_artifact_path         | If set, uploads the file(s) at the specified path to GitHub actions as artifact named {image_type}-{packer_template_file (excluding .pkr.hcl extension)}-manifest, to be used in later jobs.         | `false`                                            |                                                                                             |

### Secrets

| secret                | description                                                                                                                                                            | required | default |
| --------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------- | ------- |
| ENCRYPTED_VAULT_TOKEN | A GPG encrypted vault token encrypted with the github-actions-workflows/vm-image-build/global/github_actions_gpg_passphrase vault secret                               | `false`  |         |
| ENV_VAR_JSON          | JSON object containing environment variables to be exported to the build environment (e.g. {"MY_VAR": "MY_SECRET"}). Use only when secrets cannot be stored in Vault.' | `false`  |         |

### Usage Examples

#### Basic GCP example

```yaml
name: VM Image Build

on:
  push:
    paths:
      - .github/workflows/image-build.yaml
      - images/**

jobs:
  gcp_packer:
    name: "GCP"
    uses: Unity-Technologies/github-actions-workflows/.github/workflows/vm-image-build.yaml@main
    with:
      directory: images/gcp
      type: gcp
      cost_center: { { COST_CENTER } } # Replace with your cost center number. You can find your cost center in workday
      skip_create_image: ${{ github.ref != 'refs/heads/main' }} # Only push images on main branch
```

#### Using Vault secrets

Fetch a Vault token and encrypt it using GPG for passing between jobs (required due to GitHub Actions limitation on passing secrets between jobs):

```yaml
name: VM Image Build

on:
  push:
    paths:
      - .github/workflows/image-build.yaml
      - images/**

jobs:
  vault_token:
    name: "Fetch Vault Token"
    permissions:
      id-token: write # This is required for requesting the JWT token from GitHub
    runs-on: [unity-linux-runner]
    outputs:
      VAULT_TOKEN: ${{ steps.vault_token.outputs.out }}
    steps:
      - id: global-config
        uses: Unity-Technologies/github-actions-workflows/actions/global-config@main
      - name: Fetch GPG Signing Key
        id: fetch-gpg-key
        uses: hashicorp/vault-action@4c06c5ccf5c0761b6029f56cfb1dcf5565918a3b # v3.4.0
        with:
          url: https://vault.corp.unity3d.com
          role: github-actions-repos-all
          path: ${{ steps.global-config.outputs.vault-auth-path }}
          method: jwt
          secrets: pre/data/github-actions-workflows/vm-image-build/global/github_actions_gpg_passphrase GPG_PASSPHRASE | GPG_PASSPHRASE ;
      - name: Fetch Vault Token
        id: fetch-vault-token
        uses: hashicorp/vault-action@4c06c5ccf5c0761b6029f56cfb1dcf5565918a3b # v3.4.0
        with:
          url: https://vault.corp.unity3d.com
          role: { { VAULT_ROLE } } # Replace with your Vault role that has access to your secrets
          path: ${{ steps.global-config.outputs.vault-auth-path }}
          method: jwt
          outputToken: true
      - uses: cloudposse/github-action-secret-outputs@main
        name: Encrypt Vault Token
        id: vault_token
        with:
          secret: ${{ steps.fetch-gpg-key.outputs.GPG_PASSPHRASE }}
          op: encode
          in: ${{ steps.fetch-vault-token.outputs.vault_token }}

  gcp_packer:
    name: "GCP"
    uses: Unity-Technologies/github-actions-workflows/.github/workflows/vm-image-build.yaml@main
    needs: vault_token
    with:
      directory: images/gcp
      type: gcp
      cost_center: { { COST_CENTER } } # Replace with your cost center number. You can find your cost center in workday
      skip_create_image: ${{ github.ref != 'refs/heads/main' }} # Only push images on main branch
    secrets:
      ENCRYPTED_VAULT_TOKEN: ${{ needs.vault_token.outputs.VAULT_TOKEN }}
```

#### Using the Packer manifest

To access build outputs (image name, ID, etc.), configure Packer to generate a manifest and have the workflow upload it as a job artifact.

Add the `manifest` post-processor to your Packer template:

```hcl
build {
  post-processor "manifest" {
    output = "packer-manifest.json"
  }
}
```

Then set `manifest_artifact_path` and consume the artifact in a downstream job:

```yaml
name: VM Image Build

on:
  push:
    paths:
      - .github/workflows/image-build.yaml
      - images/**

jobs:
  aws_packer:
    name: "AWS"
    uses: Unity-Technologies/github-actions-workflows/.github/workflows/vm-image-build.yaml@main
    with:
      directory: images/aws # this directory would contain a file named ubuntu-20.04.pkr.hcl
      type: aws
      cost_center: { { COST_CENTER } } # Replace with your cost center number. You can find your cost center in workday
      aws_role_to_assume: { { AWS_ARN } } # Replace with your AWS ARN
      aws_region: { { AWS_REGION } } # AWS region used for auth
      skip_create_image: ${{ github.ref != 'refs/heads/main' }} # Only push images on main branch
      debug: true
      # Uncomment the line below to upload the packer manifest as a job artifact.
      # The uploaded artifact name is `{inputs.type}-{name of your packer template file, excluding .pkr.hcl extension}-manifest`
      # In this case, the artifact name would be `aws-ubuntu-20.04-manifest`.
#      manifest_artifact_path: packer-manifest.json

  # Example of how to use the outputted packer manifests (not required)
  get_aws_image_data:
    runs-on: unity-linux-runner
    name: Get AWS image ID and region
    needs: [aws_packer]
    steps:
      - name: Download packer manifest artifact
        uses: Unity-Technologies/download-artifact@v3 # can be v3 or v4 ..if invoking the flow from github.cds please use v3 else v4 - check source code here Unity-Technologies/github-actions-workflows/.github/workflows/vm-image-build.yaml 
        with:
          # You can use a specific name to download a single build manifest.
          name: aws-ubuntu-20.04-manifest
          # Uncomment the line below (and remove `name` above) to use a regex pattern targeting multiple manifests.
          # pattern: "aws-*-manifest"
          path: packer-manifests
      - name: Extract AWS AMI ID and region
        id: extract_ami_data
        run: |
          AMI_REGION=$(jq -r '.builds[-1].artifact_id' packer-manifests/aws-ubuntu-20.04-manifest/packer-manifest.json | cut -d "," -f1 | cut -d ":" -f1);
          AMI_ID=$(jq -r '.builds[-1].artifact_id' packer-manifests/aws-ubuntu-20.04-manifest/packer-manifest.json | cut -d "," -f1 | cut -d ":" -f2);
          echo "{ami_id}={$AMI_ID}" >> "$GITHUB_OUTPUT";
          echo "{ami_region}={$AMI_REGION}" >> "$GITHUB_OUTPUT";
      - name: Do stuff with AWS AMI ID and region
        run: |
          echo "AMI ID: ${{ steps.extract_ami_data.outputs.ami_id }}"
          echo "AMI Region: ${{ steps.extract_ami_data.outputs.ami_region }}"
```
