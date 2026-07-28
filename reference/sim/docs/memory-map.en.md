# Memory Map

[中文说明](memory-map.md)

| Region | Base | Size | Description |
| --- | ---: | ---: | --- |
| CLINT | `0x0201_0000` | `0x0001_0000` | NPC local interrupts |
| PLIC | `0x0c00_0000` | `0x0040_0000` | UART/GPIO external interrupts |
| UART0 | `0x1000_0000` | `0x0000_1000` | UART16550 |
| RCU | `0x1000_2000` | `0x0000_1000` | Clock and reset control |
| GPIO0 | `0x1010_0000` | `0x0000_0100` | GPIO[31:0] |
| GPIO1 | `0x1010_0100` | `0x0000_0100` | GPIO[53:32], 22 valid bits |
| SPI Flash | `0x3000_0000` | `0x0100_0000` | XIP instruction window |
| PSRAM | `0xc000_0000` | `0x0080_0000` | One 8 MiB RAM |

Legacy peripheral addresses not listed here are not part of the current
reference interface.
