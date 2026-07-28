SOC_ROOT := $(abspath ../..)
FRAME_ROOT := $(abspath $(SOC_ROOT)/../..)
SHELL := /bin/bash
VERILATOR ?= verilator
TOP := FrameTop
BOARD ?= mpc-soc
APP ?= hello
TRACE ?= 1
MAX_CYCLES ?= 200000
FAST_PSRAM ?= 1
UART_INPUT ?=
UART_START_CYCLE ?= 10000
UART_STOP_TEXT ?=
UART_FAIL_TEXT ?=
GPIO_IN ?=
GPIO_DRIVE ?=
GPIO_EXPECT ?=
GPIO_EXPECT_MASK ?=
EXTRA_VERILATOR_FLAGS ?=

BUILD_DIR ?= $(SOC_ROOT)/build/verilator
OBJ_DIR := $(BUILD_DIR)/obj_dir_$(TOP)
WAVE_DIR := $(SOC_ROOT)/build/wave
LOG_DIR := $(SOC_ROOT)/build/log
RTL_FILELIST ?= $(SOC_ROOT)/hw/filelist/frame.f
SOC_PKG ?= $(SOC_ROOT)/hw/include/soc_pkg.sv
BOOTROM_DIR ?= $(SOC_ROOT)/build/sw/$(BOARD)/$(APP)
DEFAULT_BOOTROM_IMAGE = $(shell images=$$(find "$(BOOTROM_DIR)" -maxdepth 1 -type f -name '*.bin' 2>/dev/null | sort); preferred=$$(printf '%s\n' "$$images" | grep -v '/app\.bin$$' | head -n 1); if [ -n "$$preferred" ]; then printf '%s' "$$preferred"; else printf '%s\n' "$$images" | head -n 1; fi)
BOOTROM_IMAGE ?= $(DEFAULT_BOOTROM_IMAGE)
SW_IMAGE ?= $(BOOTROM_IMAGE)
SIM_BIN := $(OBJ_DIR)/V$(TOP)
BUILD_CONFIG := $(OBJ_DIR)/.build-config
WAVE_FILE ?= $(WAVE_DIR)/$(TOP).fst
WAVE_VIEW ?= $(CURDIR)/$(TOP).gtkw
SIM_LOG ?= $(LOG_DIR)/$(TOP)-$(notdir $(basename $(SW_IMAGE))).log
RUN_ARGS ?= +bootrom=$(SW_IMAGE) +wave=$(WAVE_FILE) +max-cycles=$(MAX_CYCLES) $(if $(UART_INPUT),'+uart-in=$(UART_INPUT)' +uart-start-cycle=$(UART_START_CYCLE),) $(if $(UART_STOP_TEXT),'+uart-stop-text=$(UART_STOP_TEXT)',) $(if $(UART_FAIL_TEXT),'+uart-fail-text=$(UART_FAIL_TEXT)',) $(if $(GPIO_IN),+gpio-in=$(GPIO_IN),) $(if $(GPIO_DRIVE),+gpio-drive=$(GPIO_DRIVE),) $(if $(GPIO_EXPECT),+gpio-expect=$(GPIO_EXPECT),) $(if $(GPIO_EXPECT_MASK),+gpio-expect-mask=$(GPIO_EXPECT_MASK),)
CLR_RESET := \033[0m
CLR_INFO := \033[1;34m
CLR_STEP := \033[1;32m
CLR_ERR := \033[1;31m

VERILATOR_PROCASSINIT_FLAG = $(shell tmp=$$(mktemp /tmp/verilator-probe.XXXXXX.v); printf 'module m; endmodule\n' > $$tmp; if $(VERILATOR) -Wno-PROCASSINIT --lint-only $$tmp >/dev/null 2>&1; then printf '%s' '-Wno-PROCASSINIT'; fi; rm -f $$tmp)
VERILATOR_FLAGS ?= -Wall -Wno-UNUSEDPARAM -Wno-UNUSEDSIGNAL -Wno-DECLFILENAME -Wno-PINCONNECTEMPTY -Wno-TIMESCALEMOD -Wno-DEFPARAM -Wno-BLKSEQ $(VERILATOR_PROCASSINIT_FLAG) -Wno-CASEINCOMPLETE -Wno-UNOPTFLAT -Wno-SYNCASYNCNET -Wno-GENUNNAMED -DFAST_FLASH --timescale-override 1ns/1ns --timing --cc --exe --build
ifeq ($(FAST_PSRAM),1)
VERILATOR_FLAGS += -DFAST_PSRAM
endif
VERILATOR_FLAGS += $(EXTRA_VERILATOR_FLAGS)
VERILATOR_FLAGS += --Mdir $(OBJ_DIR) --top-module $(TOP)
VERILATOR_FLAGS += -CFLAGS "-std=c++17 -O2 -DSIM_TOP_HEADER=\\\"V$(TOP).h\\\" -DSIM_TOP_CLASS=V$(TOP)"

RTL_SOURCES := $(shell find $(SOC_ROOT)/hw -type f \( -name '*.v' -o -name '*.sv' -o -name '*.vh' -o -name '*.svh' -o -name '*.f' \))
FRAME_RTL_SOURCES := $(FRAME_ROOT)/FrameTop.sv $(shell find $(FRAME_ROOT)/rtl $(FRAME_ROOT)/designs -type f \( -name '*.v' -o -name '*.sv' -o -name '*.vh' -o -name '*.svh' -o -name '*.f' -o -name '*.json' \))
RTL_SOURCES += $(FRAME_RTL_SOURCES)
HARNESS_SOURCES := $(shell find $(CURDIR)/csrc -type f \( -name '*.c' -o -name '*.cc' -o -name '*.cpp' -o -name '*.h' -o -name '*.hpp' \))
SOC_PKG_INPUTS := $(SOC_ROOT)/config/memory.yml $(SOC_ROOT)/scripts/gen_soc_pkg.py

VERILATOR_FLAGS += -DFRAME_USE_REFERENCE -DFRAME_SIM_MODELS

ifeq ($(TRACE),1)
VERILATOR_FLAGS += --trace-fst -CFLAGS "-DVM_TRACE=1"
endif

.PHONY: help check-tools check-image gen-soc-pkg verilate sim wave clean FORCE

help:
	@printf "$(CLR_INFO)Verilator simulation entry$(CLR_RESET)\n"
	@printf "  make -C dv/verilator verilate\n"
	@printf "  make -C dv/verilator sim [BOOTROM_IMAGE=<image.bin>] [MAX_CYCLES=200000] [FAST_PSRAM=1]\n"
	@printf "  make -C dv/verilator wave\n\n"
	@printf "$(CLR_INFO)Inputs:$(CLR_RESET)\n"
	@printf "  RTL_FILELIST=$(RTL_FILELIST)\n"
	@printf "  SOC_PKG=$(SOC_PKG)\n"
	@printf "  BOOTROM_DIR=$(BOOTROM_DIR)\n"
	@printf "  SW_IMAGE=$(SW_IMAGE)\n"
	@printf "  FAST_PSRAM=$(FAST_PSRAM)\n"
	@printf "  UART_INPUT=$(UART_INPUT)\n"
	@printf "  UART_STOP_TEXT=$(UART_STOP_TEXT)\n"
	@printf "  UART_FAIL_TEXT=$(UART_FAIL_TEXT)\n"
	@printf "  GPIO_IN=$(GPIO_IN)\n"
	@printf "  GPIO_DRIVE=$(GPIO_DRIVE)\n"
	@printf "  GPIO_EXPECT=$(GPIO_EXPECT)\n"
	@printf "  GPIO_EXPECT_MASK=$(GPIO_EXPECT_MASK)\n"

$(BUILD_DIR) $(WAVE_DIR) $(LOG_DIR):
	@mkdir -p $@

check-tools:
	@command -v $(VERILATOR) >/dev/null 2>&1 || (printf "$(CLR_ERR)ERROR: verilator not found. Install Verilator or set VERILATOR=/path/to/verilator$(CLR_RESET)\n"; exit 127)

check-image:
	@test -f $(SW_IMAGE) || (printf "$(CLR_ERR)ERROR: bootrom image not found: $(SW_IMAGE)$(CLR_RESET)\n"; printf "$(CLR_ERR)Place a raw flash image at $(BOOTROM_IMAGE) or pass BOOTROM_IMAGE=<file>$(CLR_RESET)\n"; exit 2)

gen-soc-pkg: $(SOC_PKG)

$(SOC_PKG): $(SOC_PKG_INPUTS)
	@python3 $(SOC_ROOT)/scripts/gen_soc_pkg.py --output $(SOC_PKG)

FORCE:

$(BUILD_CONFIG): FORCE | $(BUILD_DIR)
	@mkdir -p $(OBJ_DIR)
	@{ \
		printf '%s\n' 'VERILATOR=$(VERILATOR)'; \
		printf '%s\n' 'TOP=$(TOP)'; \
		printf '%s\n' 'TRACE=$(TRACE)'; \
		printf '%s\n' 'FAST_PSRAM=$(FAST_PSRAM)'; \
		printf '%s\n' 'RTL_FILELIST=$(RTL_FILELIST)'; \
		printf '%s\n' 'VERILATOR_FLAGS=$(VERILATOR_FLAGS)'; \
	} > $@.tmp
	@cmp -s $@.tmp $@ || mv $@.tmp $@
	@rm -f $@.tmp

$(SIM_BIN): $(BUILD_CONFIG) $(RTL_SOURCES) $(HARNESS_SOURCES) $(SOC_PKG) | $(BUILD_DIR) $(WAVE_DIR) $(LOG_DIR)
	@$(VERILATOR) $(VERILATOR_FLAGS) -f $(RTL_FILELIST) $(CURDIR)/csrc/sim_main.cpp

verilate: check-tools gen-soc-pkg $(SIM_BIN)

sim: check-image verilate
	@printf "$(CLR_STEP)Running $(SIM_BIN)$(CLR_RESET)\n"
	@printf "$(CLR_STEP)Boot ROM: $(SW_IMAGE)$(CLR_RESET)\n"
	@printf "$(CLR_STEP)Log: $(SIM_LOG)$(CLR_RESET)\n"
	@set -o pipefail; $(SIM_BIN) $(RUN_ARGS) | tee $(SIM_LOG)

wave:
	@test -f $(WAVE_FILE) || (printf "$(CLR_ERR)ERROR: wave not found: $(WAVE_FILE)$(CLR_RESET)\n"; exit 2)
	@if [ -f "$(WAVE_VIEW)" ]; then gtkwave "$(WAVE_VIEW)" & else gtkwave "$(WAVE_FILE)" & fi

clean:
	@rm -rf $(BUILD_DIR) $(WAVE_FILE) $(SIM_LOG)
