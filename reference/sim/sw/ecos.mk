SOC_ROOT := $(abspath ..)
ECOS_OVERLAY_DIR := $(SOC_ROOT)/sw/ecos
ECOS_SDK ?= $(if $(wildcard $(SOC_ROOT)/third_party/ecos-sdk),$(SOC_ROOT)/third_party/ecos-sdk,$(HOME)/.local/ecos-sdk)
CROSS_COMPILE ?= riscv64-unknown-elf-

ifeq ($(origin CC),default)
CC := $(CROSS_COMPILE)gcc
endif
OBJCOPY ?= $(CROSS_COMPILE)objcopy
OBJDUMP ?= $(CROSS_COMPILE)objdump
SIZE ?= $(CROSS_COMPILE)size

ARCH_FLAGS ?= -march=rv32im -mabi=ilp32
OPT_FLAGS ?= -O2 -g
WARN_FLAGS ?= -Wall -Wextra

ECOS_INCLUDES ?= -I$(ECOS_SDK)/include
ECOS_INCLUDES += $(foreach dir,$(wildcard $(ECOS_SDK)/hal/*),-I$(dir))
ECOS_INCLUDES += -I$(ECOS_SDK)/components/libc/include
ECOS_INCLUDES += -I$(ECOS_SDK)/components/libgcc/include
ECOS_LIB_DIRS ?= -L$(ECOS_SDK)/lib
ECOS_LIBS ?=

COMMON_CFLAGS ?= $(ARCH_FLAGS) $(OPT_FLAGS) $(WARN_FLAGS) -ffreestanding -fno-common
COMMON_ASFLAGS ?= $(ARCH_FLAGS) $(OPT_FLAGS)
COMMON_LDFLAGS ?= $(ARCH_FLAGS) -nostdlib -nostartfiles -Wl,--gc-sections
