.PHONY: test test-unit test-integration test-modules clean deps fmt vet

# Default test timeout
TEST_TIMEOUT ?= 60m

# Test parallelism
TEST_PARALLELISM ?= 4

# Azure subscription for testing
export ARM_SUBSCRIPTION_ID ?= $(shell az account show --query id -o tsv)

deps:
	@echo "Installing Go dependencies..."
	go mod download
	go mod tidy

fmt:
	@echo "Formatting Go code..."
	go fmt ./...

vet:
	@echo "Running go vet..."
	go vet ./...

test-unit: deps fmt vet
	@echo "Running unit tests..."
	go test -v -timeout=$(TEST_TIMEOUT) -parallel=$(TEST_PARALLELISM) -run "TestACR.*Module" ./...

test-integration: deps fmt vet
	@echo "Running integration tests..."
	go test -v -timeout=$(TEST_TIMEOUT) -parallel=$(TEST_PARALLELISM) -run "TestACRPlatform.*" ./...

test-modules: test-unit

test: test-unit test-integration

test-registry:
	@echo "Testing ACR Registry module..."
	go test -v -timeout=$(TEST_TIMEOUT) -run "TestACRRegistry.*" ./...

test-rbac:
	@echo "Testing ACR RBAC module..."
	go test -v -timeout=$(TEST_TIMEOUT) -run "TestACRRBAC.*" ./...

test-network:
	@echo "Testing ACR Network module..."
	go test -v -timeout=$(TEST_TIMEOUT) -run "TestACRNetwork.*" ./...

clean:
	@echo "Cleaning test artifacts..."
	go clean -testcache
	rm -rf terraform.tfstate*
	rm -rf .terraform/

# Run tests with coverage
test-coverage: deps fmt vet
	@echo "Running tests with coverage..."
	go test -v -timeout=$(TEST_TIMEOUT) -parallel=$(TEST_PARALLELISM) -coverprofile=coverage.out ./...
	go tool cover -html=coverage.out -o coverage.html
	@echo "Coverage report generated: coverage.html"

# Validate Terraform configuration
validate:
	@echo "Validating Terraform configurations..."
	@for dir in ../modules/*/; do \
		echo "Validating $$dir"; \
		cd "$$dir" && terraform init -backend=false && terraform validate; \
		cd - > /dev/null; \
	done
	@for dir in ../environments/*/; do \
		echo "Validating $$dir"; \
		cd "$$dir" && terraform init -backend=false && terraform validate; \
		cd - > /dev/null; \
	done

# Security scan with tfsec
security-scan:
	@echo "Running security scan with tfsec..."
	@if command -v tfsec >/dev/null 2>&1; then \
		tfsec ../; \
	else \
		echo "tfsec not installed. Install with: go install github.com/aquasecurity/tfsec/cmd/tfsec@latest"; \
	fi

# Run all quality checks
quality: deps fmt vet validate security-scan test

help:
	@echo "Available targets:"
	@echo "  deps            - Install Go dependencies"
	@echo "  fmt             - Format Go code"
	@echo "  vet             - Run go vet"
	@echo "  test-unit       - Run unit tests for modules"
	@echo "  test-integration - Run integration tests"
	@echo "  test-modules    - Alias for test-unit"
	@echo "  test            - Run all tests"
	@echo "  test-registry   - Test ACR Registry module only"
	@echo "  test-rbac       - Test ACR RBAC module only"
	@echo "  test-network    - Test ACR Network module only"
	@echo "  test-coverage   - Run tests with coverage report"
	@echo "  validate        - Validate Terraform configurations"
	@echo "  security-scan   - Run security scan with tfsec"
	@echo "  quality         - Run all quality checks"
	@echo "  clean           - Clean test artifacts"
	@echo "  help            - Show this help message"