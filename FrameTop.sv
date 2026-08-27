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
  // A selected design may combinationally read one IO bit and drive another.
  // The resolved inout vector is otherwise reported as a false flat loop.
  /* verilator lint_off UNOPTFLAT */
  logic [PAYLOAD_WIDTH-1:0] payload_out;
  logic [PAYLOAD_WIDTH-1:0] payload_oe;
  /* verilator lint_on UNOPTFLAT */
  logic [DESIGN_COUNT-1:0] design_selected;
  logic [DESIGN_COUNT-1:0] design_clock_enable;
  logic [DESIGN_COUNT-1:0] design_reset;
  wire [DESIGN_COUNT-1:0] design_present;
  logic selection_valid;
  wire  [DESIGN_COUNT-1:0] design_clock;
  wire [DESIGN_COUNT-1:0][PAYLOAD_WIDTH-1:0] designs_io_out;
  wire [DESIGN_COUNT-1:0][PAYLOAD_WIDTH-1:0] designs_io_oe;

  assign payload_in = user_io[IO_WIDTH-1:DESIGN_ID_WIDTH];

  FrameDesignControl #(
    .DESIGN_COUNT(DESIGN_COUNT), .DESIGN_ID_WIDTH(DESIGN_ID_WIDTH),
    .RESET_RELEASE_CYCLES(2)
  ) u_design_control (
    .clock(clock), .reset(reset),
    .async_design_id(user_io[DESIGN_ID_WIDTH-1:0]),
    .design_present(design_present),
    .design_id(design_id), .selection_valid(selection_valid),
    .design_selected(design_selected),
    .design_clock_enable(design_clock_enable), .design_reset(design_reset)
  );

  genvar clock_index;
  generate
    for (clock_index = 0; clock_index < DESIGN_COUNT; clock_index++) begin : g_design_clock
      FrameClockGate u_clock_gate (
        .clock(clock), .enable(design_clock_enable[clock_index]),
        .gated_clock(design_clock[clock_index])
      );
    end
  endgenerate

  FrameDesignRegistry #(
    .IO_WIDTH(PAYLOAD_WIDTH), .DESIGN_COUNT(DESIGN_COUNT)
  ) u_design_registry (
    .design_clock(design_clock), .design_reset(design_reset),
    .io_in(payload_in), .designs_io_out(designs_io_out),
    .designs_io_oe(designs_io_oe), .design_present(design_present)
  );

  DesignIoMux #(
    .IO_WIDTH(PAYLOAD_WIDTH), .DESIGN_COUNT(DESIGN_COUNT),
    .DESIGN_ID_WIDTH(DESIGN_ID_WIDTH)
  ) u_design_io_mux (
    .select_enable(selection_valid), .design_id(design_id),
    .designs_out(designs_io_out), .designs_oe(designs_io_oe),
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
