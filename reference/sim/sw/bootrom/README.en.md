# Archived Boot Images

[中文说明](README.md)

Two acceptance images are retained without requiring a rebuild:

- `hello/retrosoc_fw.bin`: Flash XIP and UART output
- `uart_poll/uart_poll.bin`: UART input and output

`make reference-test` rebuilds the GPIO and PSRAM images from
`sw/ecos/templates/`.
