#include <stdint.h>

#include "board.h"
#include "hal_sys_uart.h"

#define UART_POLL_LIMIT 500000u

static void fail(char *message) {
    hal_sys_putstr("uart poll fail: ");
    hal_sys_putstr(message);
    hal_sys_putstr("\n\r");
    while (1) {
    }
}

static void wait_uart_status(uint8_t mask, char *message) {
    uint32_t timeout = UART_POLL_LIMIT;

    while (timeout-- != 0u) {
        if ((REG_UART_0_LS & mask) == mask) {
            return;
        }
    }

    fail(message);
}

void main(void) {
    uint8_t value;

    hal_sys_uart_init();
    hal_sys_putstr("uart poll test start\n\r");

    hal_sys_putstr("uart poll step: check transmitter status\n\r");
    wait_uart_status(UART_LS_THR_EMPTY_MASK | UART_LS_TX_EMPTY_MASK, "tx empty");

    hal_sys_putstr("uart poll step: check divisor latch readback\n\r");
    REG_UART_0_LC = UART_LC_DLAB_MASK | UART_LC_8N1_VALUE;
    REG_UART_0_DLL = 13u;
    REG_UART_0_DLM = 0u;
    if (REG_UART_0_DLL != 13u || REG_UART_0_DLM != 0u) {
        fail("divisor");
    }
    REG_UART_0_LC = UART_LC_8N1_VALUE;
    if ((REG_UART_0_LC & (UART_LC_DLAB_MASK | UART_LC_8N1_VALUE)) != UART_LC_8N1_VALUE) {
        fail("line control");
    }

    hal_sys_putstr("uart poll step: check interrupt disabled polling mode\n\r");
    REG_UART_0_IE = 0u;
    if (REG_UART_0_IE != 0u) {
        fail("ier disable");
    }

    hal_sys_putstr("uart poll step: send raw byte through THR\n\r");
    wait_uart_status(UART_LS_THR_EMPTY_MASK, "thr ready");
    REG_UART_0_TH = (uint8_t)'U';
    wait_uart_status(UART_LS_TX_EMPTY_MASK, "tx complete");

    hal_sys_putstr("\n\ruart poll step: receive injected byte\n\r");
    wait_uart_status(UART_LS_DATA_READY_MASK, "rx ready");
    value = REG_UART_0_RB;
    if (value != (uint8_t)'Z') {
        fail("rx byte");
    }

    hal_sys_putstr("uart poll ok\n\r");
    while (1) {
    }
}
