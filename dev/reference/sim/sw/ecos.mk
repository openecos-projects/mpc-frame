SOC_ROOT := $(abspath ..)
ECOS_OVERLAY_DIR := $(SOC_ROOT)/sw/ecos
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

ECOS_INCLUDES ?=
ECOS_LIB_DIRS ?=
ECOS_LIBS ?=

COMMON_CFLAGS ?= $(ARCH_FLAGS) $(OPT_FLAGS) $(WARN_FLAGS) -ffreestanding -fno-common
COMMON_ASFLAGS ?= $(ARCH_FLAGS) $(OPT_FLAGS)
COMMON_LDFLAGS ?= $(ARCH_FLAGS) -nostdlib -nostartfiles -Wl,--gc-sections
