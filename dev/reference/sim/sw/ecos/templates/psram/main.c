#include "main.h"

static void put_hex32(uint32_t value) {
    static const char hex[] = "0123456789abcdef";

    hal_sys_putstr("0x");
    for (int shift = 28; shift >= 0; shift -= 4) {
        hal_sys_putchar(hex[(value >> shift) & 0x0fu]);
    }
}

static void fail(char *message, uintptr_t address, uint32_t expect, uint32_t actual) {
    hal_sys_putstr("psram fail: ");
    hal_sys_putstr(message);
    hal_sys_putstr(" addr ");
    put_hex32((uint32_t)address);
    hal_sys_putstr(" expect ");
    put_hex32(expect);
    hal_sys_putstr(" actual ");
    put_hex32(actual);
    hal_sys_putstr("\n\r");
    while (1) {
    }
}

static void check_word(uintptr_t address, uint32_t pattern) {
    volatile uint32_t *mem = (volatile uint32_t *)address;
    uint32_t actual;

    *mem = pattern;
    actual = *mem;
    if (actual != pattern) {
        fail("word", address, pattern, actual);
    }
}

static void check_half(uintptr_t address, uint16_t pattern) {
    volatile uint16_t *mem = (volatile uint16_t *)address;
    uint16_t actual;

    *mem = pattern;
    actual = *mem;
    if (actual != pattern) {
        fail("half", address, pattern, actual);
    }
}

static void check_byte(uintptr_t address, uint8_t pattern) {
    volatile uint8_t *mem = (volatile uint8_t *)address;
    uint8_t actual;

    *mem = pattern;
    actual = *mem;
    if (actual != pattern) {
        fail("byte", address, pattern, actual);
    }
}

void main(void) {
    const uintptr_t base = MPC_SOC_PSRAM_BASE;

    hal_sys_uart_init();
    hal_sys_putstr("psram basic test start\n\r");

    hal_sys_putstr("psram step: check chip0 low words\n\r");
    check_word(base + 0x00000000u, 0x11223344u);
    check_word(base + 0x00000004u, 0x55667788u);
    hal_sys_putstr("psram step: check chip0 middle word\n\r");
    check_word(base + 0x00010000u, 0x01010101u);
    hal_sys_putstr("psram step: check chip0 high boundary words\n\r");
    check_word(base + 0x00400100u, 0x0c040100u);
    check_word(base + 0x007ffffcu, 0xa5a5a5a5u);
    hal_sys_putstr("chip0 ok\n\r");

    hal_sys_putstr("psram step: check byte and halfword accesses\n\r");
    check_byte(base + 0x00000201u, 0x5au);
    check_half(base + 0x00000302u, 0x1357u);
    hal_sys_putstr("byte half word ok\n\r");

    hal_sys_putstr("psram ok\n\r");
    while (1) {
    }
}
