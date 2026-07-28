module FrameDesign2Tb;

  localparam int IO_WIDTH = 73;
  localparam int DESIGN_ID_WIDTH = 7;
  localparam time HALF_PERIOD = 5ns;

  logic clock = 1'b0;
  logic reset = 1'b1;
  logic [IO_WIDTH-1:0] test_io_out = '0;
  logic [IO_WIDTH-1:0] test_io_oe = '0;
  tri [IO_WIDTH-1:0] user_io;
  integer design1_edges = 0;
  integer design2_edges = 0;

  always #(HALF_PERIOD) clock = ~clock;

  for (genvar io_index = 0; io_index < IO_WIDTH; io_index++) begin : gen_test_io
    assign user_io[io_index] = test_io_oe[io_index]
      ? test_io_out[io_index]
      : 1'bz;
  end

  FrameTop dut (
    .clock(clock), .reset(reset), .user_io(user_io)
  );

  always @(posedge dut.design_clock[1]) design1_edges = design1_edges + 1;
  always @(posedge dut.design_clock[2]) design2_edges = design2_edges + 1;

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
    int design1_snapshot;
    int design2_snapshot;
    logic [3:0] count_snapshot;

    select_design(7'd2);
    if (!dut.design_selected[2] || dut.design_present[2:0] != 3'b111)
      $fatal(1, "design 2 was not registered and selected");

    design1_snapshot = design1_edges;
    count_snapshot = user_io[DESIGN_ID_WIDTH +: 4];
    @(posedge clock);
    #1ns;
    if (user_io[DESIGN_ID_WIDTH +: 4] === count_snapshot)
      $fatal(1, "design 2 counter did not advance through FrameTop");
    if (design1_edges != design1_snapshot)
      $fatal(1, "design 1 clock ran while design 2 was selected");

    test_io_oe[DESIGN_ID_WIDTH + 5] = 1'b1;
    test_io_out[DESIGN_ID_WIDTH + 5] = 1'b1;
    #1ns;
    if (user_io[DESIGN_ID_WIDTH + 4] !== 1'b1)
      $fatal(1, "design 2 did not read the external input");

    @(negedge clock);
    reset = 1'b1;
    repeat (2) @(posedge clock);
    #1ns;
    design2_snapshot = design2_edges;
    select_design(7'd1);
    if (!dut.design_selected[1] || design2_edges != design2_snapshot)
      $fatal(1, "reset reselection did not stop design 2 and start design 1");

    $display("FRAME DESIGN 2 TEST PASS");
    $finish;
  end

endmodule
