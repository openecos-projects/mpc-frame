module FrameDesign1Tb;

  localparam int IO_WIDTH = 73;
  localparam int DESIGN_ID_WIDTH = 7;
  localparam time HALF_PERIOD = 5ns;

  logic clock = 1'b0;
  logic reset = 1'b1;
  logic [IO_WIDTH-1:0] test_io_out = '0;
  logic [IO_WIDTH-1:0] test_io_oe = '0;
  tri [IO_WIDTH-1:0] user_io;
  integer design_clock_edges = 0;

  always #(HALF_PERIOD) clock = ~clock;

  for (genvar io_index = 0; io_index < IO_WIDTH; io_index++) begin : gen_test_io
    assign user_io[io_index] = test_io_oe[io_index]
      ? test_io_out[io_index]
      : 1'bz;
  end

  FrameTop dut (
    .clock(clock), .reset(reset), .user_io(user_io)
  );

  always @(posedge dut.design_clock[1])
    design_clock_edges = design_clock_edges + 1;

  task automatic select_design(input logic [DESIGN_ID_WIDTH-1:0] design_id);
    begin
      test_io_oe = '0;
      test_io_out = '0;
      test_io_oe[DESIGN_ID_WIDTH-1:0] = '1;
      test_io_out[DESIGN_ID_WIDTH-1:0] = design_id;
      reset = 1'b1;
      repeat (20) @(posedge clock);
      @(negedge clock);
      reset = 1'b0;
      repeat (4) @(posedge clock);
      #1ns;
    end
  endtask

  initial begin
    int edge_snapshot;
    logic toggle_snapshot;

    select_design(7'd1);
    if (user_io[DESIGN_ID_WIDTH + 1] !== 1'b0)
      $fatal(1, "design 1 input path did not start low");

    test_io_oe[DESIGN_ID_WIDTH + 2] = 1'b1;
    test_io_out[DESIGN_ID_WIDTH + 2] = 1'b1;
    #1ns;
    if (user_io[DESIGN_ID_WIDTH + 1] !== 1'b1)
      $fatal(1, "design 1 did not read the external input");

    toggle_snapshot = user_io[DESIGN_ID_WIDTH];
    @(posedge clock);
    #1ns;
    if (user_io[DESIGN_ID_WIDTH] === toggle_snapshot)
      $fatal(1, "design 1 output did not toggle through FrameTop");

    test_io_out[DESIGN_ID_WIDTH-1:0] = 7'd2;
    repeat (3) @(posedge clock);
    #1ns;
    if (!dut.design_selected[1] || dut.design_id != 7'd1)
      $fatal(1, "runtime selector change replaced the locked design");

    @(negedge clock);
    reset = 1'b1;
    repeat (2) @(posedge clock);
    #1ns;
    edge_snapshot = design_clock_edges;
    repeat (3) @(posedge clock);
    if (design_clock_edges != edge_snapshot)
      $fatal(1, "design 1 clock was not stopped during reset");

    select_design(7'd3);
    if (dut.selection_valid || dut.design_clock_enable != '0)
      $fatal(1, "an unregistered design was enabled");
    if (user_io[DESIGN_ID_WIDTH] !== 1'bz ||
        user_io[DESIGN_ID_WIDTH + 1] !== 1'bz)
      $fatal(1, "an unregistered design drove payload IO");

    $display("FRAME DESIGN 1 TEST PASS");
    $finish;
  end

endmodule
