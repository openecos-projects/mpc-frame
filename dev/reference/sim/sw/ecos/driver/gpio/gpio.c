#include <hal_gpio.h>

#include "board.h"

void hal_gpio_set_dir(uint32_t value) {
    REG_GPIO_0_PADDIR = value;
}

uint32_t hal_gpio_get_dir(void) {
    return REG_GPIO_0_PADDIR;
}

uint32_t hal_gpio_get_input(void) {
    return REG_GPIO_0_PADIN;
}

uint32_t hal_gpio_get_output(void) {
    return REG_GPIO_0_PADOUT;
}

void hal_gpio_set_output(uint32_t value) {
    REG_GPIO_0_PADOUT = value;
}

void hal_gpio_set_level(uint32_t pin, uint32_t level) {
    uint32_t mask = 1u << pin;
    if (level == GPIO_LEVEL_LOW) {
        REG_GPIO_0_PADOUT &= ~mask;
    } else {
        REG_GPIO_0_PADOUT |= mask;
    }
}

uint32_t hal_gpio_get_level(uint32_t pin) {
    return (REG_GPIO_0_PADIN >> pin) & 1u;
}
