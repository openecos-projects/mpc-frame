#ifndef MPC_FRAME_HAL_GPIO_H
#define MPC_FRAME_HAL_GPIO_H

#include <stdint.h>

#define GPIO_LEVEL_LOW 0u
#define GPIO_LEVEL_HIGH 1u

void hal_gpio_set_dir(uint32_t value);
uint32_t hal_gpio_get_dir(void);
uint32_t hal_gpio_get_input(void);
uint32_t hal_gpio_get_output(void);
void hal_gpio_set_output(uint32_t value);
void hal_gpio_set_level(uint32_t pin, uint32_t level);
uint32_t hal_gpio_get_level(uint32_t pin);

#endif
