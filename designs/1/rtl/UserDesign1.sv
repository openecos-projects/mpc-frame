// Minimal user design used to verify the package and FrameTop workflows.

module UserDesign1 #(
  parameter int IO_WIDTH = 66
) (
  input  logic                clock,
  input  logic                reset,
  input  logic [IO_WIDTH-1:0] io_in,
  output logic [IO_WIDTH-1:0] io_out,
  output logic [IO_WIDTH-1:0] io_oe
);

  logic toggle_value;

  always_ff @(posedge clock) begin
    if (reset)
      toggle_value <= 1'b0;
    else
      toggle_value <= ~toggle_value;
  end

  always_comb begin
    io_out = '0;
    io_oe = '0;
    io_out[0] = toggle_value;
    io_oe[0] = 1'b1;
    io_out[1] = io_in[2];
    io_oe[1] = 1'b1;
  end

endmodule
