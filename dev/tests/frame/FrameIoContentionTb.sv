module FrameIoContentionTb;

  localparam int IO_WIDTH = 73;
  localparam int DESIGN_ID_WIDTH = 7;
  localparam time HALF_PERIOD = 5ns;

  logic clock = 1'b0;
  logic reset = 1'b1;
  logic [IO_WIDTH-1:0] test_io_out = '0;
  logic [IO_WIDTH-1:0] test_io_oe = '0;
  tri [IO_WIDTH-1:0] user_io;
  logic payload_contention;

  always #(HALF_PERIOD) clock = ~clock;

  for (genvar io_index = 0; io_index < IO_WIDTH; io_index++) begin : gen_test_io
    assign user_io[io_index] = test_io_oe[io_index]
      ? test_io_out[io_index]
      : 1'bz;
  end

  FrameTop dut (
    .clock(clock), .reset(reset), .user_io(user_io)
  );

  always_comb begin
    payload_contention = |(
      test_io_oe[IO_WIDTH-1:DESIGN_ID_WIDTH] & dut.payload_oe
    );
  end

  initial begin
    test_io_oe[DESIGN_ID_WIDTH-1:0] = '1;
    test_io_out[DESIGN_ID_WIDTH-1:0] = 7'd2;
    repeat (20) @(posedge clock);
    @(negedge clock);
    reset = 1'b0;
    repeat (4) @(posedge clock);
    #1ns;

    test_io_oe[DESIGN_ID_WIDTH + 5] = 1'b1;
    test_io_out[DESIGN_ID_WIDTH + 5] = 1'b1;
    #1ns;
    if (payload_contention)
      $fatal(1, "an input-only external drive was reported as contention");

    @(negedge clock);
    test_io_oe[DESIGN_ID_WIDTH] = 1'b1;
    test_io_out[DESIGN_ID_WIDTH] = dut.payload_out[0];
    #1ns;
    if (!payload_contention)
      $fatal(1, "same-value external and design outputs were not detected");

    test_io_oe[DESIGN_ID_WIDTH] = 1'b0;
    #1ns;
    if (payload_contention)
      $fatal(1, "contention remained after the external driver released IO");

    $display("FRAME IO CONTENTION TEST PASS");
    $finish;
  end

endmodule
