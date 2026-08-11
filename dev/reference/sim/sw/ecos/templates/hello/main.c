#include "main.h"

void main(void){

    hal_sys_uart_init();
    hal_sys_putstr("hello test start\n\r");
    hal_sys_putstr("hello step: print banner\n\r");
    hal_sys_putstr("hello ecos, this is mpc-soc\n\r");
    hal_sys_putstr("hello step: emit completion marker\n\r");
    hal_sys_putstr("done!\n\r");

}
