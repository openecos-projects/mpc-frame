#include <stdint.h>
#include "main.h"
#include "board.h"

extern uint32_t app_start;
extern uint32_t app_end;

#ifdef CONFIG_LINK_TARGET_MEM
#define APP_ENTRY MPC_SOC_MEM_BASE
#else
#define APP_ENTRY MPC_SOC_BOOTROM_BASE
#endif

void main(void) {
  hal_sys_uart_init();
  hal_sys_putstr("loading app...\n");

  uint32_t* source = &app_start;
  uint32_t* target = (uint32_t*)APP_ENTRY;
  uint32_t* end = &app_end;

  while (source < end) {
    *target = *source;
    ++target;
    ++source;
  }

  __asm__ volatile("fence.i");
  void (*entry)(void) = (void (*)(void))APP_ENTRY;
  entry();
}
