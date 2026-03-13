# --- OS Detection ---
UNAME_SYSTEM := $(shell uname -s)
ifeq ($(UNAME_SYSTEM), Linux)
	DETECTED_OS := linux
	SHA256_CMD := sha256sum
else ifeq ($(UNAME_SYSTEM), Darwin)
	DETECTED_OS := macos
	SHA256_CMD := shasum -a 256
endif
# --- OS Detection ---

# --- Architecture Detection ---
UNAME_PLATFORM := $(shell uname -m)
ifeq ($(UNAME_PLATFORM), x86_64)
    DETECTED_ARCH := x64
else ifeq ($(UNAME_PLATFORM), amd64)
    DETECTED_ARCH := x64
else ifeq ($(UNAME_PLATFORM), arm64)
    DETECTED_ARCH := arm64
endif
# --- Architecture Detection ---

# --- Tailwind Checksum ---
ifeq ($(DETECTED_OS)_$(DETECTED_ARCH), linux_x64)
    EXPECTED_HASH := 39e8d4e24b3c83b0a6e69e100a972fbc75d5fef8dce47b3ddac3cf92dea81fe3
else ifeq ($(DETECTED_OS)_$(DETECTED_ARCH), linux_arm64)
    EXPECTED_HASH := d87e6486bb3f70b04ef1dcaacc4ee6548a5a15fbf521b31bc24d2c774f68a951
else ifeq ($(DETECTED_OS)_$(DETECTED_ARCH), macos_x64)
    EXPECTED_HASH := 019e5cfa441992ede2772c6faaeb8d7fb1726aab50b1138c0aa38e88f4b7bd44
else ifeq ($(DETECTED_OS)_$(DETECTED_ARCH), macos_arm64)
    EXPECTED_HASH := e510af7928750c9ee8d5ff2e5e98088bd5b99a8a8e2c554668621c7e151fa91f
endif
# --- Tailwind Checksum ---

DIST_DIR := dist
ASSETS_DIR := assets
CONTENT_DIR := content
BIN_DIR := bin

TAILWIND_VERSION := v4.2.1
TAILWIND_URL := https://github.com/tailwindlabs/tailwindcss/releases/download/${TAILWIND_VERSION}/tailwindcss-${DETECTED_OS}-${DETECTED_ARCH}
TAILWIND_BIN := ${BIN_DIR}/tailwindcss-${TAILWIND_VERSION}

.PHONY: clean clean_bin
clean: clean_bin clean_dist

clean_bin:
	@rm -rf ${BIN_DIR}/* > /dev/null 2>&1 | true

clean_dist:
	@rm -rf ${DIST_DIR}/* 2>&1 | true

.PHONY: tailwind_bin
tailwind_bin: $(TAILWIND_BIN)
$(TAILWIND_BIN):
	@echo "Downloading $(TAILWIND_BIN)..."
	curl --fail --show-error --location --output $(TAILWIND_BIN) $(TAILWIND_URL)
	chmod +x $(TAILWIND_BIN)

.PHONY: tailwind_verify
tailwind_verify:
	@if [ -z "$(EXPECTED_HASH)" ]; then \
		echo "Error: No expected hash defined for $(DETECTED_OS)_$(DETECTED_ARCH)."; \
		exit 1; \
	fi
	@echo "Verifying SHA-256 checksum..."
	@echo "$(EXPECTED_HASH)  $(TAILWIND_BIN)" | $(SHA256_CMD) -c -
	@echo "Checksum verified successfully!"

.PHONY: detect
detect:
	@echo "Detected OS   : $(DETECTED_OS)"
	@echo "Detected Arch : $(DETECTED_ARCH)"
	@echo "Tailwind URL  : $(TAILWIND_URL)"
	@echo "Tailwind Bin  : $(TAILWIND_BIN)"
	@echo "Expected Hash : $(EXPECTED_HASH)"

.PHONY: build build_dist build_docker
build: build_dist build_docker

build_dist: $(TAILWIND_BIN) tailwind_verify
	@echo "Copy ${ASSETS_DIR}..."
	@cp -r ${ASSETS_DIR}/* ${DIST_DIR}/
	@echo "Generate index.html..."
	@go run generate.go
	@echo "Generate style.css..."
	@${TAILWIND_BIN} -o ${DIST_DIR}/style.css --content ${DIST_DIR}/index.html --minify
	@echo "Generate index.json..."
	@jq -s add ${CONTENT_DIR}/*.json | jq 'walk(if type == "object" then del(._style) else . end)' > ${DIST_DIR}/index.json

DOCKER_IMAGE := eraac/resume:$(shell git describe --always --dirty --tags)

build_docker:
	@docker build -f production/docker/Dockerfile -t ${DOCKER_IMAGE} .

.PHONY: publish
publish:
	@docker push ${DOCKER_IMAGE}

.PHONY: test_docker
test_docker:
	@docker stop resume-test > /dev/null 2>&1 | true # in case of previous test failure, ensure the container is deleted
	@docker build -f production/docker/Dockerfile -t resume:test .
	@docker run --name resume-test --rm -d -p 8080:8080 resume:test
	@sleep 2 # let's some time for nginx to start
	@tests/nginx.sh
	@docker stop resume-test

.PHONY: all
all: build test_docker publish
