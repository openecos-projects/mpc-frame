SHELL := /bin/bash

FRAME_ROOT := $(CURDIR)
FRAME_MAKEFILE := $(firstword $(MAKEFILE_LIST))
VERILATOR ?= verilator
GTKWAVE ?= gtkwave
PYTHON ?= python3
CXX ?= c++
TRACE ?= 0
VERILATOR_RECOMMENDED_VERSION := 5.050

# PROCASSINIT is not available in every otherwise compatible Verilator release.
VERILATOR_PROCASSINIT_FLAG = $(shell \
	tmp=$$(mktemp /tmp/mpc-frame-verilator-probe.XXXXXX.sv); \
	printf 'module m; endmodule\n' > $$tmp; \
	if $(VERILATOR) -Wno-PROCASSINIT --lint-only $$tmp >/dev/null 2>&1; then \
		printf '%s' '-Wno-PROCASSINIT'; \
	fi; \
	rm -f $$tmp)

REGISTRY_TOOL := $(FRAME_ROOT)/scripts/design_registry.py
REGISTRY_MANIFEST ?= $(FRAME_ROOT)/designs/registry.json
REGISTRY_RTL ?= $(FRAME_ROOT)/rtl/generated/FrameDesignRegistry.sv
REGISTRY_FILELIST ?= $(FRAME_ROOT)/rtl/generated/user-designs.f
DESIGN_TEMPLATE := $(FRAME_ROOT)/designs/template

DESIGN ?=
DESIGN_MANIFEST := $(if $(filter %.json,$(DESIGN)),$(DESIGN),$(patsubst %/,%,$(DESIGN))/design.json)
DESIGN_DIR := $(patsubst %/,%,$(dir $(DESIGN_MANIFEST)))
DESIGN_KEY := $(notdir $(DESIGN_DIR))
DESIGN_BUILD_ROOT := $(FRAME_ROOT)/build/designs/$(DESIGN_KEY)
DESIGN_LINT_DIR := $(DESIGN_BUILD_ROOT)/lint
DESIGN_UNIT_DIR := $(DESIGN_BUILD_ROOT)/unit
DESIGN_FRAME_DIR := $(DESIGN_BUILD_ROOT)/frame
TEST_ARG := $(if $(TEST),--test $(TEST),)
FRAME_TEST_NAME := $(if $(TEST),$(TEST),frame)
FRAME_WAVE_FILE := $(FRAME_ROOT)/build/waves/$(DESIGN_KEY)/$(FRAME_TEST_NAME).fst
FRAME_TRACE_FLAGS := $(if $(filter 1,$(TRACE)),--trace-fst,)
FRAME_TRACE_ARG := $(if $(filter 1,$(TRACE)),--trace-file $(FRAME_WAVE_FILE),)

NAME ?=
TOP_NAME ?=
DESIGN_OUTPUT ?= $(FRAME_ROOT)/designs/$(NAME)
CREATE_TOP_ARG := $(if $(TOP_NAME),--module $(TOP_NAME),)
USER_DESIGN_ARG := $(if $(DESIGN),--design $(DESIGN),)

.PHONY: require-design
require-design:
	@test -n "$(DESIGN)" || (printf '%s\n' \
		'ERROR: DESIGN is required, for example DESIGN=designs/counter32'; exit 2)
