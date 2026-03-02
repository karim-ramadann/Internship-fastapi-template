# =============================================================================
# Root Makefile - CI and local build targets
# =============================================================================
# Targets below are intended for GitHub Actions (env provided by workflow).
# Required env: IMAGE_TAG, ECR_REGISTRY, ECR_REPOSITORY
# =============================================================================

.PHONY: build-backend push-backend build-push-backend

# Build backend Docker image (requires ECR_REGISTRY, ECR_REPOSITORY, IMAGE_TAG)
build-backend:
	@test -n "$$ECR_REGISTRY" || (echo "ECR_REGISTRY is required" && exit 1)
	@test -n "$$ECR_REPOSITORY" || (echo "ECR_REPOSITORY is required" && exit 1)
	@test -n "$$IMAGE_TAG" || (echo "IMAGE_TAG is required" && exit 1)
	docker build -t $(ECR_REGISTRY)/$(ECR_REPOSITORY):$(IMAGE_TAG) -f backend/Dockerfile .

# Push backend image to ECR (requires same env as build-backend)
push-backend:
	@test -n "$$ECR_REGISTRY" || (echo "ECR_REGISTRY is required" && exit 1)
	@test -n "$$ECR_REPOSITORY" || (echo "ECR_REPOSITORY is required" && exit 1)
	@test -n "$$IMAGE_TAG" || (echo "IMAGE_TAG is required" && exit 1)
	docker push $(ECR_REGISTRY)/$(ECR_REPOSITORY):$(IMAGE_TAG)

# Build and push in one step (for CI)
build-push-backend: build-backend push-backend

prek-run-all:
	uv run prek run --all-files
