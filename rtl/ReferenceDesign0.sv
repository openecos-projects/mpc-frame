// Adapter from the FrameTop payload bus to the fixed reference SoC IO map.

module ReferenceDesign0 #(
  parameter int IO_WIDTH = 66
) (
  input  logic [IO_WIDTH-1:0] io_in,
  input  logic clock,
  input  logic reset,
  output logic [IO_WIDTH-1:0] io_out,
  output logic [IO_WIDTH-1:0] io_oe
);

`ifdef FRAME_USE_REFERENCE
  wire [53:0] gpio_in = io_in[65:12];
  wire [53:0] gpio_out;
  wire [53:0] gpio_dir;
  wire uart_tx;
  wire flash_sck;
  wire flash_cs_n;
  wire flash_mosi;
  wire flash_miso;
  wire psram_sck;
  wire psram_cs_n;
  wire [3:0] psram_dio_in;
  wire [3:0] psram_dio_out;
  wire [3:0] psram_dio_oe;

`ifdef FRAME_SIM_MODELS
  wire [3:0] psram_model_bus;
  assign psram_dio_in = psram_model_bus;

  genvar psram_bit;
  generate
    for (psram_bit = 0; psram_bit < 4; psram_bit++) begin : g_psram_model_bus
      assign psram_model_bus[psram_bit] = psram_dio_oe[psram_bit]
        ? psram_dio_out[psram_bit]
        : 1'bz;
    end
  endgenerate

  flash u_flash_model (
    .sck  (flash_sck),
    .ss   (flash_cs_n),
    .mosi (flash_mosi),
    .miso (flash_miso)
  );

  ESP_PSRAM64H #(.ID(0)) u_psram_model (
    .sclk (psram_sck),
    .csn  (psram_cs_n),
    .sio  (psram_model_bus)
  );
`else
  assign flash_miso = io_in[5];
  assign psram_dio_in = io_in[11:8];
`endif

  FrameReferenceSoC u_reference_soc (
    .clock      (clock),
    .reset      (reset),
    .uart0_rx   (io_in[0]),
    .uart0_tx   (uart_tx),
    .gpio_in    (gpio_in),
    .gpio_out   (gpio_out),
    .gpio_oe    (gpio_dir),
    .flash_sck_o(flash_sck),
    .flash_cs_n (flash_cs_n),
    .flash_mosi_o(flash_mosi),
    .flash_miso_i(flash_miso),
    .psram_sck_o(psram_sck),
    .psram_cs_n (psram_cs_n),
    .psram_dio_i(psram_dio_in),
    .psram_dio_o(psram_dio_out),
    .psram_dio_oe(psram_dio_oe)
  );

  always_comb begin
    io_out = '0;
    io_oe = '0;
    io_out[1] = uart_tx;
    io_oe[1] = 1'b1;
    io_out[2] = flash_sck;
    io_out[3] = flash_cs_n;
    io_out[4] = flash_mosi;
    io_oe[4:2] = 3'b111;
    io_out[6] = psram_sck;
    io_out[7] = psram_cs_n;
    io_out[11:8] = psram_dio_out;
    io_oe[7:6] = 2'b11;
    io_oe[11:8] = psram_dio_oe;
    io_out[65:12] = gpio_out;
    io_oe[65:12] = gpio_dir;
  end
`else
  always_comb begin
    io_out = '0;
    io_oe = '0;
  end
`endif

endmodule
