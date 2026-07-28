module UserDesign2IoTb;

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
    if (io_out[3:0] !== 4'h0 || io_oe[4:0] !== 5'b11111)
      $fatal(1, "design 2 reset or output-enable state is incorrect");

    io_in[5] = 1'b1;
    #1ns;
    if (io_out[4] !== 1'b1)
      $fatal(1, "design 2 input path is incorrect");

    @(negedge clock);
    reset = 1'b0;
    repeat (3) @(posedge clock);
    #1ns;
    if (io_out[3:0] !== 4'd3)
      $fatal(1, "design 2 counter did not advance");

    $display("USER DESIGN 2 IO TEST PASS");
    $finish;
  end

endmodule
