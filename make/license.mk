# This file contains makefile targets to update copyrights and third party notices in the repo

# --- Configurable license header settings ---
COPYRIGHT_YEAR          ?= $(shell date +%Y)
COPYRIGHT_OWNER         ?= NVIDIA CORPORATION & AFFILIATES
COPYRIGHT_STYLE         ?= apache
COPYRIGHT_FLAGS         ?= -s
COPYRIGHT_EXCLUDE       ?= vendor deployment config bundle .*
GIT_LS_FILES_EXCLUDES := $(foreach d,$(COPYRIGHT_EXCLUDE),:^"$(d)")

# --- Tool paths ---
BIN_DIR            ?= ./bin
ADDLICENSE         ?= $(BIN_DIR)/addlicense
ADDLICENSE_VERSION ?= latest

# Ensure bin dir exists
$(BIN_DIR):
	@mkdir -p $(BIN_DIR)

# Install addlicense locally
.PHONY: addlicense
addlicense: $(BIN_DIR)
	@if [ ! -f "$(ADDLICENSE)" ]; then \
		echo "Installing addlicense to $(ADDLICENSE)..."; \
		GOBIN=$(abspath $(BIN_DIR)) go install github.com/google/addlicense@$(ADDLICENSE_VERSION); \
	else \
		echo "addlicense already installed at $(ADDLICENSE)"; \
	fi

# Check headers
.PHONY: copyright-check
copyright-check: addlicense
	@echo "Checking copyright headers..."
	@git ls-files '*' $(GIT_LS_FILES_EXCLUDES) | xargs grep -ILi "$(COPYRIGHT_OWNER)" | xargs -r $(ADDLICENSE) -check -c "$(COPYRIGHT_OWNER)" -l $(COPYRIGHT_STYLE) $(COPYRIGHT_FLAGS) -y $(COPYRIGHT_YEAR)

# Fix headers
.PHONY: copyright
copyright: addlicense
	@echo "Adding copyright headers..."
	@git ls-files '*' $(GIT_LS_FILES_EXCLUDES) | xargs grep -ILi "$(COPYRIGHT_OWNER)" | xargs -r $(ADDLICENSE) -c "$(COPYRIGHT_OWNER)" -l $(COPYRIGHT_STYLE) $(COPYRIGHT_FLAGS) -y $(COPYRIGHT_YEAR)

# Generate THIRD_PARTY_NOTICES from go module cache
.PHONY: third-party-licenses
third-party-licenses:
	@echo "Downloading module dependencies..."
	@go mod download
	@echo "Collecting third-party licenses..."
	@> THIRD_PARTY_NOTICES
	@go mod download -json 2>/dev/null \
		| jq -r 'select(.Dir != null) | "\(.Path)@\(.Version)\t\(.Dir)"' \
		| sort \
		| while IFS=$$'\t' read -r mod dir; do \
			license=$$(find "$$dir" -maxdepth 1 \( -iname 'LICENSE*' -o -iname 'COPYING*' \) -print -quit 2>/dev/null); \
			if [ -n "$$license" ]; then \
				echo "---" >> THIRD_PARTY_NOTICES; \
				echo "## $$mod" >> THIRD_PARTY_NOTICES; \
				echo "" >> THIRD_PARTY_NOTICES; \
				cat "$$license" >> THIRD_PARTY_NOTICES; \
				echo "" >> THIRD_PARTY_NOTICES; \
			fi; \
		done
	@echo "THIRD_PARTY_NOTICES updated ($$(grep -c '^## ' THIRD_PARTY_NOTICES) modules)."