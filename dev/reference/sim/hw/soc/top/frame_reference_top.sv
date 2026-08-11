// Frame-facing reference SoC top.
//
// The internal SoC keeps its existing memory bus and controller implementation,
// while this boundary exposes one UART, two GPIO banks, one SPI flash, and one
// QSPI PSRAM. Memory models belong to the simulation adapter, not this block.

module FrameReferenceSoC (
  input        clock,
  input        reset,
  input        uart0_rx,
  output       uart0_tx,
  input  [53:0] gpio_in,
  output [53:0] gpio_out,
  output [53:0] gpio_oe,
  output       flash_sck_o,
  output       flash_cs_n,
  output       flash_mosi_o,
  input        flash_miso_i,
  output       psram_sck_o,
  output       psram_cs_n,
  input  [3:0] psram_dio_i,
  output [3:0] psram_dio_o,
  output [3:0] psram_dio_oe
);

  wire [2:0] psram_nss_o;
  wire [63:0] gpio_in_full = {10'b0, gpio_in};
  wire [63:0] gpio_out_full;
  wire [63:0] gpio_oe_full;

  ysyxSoC soc (
    .clock             (clock),
    .reset             (reset),
    .coreSel           (4'h0),
    .uart0_rx          (uart0_rx),
    .uart0_tx          (uart0_tx),
    .spi_sck           (flash_sck_o),
    .spi_ss            (flash_cs_n),
    .spi_mosi          (flash_mosi_o),
    .spi_miso          (flash_miso_i),
    .psram_sck_o       (psram_sck_o),
    .psram_nss_o       (psram_nss_o),
    .psram_io_oe_o     (psram_dio_oe),
    .psram_io_di_i     (psram_dio_i),
    .psram_io_do_o     (psram_dio_o),
    .pll_en_i          (1'b0),
    .clk_cfg_i         (2'b0),
    .clk_o             (),
    .gpio0_gpio_in_i   (gpio_in_full),
    .gpio0_gpio_out_o  (gpio_out_full),
    .gpio0_gpio_dir_o  (gpio_oe_full)
  );

  assign gpio_out = gpio_out_full[53:0];
  assign gpio_oe = gpio_oe_full[53:0];
  assign psram_cs_n = psram_nss_o[0];

endmodule
