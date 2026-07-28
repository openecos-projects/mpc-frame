SHELL := /bin/bash

VERILATOR ?= verilator
PYTHON ?= python3
TRACE ?= 0
RTL_FILELIST := $(CURDIR)/rtl/filelist.f
REGISTRY_TOOL := $(CURDIR)/scripts/design_registry.py
REGRESSION_TOOL := $(CURDIR)/scripts/run_regression.py
REGISTRY_MANIFEST := $(CURDIR)/designs/registry.json
REGISTRY_RTL := $(CURDIR)/rtl/generated/FrameDesignRegistry.sv
REGISTRY_FILELIST := $(CURDIR)/build/generated/user-designs.f
DESIGN ?= designs/1
DESIGN_MANIFEST := $(if $(filter %.json,$(DESIGN)),$(DESIGN),$(patsubst %/,%,$(DESIGN))/design.json)
DESIGN_DIR := $(patsubst %/,%,$(dir $(DESIGN_MANIFEST)))
DESIGN_KEY := $(notdir $(DESIGN_DIR))
DESIGN_BUILD_ROOT := $(CURDIR)/build/designs/$(DESIGN_KEY)
DESIGN_LINT_DIR := $(DESIGN_BUILD_ROOT)/lint
DESIGN_UNIT_DIR := $(DESIGN_BUILD_ROOT)/unit
DESIGN_FRAME_DIR := $(DESIGN_BUILD_ROOT)/frame
TEST_ARG := $(if $(TEST),--test $(TEST),)
FRAME_TEST_NAME := $(if $(TEST),$(TEST),frame)
FRAME_WAVE_FILE := $(CURDIR)/build/waves/$(DESIGN_KEY)/$(FRAME_TEST_NAME).fst
FRAME_TRACE_FLAGS := $(if $(filter 1,$(TRACE)),--trace-fst,)
FRAME_TRACE_ARG := $(if $(filter 1,$(TRACE)),--trace-file $(FRAME_WAVE_FILE),)
REFERENCE_SIM_DIR := $(CURDIR)/reference/sim/dv/verilator
REFERENCE_FRAME_FILELIST := $(CURDIR)/reference/sim/hw/filelist/frame.f
REFERENCE_IMAGE ?= $(CURDIR)/reference/sim/sw/bootrom/hello/retrosoc_fw.bin
CONTROL_TEST_DIR := $(CURDIR)/build/control-test
CONTENTION_TEST_DIR := $(CURDIR)/build/contention-test

.PHONY: help lint lint-user registry-filelist registry-check registry-generate \
	design-lint design-test design-frame-test manifest-test stage5-test \
	frame-test regression-fast regression control-test \
	io-contention-test reference-verilate reference-sim reference-test clean

help:
	@printf '%s\n' 'mpc-frame build entry'
	@printf '%s\n' '  make lint       Lint FrameTop and every registered design'
	@printf '%s\n' '  make design-lint DESIGN=designs/1'
	@printf '%s\n' '  make design-test DESIGN=designs/1 [TEST=io]'
	@printf '%s\n' '  make design-frame-test DESIGN=designs/1 [TEST=frame]'
	@printf '%s\n' '  make frame-test DESIGN=<0|designs/id> [TEST=name] [TRACE=1]'
	@printf '%s\n' '  make regression-fast [TRACE=1]  Run all registered design tests'
	@printf '%s\n' '  make regression [TRACE=1]       Add the complete reference tests'
	@printf '%s\n' '  make registry-check     Validate manifests and generated registry RTL'
	@printf '%s\n' '  make registry-generate  Regenerate committed registry RTL'
	@printf '%s\n' '  make stage5-test        Run manifest, standalone, and FrameTop tests'
	@printf '%s\n' '  make control-test  Verify design selection, reset, clock gating, and IO isolation'
	@printf '%s\n' '  make io-contention-test  Verify the external payload drive contract'
	@printf '%s\n' '  make reference-verilate  Build the reference design through FrameTop'
	@printf '%s\n' '  make reference-sim       Run a reference image through FrameTop'
	@printf '%s\n' '  make reference-test      Run the complete FrameTop reference acceptance test'

registry-filelist:
	@$(PYTHON) $(REGISTRY_TOOL) registry-filelist \
		--registry $(REGISTRY_MANIFEST) --filelist $(REGISTRY_FILELIST)

registry-check:
	@$(PYTHON) $(REGISTRY_TOOL) check-registry \
		--registry $(REGISTRY_MANIFEST) --output $(REGISTRY_RTL)

registry-generate:
	@$(PYTHON) $(REGISTRY_TOOL) generate-registry \
		--registry $(REGISTRY_MANIFEST) --output $(REGISTRY_RTL) \
		--filelist $(REGISTRY_FILELIST)

lint: registry-filelist registry-check
	@$(VERILATOR) --lint-only --timing --Wall \
		-Wno-UNUSEDSIGNAL -Wno-UNUSEDPARAM -Wno-DECLFILENAME \
		--top-module FrameTop -f $(RTL_FILELIST)

