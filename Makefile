SHELL := /bin/bash

VERILATOR ?= verilator
PYTHON ?= python3
RTL_FILELIST := $(CURDIR)/rtl/filelist.f
REGISTRY_TOOL := $(CURDIR)/scripts/design_registry.py
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
REFERENCE_SIM_DIR := $(CURDIR)/reference/sim/dv/verilator
REFERENCE_FRAME_FILELIST := $(CURDIR)/reference/sim/hw/filelist/frame.f
REFERENCE_IMAGE ?= $(CURDIR)/reference/sim/sw/bootrom/hello/retrosoc_fw.bin
REFERENCE_GPIO_IMAGE := $(CURDIR)/reference/sim/build/sw/mpc-soc/gpio/gpio.bin
REFERENCE_PSRAM_IMAGE := $(CURDIR)/reference/sim/build/sw/mpc-soc/psram/psram.bin
CONTROL_TEST_DIR := $(CURDIR)/build/control-test

.PHONY: help lint lint-user registry-filelist registry-check registry-generate \
	design-lint design-test design-frame-test manifest-test stage5-test \
	control-test reference-verilate reference-sim reference-test clean

help:
	@printf '%s\n' 'mpc-frame build entry'
	@printf '%s\n' '  make lint       Lint FrameTop and every registered design'
	@printf '%s\n' '  make design-lint DESIGN=designs/1'
	@printf '%s\n' '  make design-test DESIGN=designs/1 [TEST=io]'
	@printf '%s\n' '  make design-frame-test DESIGN=designs/1 [TEST=frame]'
	@printf '%s\n' '  make registry-check     Validate manifests and generated registry RTL'
	@printf '%s\n' '  make registry-generate  Regenerate committed registry RTL'
	@printf '%s\n' '  make stage5-test        Run manifest, standalone, and FrameTop tests'
	@printf '%s\n' '  make control-test  Verify design selection, reset, clock gating, and IO isolation'
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
	@$(PYTHON) $(REGISTRY_TOOL) design-build --design $(DESIGN_MANIFEST) \
		--output-dir $(DESIGN_FRAME_DIR) --kind frame \
		--registry $(REGISTRY_MANIFEST) $(TEST_ARG)
	@top=$$(cat $(DESIGN_FRAME_DIR)/top.txt); \
	$(VERILATOR) --binary --timing --assert --Wall \
		-Wno-UNUSEDSIGNAL -Wno-UNUSEDPARAM -Wno-DECLFILENAME \
		-Wno-BLKSEQ -Wno-PROCASSINIT \
		--Mdir $(DESIGN_FRAME_DIR)/obj --top-module "$$top" \
		-f $(RTL_FILELIST) -f $(DESIGN_FRAME_DIR)/sources.f && \
	$(DESIGN_FRAME_DIR)/obj/V$$top

manifest-test:
	@$(PYTHON) -m unittest discover -s tests/registry -p 'test_*.py'

stage5-test: manifest-test design-test design-frame-test

control-test:
	@mkdir -p $(CONTROL_TEST_DIR)
	@$(VERILATOR) --binary --timing --assert --Wall \
		-Wno-UNUSEDSIGNAL -Wno-UNUSEDPARAM -Wno-DECLFILENAME \
		-Wno-BLKSEQ -Wno-PROCASSINIT \
		--Mdir $(CONTROL_TEST_DIR) --top-module FrameControlTb \
		rtl/FrameClockGate.sv rtl/FrameDesignControl.sv rtl/DesignIoMux.sv \
		tests/control/FrameControlTb.sv
	@$(CONTROL_TEST_DIR)/VFrameControlTb

reference-verilate: registry-filelist registry-check
	@$(MAKE) -C $(REFERENCE_SIM_DIR) verilate \
		TOP=FrameTop RTL_FILELIST=$(REFERENCE_FRAME_FILELIST) TRACE=0

reference-sim: registry-filelist registry-check
	@$(MAKE) -C $(REFERENCE_SIM_DIR) sim \
		TOP=FrameTop RTL_FILELIST=$(REFERENCE_FRAME_FILELIST) TRACE=0 \
		BOOTROM_IMAGE=$(REFERENCE_IMAGE) $(REFERENCE_SIM_ARGS)

reference-test: control-test design-frame-test reference-verilate
	@$(MAKE) -C reference/sim/sw APP=gpio DRIVERS='sys_uart gpio' LINK_TARGET=xip
	@$(MAKE) -C reference/sim/sw APP=psram DRIVERS=sys_uart LINK_TARGET=xip
	@$(MAKE) -C $(REFERENCE_SIM_DIR) sim TOP=FrameTop RTL_FILELIST=$(REFERENCE_FRAME_FILELIST) \
		TRACE=0 BOOTROM_IMAGE=$(REFERENCE_IMAGE) MAX_CYCLES=500000 UART_STOP_TEXT='done!'
	@$(MAKE) -C $(REFERENCE_SIM_DIR) sim TOP=FrameTop RTL_FILELIST=$(REFERENCE_FRAME_FILELIST) \
		TRACE=0 BOOTROM_IMAGE=$(CURDIR)/reference/sim/sw/bootrom/uart_poll/uart_poll.bin \
		MAX_CYCLES=1000000 UART_INPUT=Z UART_START_CYCLE=300000 \
		UART_STOP_TEXT='uart poll ok' UART_FAIL_TEXT='uart poll fail'
	@$(MAKE) -C $(REFERENCE_SIM_DIR) sim TOP=FrameTop RTL_FILELIST=$(REFERENCE_FRAME_FILELIST) \
		TRACE=0 BOOTROM_IMAGE=$(REFERENCE_GPIO_IMAGE) MAX_CYCLES=1000000 \
		UART_STOP_TEXT='gpio ok' UART_FAIL_TEXT='gpio fail' \
		GPIO_IN=0x0000000400000004 GPIO_DRIVE=0x0000000c0000000c \
		GPIO_EXPECT='1,2,3,0,0x100000000,0x200000000,0x300000000,0' \
		GPIO_EXPECT_MASK=0x300000003
	@$(MAKE) -C $(REFERENCE_SIM_DIR) sim TOP=FrameTop RTL_FILELIST=$(REFERENCE_FRAME_FILELIST) \
		TRACE=0 BOOTROM_IMAGE=$(REFERENCE_PSRAM_IMAGE) MAX_CYCLES=1000000 \
		UART_STOP_TEXT='psram ok' UART_FAIL_TEXT='psram fail'

clean:
	@rm -rf $(CURDIR)/build $(CURDIR)/reference/sim/build
