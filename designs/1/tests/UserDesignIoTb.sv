module UserDesignIoTb;

  localparam int IO_WIDTH = 66;
  localparam time HALF_PERIOD = 5ns;

  logic clock = 1'b0;
  logic reset = 1'b1;
  logic [IO_WIDTH-1:0] io_in = '0;
  wire [IO_WIDTH-1:0] io_out;
  wire [IO_WIDTH-1:0] io_oe;

  always #(HALF_PERIOD) clock = ~clock;

  UserDesignDut #(.IO_WIDTH(IO_WIDTH)) dut (
    .clock(clock), .reset(reset), .io_in(io_in),
    .io_out(io_out), .io_oe(io_oe)
  );

  initial begin
    repeat (2) @(posedge clock);
    #1ns;
    if (io_out[0] !== 1'b0)
      $fatal(1, "reset did not clear the toggle output");
    if (io_oe[1:0] !== 2'b11 || io_oe[IO_WIDTH-1:2] !== '0)
      $fatal(1, "output-enable map is incorrect");

    io_in[2] = 1'b1;
    #1ns;
    if (io_out[1] !== 1'b1)
      $fatal(1, "input was not reflected on the output");

    @(negedge clock);
    reset = 1'b0;
    @(posedge clock);
    #1ns;
    if (io_out[0] !== 1'b1)
      $fatal(1, "toggle output did not advance with the clock");
    @(posedge clock);
    #1ns;
    if (io_out[0] !== 1'b0)
      $fatal(1, "toggle output did not advance on the second clock");

    @(negedge clock);
    reset = 1'b1;
    @(posedge clock);
    #1ns;
    if (io_out[0] !== 1'b0)
      $fatal(1, "reset did not restore the output state");

    $display("USER DESIGN IO TEST PASS");
    $finish;
  end

endmodule
