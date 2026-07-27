module apb4_simple_stub (
    input  wire        apb4_pclk,
    input  wire        apb4_presetn,
    input  wire        apb4_psel,
    input  wire        apb4_penable,
    input  wire        apb4_pwrite,
    input  wire [31:0] apb4_paddr,
    input  wire [2:0]  apb4_pprot,
    input  wire [31:0] apb4_pwdata,
    input  wire [3:0]  apb4_pstrb,
    output wire        apb4_pready,
    output wire        apb4_pslverr,
    output wire [31:0] apb4_prdata
);
  assign apb4_pready = apb4_psel & apb4_penable;
  assign apb4_pslverr = 1'b0;
  assign apb4_prdata = 32'h0;

  wire unused = &{apb4_pclk, apb4_presetn, apb4_pwrite, apb4_paddr, apb4_pprot, apb4_pwdata, apb4_pstrb, 1'b0};
endmodule

`ifndef USE_REAL_RTC
module apb4_rtc (
    input wire apb4_pclk,
    input wire apb4_presetn,
    input wire apb4_psel,
    input wire apb4_penable,
    input wire apb4_pwrite,
    input wire [31:0] apb4_paddr,
    input wire [2:0] apb4_pprot,
    input wire [31:0] apb4_pwdata,
    input wire [3:0] apb4_pstrb,
    output wire apb4_pready,
    output wire apb4_pslverr,
    output wire [31:0] apb4_prdata,
    input wire rtc_rtc_clk_i,
    input wire rtc_rtc_rst_n_i,
    output wire rtc_irq_o
);
  apb4_simple_stub bus (.*);
  assign rtc_irq_o = 1'b0;
  wire unused_rtc = rtc_rtc_clk_i & rtc_rtc_rst_n_i;
endmodule
`endif

`ifndef USE_REAL_WDG
module apb4_wdg (
    input wire apb4_pclk,
    input wire apb4_presetn,
    input wire apb4_psel,
    input wire apb4_penable,
    input wire apb4_pwrite,
    input wire [31:0] apb4_paddr,
    input wire [2:0] apb4_pprot,
    input wire [31:0] apb4_pwdata,
    input wire [3:0] apb4_pstrb,
    output wire apb4_pready,
    output wire apb4_pslverr,
    output wire [31:0] apb4_prdata,
    input wire wdg_rtc_clk_i,
    output wire wdg_rst_o
);
  apb4_simple_stub bus (.*);
  assign wdg_rst_o = 1'b0;
  wire unused_wdg = wdg_rtc_clk_i;
endmodule
`endif

`ifndef USE_REAL_ARCHINFO
module apb4_archinfo (
    input wire apb4_pclk,
    input wire apb4_presetn,
    input wire apb4_psel,
    input wire apb4_penable,
    input wire apb4_pwrite,
    input wire [31:0] apb4_paddr,
    input wire [2:0] apb4_pprot,
    input wire [31:0] apb4_pwdata,
    input wire [3:0] apb4_pstrb,
    output wire apb4_pready,
    output wire apb4_pslverr,
    output wire [31:0] apb4_prdata
);
  apb4_simple_stub bus (.*);
endmodule
`endif

`ifndef USE_REAL_UART
module apb4_uart (
    input wire apb4_pclk,
    input wire apb4_presetn,
    input wire apb4_psel,
    input wire apb4_penable,
    input wire apb4_pwrite,
    input wire [31:0] apb4_paddr,
    input wire [2:0] apb4_pprot,
    input wire [31:0] apb4_pwdata,
    input wire [3:0] apb4_pstrb,
    output wire apb4_pready,
    output wire apb4_pslverr,
    output wire [31:0] apb4_prdata,
    input wire uart_uart_rx_i,
    output wire uart_uart_tx_o,
    output wire uart_irq_o
);
  apb4_simple_stub bus (.*);
  assign uart_uart_tx_o = 1'b1;
  assign uart_irq_o = 1'b0;
  wire unused_uart = uart_uart_rx_i;
endmodule
`endif

`ifndef USE_REAL_I2C
module apb4_i2c (
    input wire apb4_pclk,
    input wire apb4_presetn,
    input wire apb4_psel,
    input wire apb4_penable,
    input wire apb4_pwrite,
    input wire [31:0] apb4_paddr,
    input wire [2:0] apb4_pprot,
    input wire [31:0] apb4_pwdata,
    input wire [3:0] apb4_pstrb,
    output wire apb4_pready,
    output wire apb4_pslverr,
    output wire [31:0] apb4_prdata,
    input wire i2c_scl_i,
    output wire i2c_scl_o,
    output wire i2c_scl_dir_o,
    input wire i2c_sda_i,
    output wire i2c_sda_o,
    output wire i2c_sda_dir_o,
    output wire i2c_irq_o
);
  apb4_simple_stub bus (.*);
  assign i2c_scl_o = 1'b1;
  assign i2c_scl_dir_o = 1'b0;
  assign i2c_sda_o = 1'b1;
  assign i2c_sda_dir_o = 1'b0;
  assign i2c_irq_o = 1'b0;
  wire unused_i2c = i2c_scl_i & i2c_sda_i;
endmodule
`endif

`ifndef USE_REAL_PWM
module apb4_pwm (
    input wire apb4_pclk,
    input wire apb4_presetn,
    input wire apb4_psel,
    input wire apb4_penable,
    input wire apb4_pwrite,
    input wire [31:0] apb4_paddr,
    input wire [2:0] apb4_pprot,
    input wire [31:0] apb4_pwdata,
    input wire [3:0] apb4_pstrb,
    output wire apb4_pready,
    output wire apb4_pslverr,
    output wire [31:0] apb4_prdata,
    output wire [3:0] pwm_pwm_o,
    output wire pwm_irq_o
);
  apb4_simple_stub bus (.*);
  assign pwm_pwm_o = 4'h0;
  assign pwm_irq_o = 1'b0;
endmodule
`endif

`ifndef USE_REAL_TIMER
module apb4_tmr (
    input wire apb4_pclk,
    input wire apb4_presetn,
    input wire apb4_psel,
    input wire apb4_penable,
    input wire apb4_pwrite,
    input wire [31:0] apb4_paddr,
    input wire [2:0] apb4_pprot,
    input wire [31:0] apb4_pwdata,
    input wire [3:0] apb4_pstrb,
    output wire apb4_pready,
    output wire apb4_pslverr,
    output wire [31:0] apb4_prdata,
    input wire tmr_exclk_i,
    input wire tmr_capch_i,
    output wire tmr_irq_o
);
  apb4_simple_stub bus (.*);
  assign tmr_irq_o = 1'b0;
  wire unused_tmr = tmr_exclk_i & tmr_capch_i;
endmodule
`endif

`ifndef USE_REAL_SPI
module apb4_spi (
    input wire apb4_pclk,
    input wire apb4_presetn,
    input wire apb4_psel,
    input wire apb4_penable,
    input wire apb4_pwrite,
    input wire [31:0] apb4_paddr,
    input wire [2:0] apb4_pprot,
    input wire [31:0] apb4_pwdata,
    input wire [3:0] apb4_pstrb,
    output wire apb4_pready,
    output wire apb4_pslverr,
    output wire [31:0] apb4_prdata,
    output wire qspi_spi_sck_o,
    output wire [3:0] qspi_spi_nss_o,
    output wire [3:0] qspi_spi_io_en_o,
    input wire [3:0] qspi_spi_io_in_i,
    output wire [3:0] qspi_spi_io_out_o,
    output wire qspi_irq_o
);
  apb4_simple_stub bus (.*);
  assign qspi_spi_sck_o = 1'b0;
  assign qspi_spi_nss_o = 4'hF;
  assign qspi_spi_io_en_o = 4'h0;
  assign qspi_spi_io_out_o = 4'h0;
  assign qspi_irq_o = 1'b0;
  wire unused_qspi = |qspi_spi_io_in_i;
endmodule
`endif

`ifndef USE_REAL_RNG
module apb4_rng (
    input wire apb4_pclk,
    input wire apb4_presetn,
    input wire apb4_psel,
    input wire apb4_penable,
    input wire apb4_pwrite,
    input wire [31:0] apb4_paddr,
    input wire [2:0] apb4_pprot,
    input wire [31:0] apb4_pwdata,
    input wire [3:0] apb4_pstrb,
    output wire apb4_pready,
    output wire apb4_pslverr,
    output wire [31:0] apb4_prdata
);
  apb4_simple_stub bus (.*);
endmodule
`endif

`ifndef USE_REAL_CRC
module apb4_crc (
    input wire apb4_pclk,
    input wire apb4_presetn,
    input wire apb4_psel,
    input wire apb4_penable,
    input wire apb4_pwrite,
    input wire [31:0] apb4_paddr,
    input wire [2:0] apb4_pprot,
    input wire [31:0] apb4_pwdata,
    input wire [3:0] apb4_pstrb,
    output wire apb4_pready,
    output wire apb4_pslverr,
    output wire [31:0] apb4_prdata
);
  apb4_simple_stub bus (.*);
endmodule
`endif
