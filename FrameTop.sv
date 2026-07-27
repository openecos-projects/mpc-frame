// mpc-frame chip top-level.
// user_io[6:0] is sampled while reset is asserted and selects one of 128 designs.

module FrameTop #(
  parameter int IO_WIDTH = 73,
  parameter int DESIGN_COUNT = 128,
  parameter int DESIGN_ID_WIDTH = 7
) (
  input  logic               clock,
  input  logic               reset,
  inout  wire [IO_WIDTH-1:0] user_io
);

  localparam int PAYLOAD_WIDTH = IO_WIDTH - DESIGN_ID_WIDTH;

  logic [DESIGN_ID_WIDTH-1:0] design_id;
  logic [PAYLOAD_WIDTH-1:0] payload_in;
  logic [PAYLOAD_WIDTH-1:0] payload_out;
  logic [PAYLOAD_WIDTH-1:0] payload_oe;
  logic [DESIGN_COUNT-1:0] design_selected;
  logic [DESIGN_COUNT-1:0] design_reset;
  wire  [DESIGN_COUNT-1:0] design_clock;
  wire [DESIGN_COUNT-1:0][PAYLOAD_WIDTH-1:0] designs_io_out;
  wire [DESIGN_COUNT-1:0][PAYLOAD_WIDTH-1:0] designs_io_oe;

  assign payload_in = user_io[IO_WIDTH-1:DESIGN_ID_WIDTH];

  // The strap value is stable during reset and remains fixed after reset.
  always_ff @(posedge clock) begin
    if (reset)
      design_id <= user_io[DESIGN_ID_WIDTH-1:0];
  end

  always_comb begin
    design_selected = '0;
    design_selected[design_id] = 1'b1;
  end

  assign design_reset = {DESIGN_COUNT{reset}} | ~design_selected;
  assign design_clock = {DESIGN_COUNT{clock}} & design_selected;

  ReferenceDesign0 #(.IO_WIDTH(PAYLOAD_WIDTH)) u_reference_design (
    .clock  (design_clock[0]), .reset  (design_reset[0]),
    .io_in  (payload_in), .io_out (designs_io_out[0]), .io_oe (designs_io_oe[0])
  );

  genvar design_index;
  generate
    for (design_index = 1; design_index < DESIGN_COUNT; design_index++) begin : g_user_design
      UserDesignSlot #(.IO_WIDTH(PAYLOAD_WIDTH)) u_user_design (
        .clock  (design_clock[design_index]), .reset  (design_reset[design_index]),
        .io_in  (payload_in), .io_out (designs_io_out[design_index]),
        .io_oe  (designs_io_oe[design_index])
      );
    end
  endgenerate

  DesignIoMux #(
    .IO_WIDTH(PAYLOAD_WIDTH), .DESIGN_COUNT(DESIGN_COUNT),
    .DESIGN_ID_WIDTH(DESIGN_ID_WIDTH)
  ) u_design_io_mux (
    .design_id(design_id), .designs_out(designs_io_out), .designs_oe(designs_io_oe),
    .io_out(payload_out), .io_oe(payload_oe)
  );

  genvar payload_index;
  generate
    for (payload_index = DESIGN_ID_WIDTH; payload_index < IO_WIDTH; payload_index++) begin : g_payload_io
      localparam int payload_bit = payload_index - DESIGN_ID_WIDTH;
      assign user_io[payload_index] = payload_oe[payload_bit]
        ? payload_out[payload_bit]
        : 1'bz;
    end
  endgenerate

endmodule