design-lint:
	@$(PYTHON) $(REGISTRY_TOOL) design-build --design $(DESIGN_MANIFEST) \
		--output-dir $(DESIGN_LINT_DIR)
	@top=$$(cat $(DESIGN_LINT_DIR)/top.txt); \
	$(VERILATOR) --lint-only --timing --Wall \
		-Wno-UNUSEDSIGNAL -Wno-UNUSEDPARAM -Wno-DECLFILENAME \
		--top-module "$$top" -f $(DESIGN_LINT_DIR)/sources.f

lint-user: design-lint

design-test:
	@$(PYTHON) $(REGISTRY_TOOL) design-build --design $(DESIGN_MANIFEST) \
		--output-dir $(DESIGN_UNIT_DIR) --kind unit $(TEST_ARG)
	@top=$$(cat $(DESIGN_UNIT_DIR)/top.txt); \
	$(VERILATOR) --binary --timing --assert --Wall \
		-Wno-UNUSEDSIGNAL -Wno-UNUSEDPARAM -Wno-DECLFILENAME \
		-Wno-BLKSEQ -Wno-PROCASSINIT \
		--Mdir $(DESIGN_UNIT_DIR)/obj --top-module "$$top" \
		-f $(DESIGN_UNIT_DIR)/sources.f && \
	$(DESIGN_UNIT_DIR)/obj/V$$top

design-frame-test: registry-filelist registry-check
	@mkdir -p $(dir $(FRAME_WAVE_FILE))
	@$(PYTHON) $(REGISTRY_TOOL) design-build --design $(DESIGN_MANIFEST) \
		--output-dir $(DESIGN_FRAME_DIR) --kind frame \
		--registry $(REGISTRY_MANIFEST) $(TEST_ARG) $(FRAME_TRACE_ARG)
	@top=$$(cat $(DESIGN_FRAME_DIR)/top.txt); \
	$(VERILATOR) --binary --timing --assert --Wall $(FRAME_TRACE_FLAGS) \
		-Wno-UNUSEDSIGNAL -Wno-UNUSEDPARAM -Wno-DECLFILENAME \
		-Wno-BLKSEQ -Wno-PROCASSINIT \
		--Mdir $(DESIGN_FRAME_DIR)/obj --top-module "$$top" \
		-f $(RTL_FILELIST) -f $(DESIGN_FRAME_DIR)/sources.f && \
	$(DESIGN_FRAME_DIR)/obj/V$$top

manifest-test:
	@$(PYTHON) -m unittest discover -s tests/registry -p 'test_*.py'

stage5-test: manifest-test design-test design-frame-test

frame-test:
	@$(PYTHON) $(REGRESSION_TOOL) --root $(CURDIR) --trace $(TRACE) frame \
		--design $(DESIGN) $(TEST_ARG)

regression-fast:
	@$(PYTHON) $(REGRESSION_TOOL) --root $(CURDIR) --trace $(TRACE) \
		regression --mode fast

regression:
	@$(PYTHON) $(REGRESSION_TOOL) --root $(CURDIR) --trace $(TRACE) \
		regression --mode full

control-test:
	@mkdir -p $(CONTROL_TEST_DIR)
	@$(VERILATOR) --binary --timing --assert --Wall \
		-Wno-UNUSEDSIGNAL -Wno-UNUSEDPARAM -Wno-DECLFILENAME \
		-Wno-BLKSEQ -Wno-PROCASSINIT \
		--Mdir $(CONTROL_TEST_DIR) --top-module FrameControlTb \
		rtl/FrameClockGate.sv rtl/FrameDesignControl.sv rtl/DesignIoMux.sv \
		tests/control/FrameControlTb.sv
	@$(CONTROL_TEST_DIR)/VFrameControlTb

io-contention-test: registry-filelist registry-check
	@mkdir -p $(CONTENTION_TEST_DIR)
	@$(VERILATOR) --binary --timing --assert --Wall \
		-Wno-UNUSEDSIGNAL -Wno-UNUSEDPARAM -Wno-DECLFILENAME \
		-Wno-BLKSEQ -Wno-PROCASSINIT \
		--Mdir $(CONTENTION_TEST_DIR) --top-module FrameIoContentionTb \
		-f $(RTL_FILELIST) tests/frame/FrameIoContentionTb.sv
	@$(CONTENTION_TEST_DIR)/VFrameIoContentionTb

reference-verilate: registry-filelist registry-check
	@$(MAKE) -C $(REFERENCE_SIM_DIR) verilate \
		TOP=FrameTop RTL_FILELIST=$(REFERENCE_FRAME_FILELIST) TRACE=$(TRACE)

reference-sim: registry-filelist registry-check
	@$(MAKE) -C $(REFERENCE_SIM_DIR) sim \
		TOP=FrameTop RTL_FILELIST=$(REFERENCE_FRAME_FILELIST) TRACE=$(TRACE) \
		BOOTROM_IMAGE=$(REFERENCE_IMAGE) $(REFERENCE_SIM_ARGS)

reference-test:
	@$(PYTHON) $(REGRESSION_TOOL) --root $(CURDIR) --trace $(TRACE) reference

clean:
	@rm -rf $(CURDIR)/build $(CURDIR)/reference/sim/build
