// Test-only registry for FrameIoContentionTb.
// This keeps internal verification designs out of the production registry.

module FrameDesignRegistry #(
  parameter int IO_WIDTH = 66,
  parameter int DESIGN_COUNT = 128
) (
  input  wire [DESIGN_COUNT-1:0]               design_clock,
  input  wire [DESIGN_COUNT-1:0]               design_reset,
  input  wire [IO_WIDTH-1:0]                   io_in,
  output wire [DESIGN_COUNT-1:0][IO_WIDTH-1:0] designs_io_out,
  output wire [DESIGN_COUNT-1:0][IO_WIDTH-1:0] designs_io_oe,
  output wire [DESIGN_COUNT-1:0]               design_present
);

  // Slot 0 is reserved by the frame contract. Slot 2 is a synthetic design
  // that drives payload bit 0 so the TB can deliberately create contention.
  assign design_present = DESIGN_COUNT'(5);

  for (genvar design_index = 0; design_index < DESIGN_COUNT; design_index++) begin : gen_design
    assign designs_io_out[design_index] = '0;
    if (design_index == 2) begin : gen_contention_source
      assign designs_io_oe[design_index] = IO_WIDTH'(1);
    end else begin : gen_inactive_slot
      assign designs_io_oe[design_index] = '0;
    end
  end

endmodule
