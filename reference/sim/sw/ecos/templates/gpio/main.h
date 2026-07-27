// System Headers
#include "string.h"
#include "stdio.h"
#include "libgcc.h"

// System Configuration
#include "generated/autoconf.h"
#include "board.h"

#include "hal_gpio.h"
#include "hal_sys_uart.h"

void hal_gpio_set_dir(uint32_t value);
uint32_t hal_gpio_get_dir(void);
uint32_t hal_gpio_get_input(void);
uint32_t hal_gpio_get_output(void);
void hal_gpio_set_output(uint32_t value);
