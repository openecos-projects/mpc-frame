// Minimal user design example using the internal wrapper contract.

module UserDesign1 #(
  parameter int IO_WIDTH = 66
) (
  input  logic                clock,
  input  logic                reset,
  input  logic [IO_WIDTH-1:0] io_in,
  output logic [IO_WIDTH-1:0] io_out,
  output logic [IO_WIDTH-1:0] io_oe
);

  logic value;

  always_ff @(posedge clock) begin
    if (reset)
      value <= 1'b0;
    else
      value <= ~value;
  end

  always_comb begin
    io_out = io_in;
    io_oe = '0;
    io_out[0] = value;
    io_oe[0] = 1'b1;
  end

endmodule
