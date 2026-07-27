// Default implementation for user design slots 1..127.

module UserDesignSlot #(
  parameter int IO_WIDTH = 66
) (
  input  logic clock,
  input  logic reset,
  input  logic [IO_WIDTH-1:0] io_in,
  output logic [IO_WIDTH-1:0] io_out,
  output logic [IO_WIDTH-1:0] io_oe
);

  always_comb begin
    io_out = '0;
    io_oe = '0;
  end

  logic unused_user_inputs;
  always_comb unused_user_inputs = clock ^ reset ^ (^io_in);

endmodule
