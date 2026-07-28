// Synchronize and lock the design selector, then sequence clock and reset release.

module FrameDesignControl #(
  parameter int DESIGN_COUNT = 128,
  parameter int DESIGN_ID_WIDTH = 7,
  parameter int RESET_RELEASE_CYCLES = 2
) (
  input  logic                       clock,
  input  logic                       reset,
  input  logic [DESIGN_ID_WIDTH-1:0] async_design_id,
  input  logic [DESIGN_COUNT-1:0]    design_present,
  output wire  [DESIGN_ID_WIDTH-1:0] design_id,
  output logic                       selection_valid,
  output logic [DESIGN_COUNT-1:0]    design_selected,
  output logic [DESIGN_COUNT-1:0]    design_clock_enable,
  output logic [DESIGN_COUNT-1:0]    design_reset
);

  localparam int RELEASE_COUNT_WIDTH = $clog2(RESET_RELEASE_CYCLES + 1);
  localparam logic [RELEASE_COUNT_WIDTH-1:0] RELEASE_COUNT_LIMIT =
    RELEASE_COUNT_WIDTH'(RESET_RELEASE_CYCLES);

  (* ASYNC_REG = "TRUE" *) logic [DESIGN_ID_WIDTH-1:0] design_id_meta;
  (* ASYNC_REG = "TRUE" *) logic [DESIGN_ID_WIDTH-1:0] design_id_sync;
  logic gate_armed;
  logic [RELEASE_COUNT_WIDTH-1:0] release_count;

  // The external selector must remain stable for at least two clock edges before
  // reset is released. Sampling stops while the selected design is running.
  always_ff @(posedge clock) begin
    if (reset) begin
      design_id_meta <= async_design_id;
      design_id_sync <= design_id_meta;
    end
  end

  assign design_id = design_id_sync;

  // Allow one low clock phase for the gate enable to settle, then keep the
  // selected design in reset for RESET_RELEASE_CYCLES complete clock edges.
  always_ff @(posedge clock) begin
    if (reset) begin
      gate_armed <= 1'b0;
      release_count <= '0;
    end else if (!gate_armed) begin
      gate_armed <= 1'b1;
    end else if (release_count < RELEASE_COUNT_LIMIT) begin
      release_count <= release_count + 1'b1;
    end
  end

  always_comb begin
    design_selected = '0;
    if (!reset && (int'(design_id) < DESIGN_COUNT) && design_present[design_id])
      design_selected[design_id] = 1'b1;
  end

  always_comb begin
    selection_valid = !reset && gate_armed &&
      (release_count == RELEASE_COUNT_LIMIT) && (|design_selected);
    design_clock_enable = design_selected;
    design_reset = {DESIGN_COUNT{reset | ~selection_valid}} | ~design_selected;
  end

endmodule
