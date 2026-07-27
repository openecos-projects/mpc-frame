include ecos.mk

BOARD ?= mpc-soc
APP ?= hello
LINK_TARGET ?= xip
DRIVERS ?= sys_uart gpio
FIRMWARE_NAME ?= $(APP)
FIRMWARE_VERSION ?= 1.0.0
CPU_FREQ_MHZ ?= 50
TIMER_FREQ_MHZ ?= 50
UART_BAUD_RATE ?= 115200
BOARD_FLASH_SIZE_KB ?= 64
BOARD_RAM_SIZE_KB ?= 24576
BOARD_RAM_TYPE_NAME ?= PSRAM

PORT_DIR := ecos
BOARD_PACKAGE_DIR := $(PORT_DIR)
APP_DIR := $(PORT_DIR)/templates/$(APP)
BUILD_DIR := $(SOC_ROOT)/build/sw/$(BOARD)/$(APP)
TARGET := $(BUILD_DIR)/$(APP).elf
AUTOCONF_H := $(BUILD_DIR)/generated/autoconf.h
LINKER_INPUT ?= $(if $(wildcard $(APP_DIR)/sections.lds),$(APP_DIR)/sections.lds,$(BOARD_PACKAGE_DIR)/sections.lds)
LINKER_SCRIPT := $(BUILD_DIR)/sections.lds
LINK_DEFS :=
ifeq ($(LINK_TARGET),xip)
LINK_DEFS += -DCONFIG_LINK_TARGET_XIP
LINK_TARGET_CONFIG := XIP
else ifeq ($(LINK_TARGET),mem)
LINK_DEFS += -DCONFIG_LINK_TARGET_MEM
LINK_TARGET_CONFIG := MEM
else
$(error unsupported LINK_TARGET=$(LINK_TARGET), expected xip or mem)
endif
CLR_RESET := \033[0m
CLR_INFO := \033[1;34m
CLR_ERR := \033[1;31m

DRIVER_C_SRCS := $(foreach driver,$(DRIVERS),$(wildcard $(BOARD_PACKAGE_DIR)/driver/$(driver)/*.c))
APP_C_SRCS := $(wildcard $(APP_DIR)/*.c)
C_SRCS := $(APP_C_SRCS) $(DRIVER_C_SRCS)
S_SRCS := $(if $(wildcard $(APP_DIR)/start.S),$(APP_DIR)/start.S,$(BOARD_PACKAGE_DIR)/start.S)
OBJS := $(patsubst %.c,$(BUILD_DIR)/%.o,$(C_SRCS))
OBJS += $(patsubst %.S,$(BUILD_DIR)/%.o,$(S_SRCS))

BOARD_INCLUDES := -I$(SOC_ROOT)/sw/$(BOARD_PACKAGE_DIR)
BOARD_INCLUDES += $(foreach dir,$(wildcard $(SOC_ROOT)/sw/$(BOARD_PACKAGE_DIR)/driver/*),-I$(dir))
BOARD_INCLUDES += -I$(BUILD_DIR)
APP_INCLUDES := -I$(SOC_ROOT)/sw/$(APP_DIR)

.PHONY: all check-board check-app info list clean

all: check-board check-app $(TARGET)
	@$(SIZE) $(TARGET)

check-board:
	@test -f $(BOARD_PACKAGE_DIR)/board.h || (printf "$(CLR_ERR)ERROR: board package not found: $(BOARD_PACKAGE_DIR)$(CLR_RESET)\n"; exit 2)

check-app:
	@test -d $(APP_DIR) || (printf "$(CLR_ERR)ERROR: app template not found: $(APP_DIR)$(CLR_RESET)\n"; printf "$(CLR_ERR)Try: make -C sw list$(CLR_RESET)\n"; exit 2)
	@test -n "$(APP_C_SRCS)" || (printf "$(CLR_ERR)ERROR: no C sources found under $(APP_DIR)$(CLR_RESET)\n"; exit 2)

info:
	@printf "$(CLR_INFO)BOARD=$(BOARD)$(CLR_RESET)\n"
	@printf "$(CLR_INFO)APP=$(APP)$(CLR_RESET)\n"
	@printf "ECOS_OVERLAY_DIR=$(ECOS_OVERLAY_DIR)\n"
	@printf "ECOS_SDK=$(ECOS_SDK)\n"
	@printf "BOARD_PACKAGE_DIR=$(BOARD_PACKAGE_DIR)\n"
	@printf "APP_DIR=$(APP_DIR)\n"
	@printf "LINK_TARGET=$(LINK_TARGET)\n"
	@printf "DRIVERS=$(DRIVERS)\n"
	@printf "CC=$(CC)\n"
	@printf "TARGET=$(TARGET)\n"

list:
	@printf "$(CLR_INFO)Boards:$(CLR_RESET)\n"
	@printf "  $(BOARD)\n"
	@printf "$(CLR_INFO)Apps for BOARD=$(BOARD):$(CLR_RESET)\n"
	@find $(PORT_DIR)/templates -mindepth 1 -maxdepth 1 -type d ! -name '.*' -printf '  %f\n' | sort

$(AUTOCONF_H): Makefile ecos.mk
	@mkdir -p $(dir $@)
	@printf "/*\n" > $@
	@printf " * Automatically generated file; DO NOT EDIT.\n" >> $@
	@printf " * mpc-soc local build configuration\n" >> $@
	@printf " */\n" >> $@
	@printf "#define CONFIG_MPC_SOC 1\n" >> $@
	@printf "#define CONFIG_FIRMWARE_NAME \"%s\"\n" "$(FIRMWARE_NAME)" >> $@
	@printf "#define CONFIG_FIRMWARE_VERSION \"%s\"\n" "$(FIRMWARE_VERSION)" >> $@
	@printf "#define CONFIG_BUILD_OPT_FLAGS \"%s\"\n" "$(OPT_FLAGS)" >> $@
	@printf "#define CONFIG_BUILD_DEBUG 1\n" >> $@
	@printf "#define CONFIG_BOARD_RAM_TYPE_NAME \"%s\"\n" "$(BOARD_RAM_TYPE_NAME)" >> $@
	@printf "#define CONFIG_BOARD_RAM_SIZE_KB %s\n" "$(BOARD_RAM_SIZE_KB)" >> $@
	@printf "#define CONFIG_BOARD_FLASH_SIZE_KB %s\n" "$(BOARD_FLASH_SIZE_KB)" >> $@
	@printf "#define CONFIG_CPU_FREQ_MHZ %s\n" "$(CPU_FREQ_MHZ)" >> $@
	@printf "#define CONFIG_TIMER_FREQ_MHZ %s\n" "$(TIMER_FREQ_MHZ)" >> $@
	@printf "#define CONFIG_UART_BAUD_RATE %s\n" "$(UART_BAUD_RATE)" >> $@
	@printf "#define CONFIG_LINK_TARGET_$(LINK_TARGET_CONFIG) 1\n" >> $@
	@for driver in $(DRIVERS); do \
		upper=$$(printf '%s' "$$driver" | tr '[:lower:]' '[:upper:]' | tr '-' '_'); \
		printf "#define CONFIG_DRIVER_%s 1\n" "$$upper" >> $@; \
	done

$(LINKER_SCRIPT): $(LINKER_INPUT) $(AUTOCONF_H)
	@mkdir -p $(dir $@)
	@$(CC) -E -P -x c $(LINK_DEFS) $(COMMON_CFLAGS) $(BOARD_INCLUDES) $(APP_INCLUDES) $(ECOS_INCLUDES) -o $@ $<

$(TARGET): $(OBJS) $(LINKER_SCRIPT)
	@mkdir -p $(dir $@)
	@$(CC) $(COMMON_LDFLAGS) -T$(LINKER_SCRIPT) -Wl,-Map,$(BUILD_DIR)/$(APP).map -o $@ $(OBJS) $(ECOS_LIB_DIRS) $(ECOS_LIBS)
	@$(OBJCOPY) -O binary $@ $(BUILD_DIR)/$(APP).bin
	@$(OBJDUMP) -d $@ > $(BUILD_DIR)/$(APP).dump

$(BUILD_DIR)/%.o: %.c $(AUTOCONF_H)
	@mkdir -p $(dir $@)
	@$(CC) $(LINK_DEFS) $(COMMON_CFLAGS) $(BOARD_INCLUDES) $(APP_INCLUDES) $(ECOS_INCLUDES) -c $< -o $@

$(BUILD_DIR)/%.o: %.S $(AUTOCONF_H)
	@mkdir -p $(dir $@)
	@$(CC) $(LINK_DEFS) $(COMMON_ASFLAGS) $(BOARD_INCLUDES) $(APP_INCLUDES) -c $< -o $@

clean:
	@rm -rf $(SOC_ROOT)/build/sw/$(BOARD)/$(APP)
