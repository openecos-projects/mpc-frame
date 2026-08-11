#ifndef __MPC_SOC_BOARD_H__
#define __MPC_SOC_BOARD_H__

#include <stdint.h>

#define MPC_SOC_BOARD_NAME              "mpc-frame-reference"
#define MPC_SOC_XLEN                    32u
#define MPC_SOC_CLOCK_HZ                50000000u
#define MPC_SOC_UART_BAUD               115200u

#define MPC_SOC_BOOTROM_BASE            0x30000000u
#define MPC_SOC_BOOTROM_SIZE            0x01000000u
#define MPC_SOC_PSRAM_BASE              0xC0000000u
#define MPC_SOC_PSRAM_SIZE              0x00800000u
#define MPC_SOC_MEM_BASE                MPC_SOC_PSRAM_BASE
#define MPC_SOC_MEM_SIZE                MPC_SOC_PSRAM_SIZE

#define MPC_SOC_UART0_BASE              0x10000000u
#define MPC_SOC_GPIO0_BASE              0x10100000u
#define MPC_SOC_GPIO1_BASE              0x10100100u

#define REG_UART_0_RB                   (*((volatile uint8_t *)(MPC_SOC_UART0_BASE + 0x00u)))
#define REG_UART_0_TH                   (*((volatile uint8_t *)(MPC_SOC_UART0_BASE + 0x00u)))
#define REG_UART_0_DLL                  (*((volatile uint8_t *)(MPC_SOC_UART0_BASE + 0x00u)))
#define REG_UART_0_IE                   (*((volatile uint8_t *)(MPC_SOC_UART0_BASE + 0x01u)))
#define REG_UART_0_DLM                  (*((volatile uint8_t *)(MPC_SOC_UART0_BASE + 0x01u)))
#define REG_UART_0_II                   (*((volatile uint8_t *)(MPC_SOC_UART0_BASE + 0x02u)))
#define REG_UART_0_FC                   (*((volatile uint8_t *)(MPC_SOC_UART0_BASE + 0x02u)))
#define REG_UART_0_LC                   (*((volatile uint8_t *)(MPC_SOC_UART0_BASE + 0x03u)))
#define REG_UART_0_MC                   (*((volatile uint8_t *)(MPC_SOC_UART0_BASE + 0x04u)))
#define REG_UART_0_LS                   (*((volatile uint8_t *)(MPC_SOC_UART0_BASE + 0x05u)))
#define REG_UART_0_MS                   (*((volatile uint8_t *)(MPC_SOC_UART0_BASE + 0x06u)))

#define UART_LS_DATA_READY_MASK         0x01u
#define UART_LS_THR_EMPTY_MASK          0x20u
#define UART_LS_TX_EMPTY_MASK           0x40u
#define UART_LC_8N1_VALUE               0x03u
#define UART_LC_DLAB_MASK               0x80u

#define REG_GPIO_0_PADDIR               (*((volatile uint32_t *)(MPC_SOC_GPIO0_BASE + 0x00u)))
#define REG_GPIO_0_PADIN                (*((volatile uint32_t *)(MPC_SOC_GPIO0_BASE + 0x04u)))
#define REG_GPIO_0_PADOUT               (*((volatile uint32_t *)(MPC_SOC_GPIO0_BASE + 0x08u)))
#define REG_GPIO_1_PADDIR               (*((volatile uint32_t *)(MPC_SOC_GPIO1_BASE + 0x00u)))
#define REG_GPIO_1_PADIN                (*((volatile uint32_t *)(MPC_SOC_GPIO1_BASE + 0x04u)))
#define REG_GPIO_1_PADOUT               (*((volatile uint32_t *)(MPC_SOC_GPIO1_BASE + 0x08u)))

#endif
