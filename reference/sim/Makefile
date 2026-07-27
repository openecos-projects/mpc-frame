SOC_ROOT := $(CURDIR)
APP ?= hello
TRACE ?= 0
MAX_CYCLES ?= 500000
BOOTROM_IMAGE ?= $(SOC_ROOT)/build/sw/mpc-soc/$(APP)/$(APP).bin

.PHONY: help sw verilate sim clean

help:
	@printf '%s\n' 'mpc-frame reference design'
	@printf '%s\n' '  make sw APP=<hello|gpio|psram|uart_poll>'
	@printf '%s\n' '  make verilate'
	@printf '%s\n' '  make sim BOOTROM_IMAGE=<image.bin>'

sw:
	@$(MAKE) -C sw APP=$(APP)

verilate:
	@$(MAKE) -C dv/verilator verilate TRACE=$(TRACE)

sim:
	@$(MAKE) -C dv/verilator sim TRACE=$(TRACE) MAX_CYCLES=$(MAX_CYCLES) \
		BOOTROM_IMAGE=$(BOOTROM_IMAGE)

clean:
	@$(MAKE) -C dv/verilator clean
