#ifndef MPC_FRAME_HAL_SYS_UART_H
#define MPC_FRAME_HAL_SYS_UART_H

#include <stdint.h>

void hal_sys_uart_init(void);
void hal_sys_putchar(char c);
void hal_sys_putstr(char *str);
uint8_t hal_sys_getchar(void);

#endif
