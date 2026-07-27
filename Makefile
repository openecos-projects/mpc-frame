SHELL := /bin/bash

VERILATOR ?= verilator
RTL_FILELIST := $(CURDIR)/rtl/filelist.f
RTL_SOURCES := $(CURDIR)/rtl/DesignIoMux.sv \
               $(CURDIR)/rtl/ReferenceDesign0.sv \
               $(CURDIR)/rtl/UserDesignSlot.sv \
               $(CURDIR)/FrameTop.sv
REFERENCE_SIM_DIR := $(CURDIR)/reference/sim/dv/verilator
REFERENCE_FRAME_FILELIST := $(CURDIR)/reference/sim/hw/filelist/frame.f
REFERENCE_IMAGE ?= $(CURDIR)/reference/sim/sw/bootrom/hello/retrosoc_fw.bin
REFERENCE_GPIO_IMAGE := $(CURDIR)/reference/sim/build/sw/mpc-soc/gpio/gpio.bin
REFERENCE_PSRAM_IMAGE := $(CURDIR)/reference/sim/build/sw/mpc-soc/psram/psram.bin

.PHONY: help lint lint-user reference-verilate reference-sim reference-test clean

help:
	@printf '%s\n' 'mpc-frame build entry'
	@printf '%s\n' '  make lint       Lint FrameTop and all 128 design slots'
	@printf '%s\n' '  make lint-user  Lint the example user design'
	@printf '%s\n' '  make reference-verilate  Build the reference design through FrameTop'
	@printf '%s\n' '  make reference-sim       Run a reference image through FrameTop'
	@printf '%s\n' '  make reference-test      Run the complete FrameTop reference acceptance test'

lint:
	@$(VERILATOR) --lint-only --timing --Wall \
		-Wno-UNUSEDSIGNAL -Wno-UNUSEDPARAM -Wno-DECLFILENAME \
		--top-module FrameTop -f $(RTL_FILELIST)

lint-user:
	@$(VERILATOR) --lint-only --timing --Wall \
		-Wno-UNUSEDSIGNAL -Wno-UNUSEDPARAM -Wno-DECLFILENAME \
		--top-module UserDesign1 $(RTL_SOURCES) \
		examples/user_design/design1/UserDesign1.sv

reference-verilate:
	@$(MAKE) -C $(REFERENCE_SIM_DIR) verilate \
		TOP=FrameTop RTL_FILELIST=$(REFERENCE_FRAME_FILELIST) TRACE=0

reference-sim:
	@$(MAKE) -C $(REFERENCE_SIM_DIR) sim \
		TOP=FrameTop RTL_FILELIST=$(REFERENCE_FRAME_FILELIST) TRACE=0 \
		BOOTROM_IMAGE=$(REFERENCE_IMAGE) $(REFERENCE_SIM_ARGS)

reference-test: reference-verilate
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
	@rm -rf $(CURDIR)/reference/sim/build
