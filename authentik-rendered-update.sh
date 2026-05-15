#!/usr/bin/env bash

helm template authentik authentik/authentik \
  --version 2026.2.3 \
  --values ./authentik/base/my-values.yaml \
  --include-crds > ./authentik/base/rendered-authentik.yaml
