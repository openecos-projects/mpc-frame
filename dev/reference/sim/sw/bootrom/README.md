# 归档启动镜像

[English](README.en.md)

当前只保留两个无需重新编译的验收镜像：

- `hello/retrosoc_fw.bin`：Flash XIP 与 UART 输出。
- `uart_poll/uart_poll.bin`：UART 输入与输出。

GPIO 和 PSRAM 镜像由 `make reference-test` 从 `sw/ecos/templates/` 重新构建。
