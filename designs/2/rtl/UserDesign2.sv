// Second minimal package used to verify multi-design registration.

module UserDesign2 #(
  parameter int IO_WIDTH = 66
) (
  input  logic                clock,
  input  logic                reset,
  input  logic [IO_WIDTH-1:0] io_in,
  output logic [IO_WIDTH-1:0] io_out,
  output logic [IO_WIDTH-1:0] io_oe
);

  logic [3:0] count;

  always_ff @(posedge clock) begin
    if (reset)
      count <= '0;
    else
      count <= count + 1'b1;
  end

  always_comb begin
    io_out = '0;
    io_oe = '0;
    io_out[3:0] = count;
    io_oe[3:0] = '1;
    io_out[4] = io_in[5];
    io_oe[4] = 1'b1;
  end

endmodule
