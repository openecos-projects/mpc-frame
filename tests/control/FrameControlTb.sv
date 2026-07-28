module FrameControlTb;

  localparam int DESIGN_COUNT = 128;
  localparam int DESIGN_ID_WIDTH = 7;
  localparam int IO_WIDTH = 8;
  localparam time HALF_PERIOD = 5ns;

  logic clock = 1'b0;
  logic reset = 1'b1;
  logic [DESIGN_ID_WIDTH-1:0] async_design_id = '0;
  logic [DESIGN_ID_WIDTH-1:0] design_id;
  logic selection_valid;
  logic [DESIGN_COUNT-1:0] design_selected;
  logic [DESIGN_COUNT-1:0] design_present = '0;
  logic [DESIGN_COUNT-1:0] design_clock_enable;
  logic [DESIGN_COUNT-1:0] design_reset;
  wire [DESIGN_COUNT-1:0] design_clock;
  logic [DESIGN_COUNT-1:0][IO_WIDTH-1:0] designs_out;
  logic [DESIGN_COUNT-1:0][IO_WIDTH-1:0] designs_oe;
  logic [IO_WIDTH-1:0] io_out;
  logic [IO_WIDTH-1:0] io_oe;
  integer clock_edges [DESIGN_COUNT];
  time clock_rise_time [DESIGN_COUNT];

  always #(HALF_PERIOD) clock = ~clock;

  FrameDesignControl #(
    .DESIGN_COUNT(DESIGN_COUNT), .DESIGN_ID_WIDTH(DESIGN_ID_WIDTH),
    .RESET_RELEASE_CYCLES(2)
  ) u_control (
    .clock(clock), .reset(reset), .async_design_id(async_design_id),
    .design_present(design_present),
    .design_id(design_id), .selection_valid(selection_valid),
    .design_selected(design_selected),
    .design_clock_enable(design_clock_enable), .design_reset(design_reset)
  );

  genvar design_index;
  generate
    for (design_index = 0; design_index < DESIGN_COUNT; design_index++) begin : g_clock
      FrameClockGate u_gate (
        .clock(clock), .enable(design_clock_enable[design_index]),
        .gated_clock(design_clock[design_index])
      );

      always @(posedge design_clock[design_index]) begin
        if (!clock)
          $fatal(1, "gated clock %0d rose while source clock was low", design_index);
        clock_edges[design_index] = clock_edges[design_index] + 1;
        clock_rise_time[design_index] = $time;
      end

      always @(negedge design_clock[design_index]) begin
        if (clock_rise_time[design_index] != 0 &&
            ($time - clock_rise_time[design_index]) < HALF_PERIOD)
          $fatal(1, "gated clock %0d produced a short pulse", design_index);
      end
    end
  endgenerate

  DesignIoMux #(
    .IO_WIDTH(IO_WIDTH), .DESIGN_COUNT(DESIGN_COUNT),
    .DESIGN_ID_WIDTH(DESIGN_ID_WIDTH)
  ) u_io_mux (
    .select_enable(selection_valid), .design_id(design_id),
    .designs_out(designs_out), .designs_oe(designs_oe),
    .io_out(io_out), .io_oe(io_oe)
  );

  task automatic expect_reset_safe;
    begin
      if (selection_valid || design_selected != '0 || design_clock_enable != '0)
        $fatal(1, "a design was enabled while reset was active");
      if (design_reset != '1)
        $fatal(1, "not all designs were held in reset");
      if (io_oe != '0)
        $fatal(1, "payload IO was driven before selection became valid");
    end
  endtask

  task automatic reject_unregistered(input int unsigned target);
    integer edge_snapshot [DESIGN_COUNT];
    logic [DESIGN_ID_WIDTH-1:0] target_id;
    begin
      target_id = DESIGN_ID_WIDTH'(target);
      @(negedge clock);
      async_design_id = target_id;
      reset = 1'b1;
      repeat (20) @(posedge clock);
      #1ns;
      expect_reset_safe();
      if (design_id != target_id)
        $fatal(1, "unregistered design ID %0d was not sampled", target);

      for (int index = 0; index < DESIGN_COUNT; index++)
        edge_snapshot[index] = clock_edges[index];

      @(negedge clock);
      reset = 1'b0;
      repeat (4) @(posedge clock);
      #1ns;
      if (selection_valid || design_selected != '0 || design_clock_enable != '0)
        $fatal(1, "unregistered design %0d was enabled", target);
      if (design_reset != '1 || io_oe != '0)
        $fatal(1, "unregistered design %0d escaped isolation", target);
      for (int index = 0; index < DESIGN_COUNT; index++) begin
        if (clock_edges[index] != edge_snapshot[index])
          $fatal(1, "clock %0d ran for unregistered design %0d", index, target);
      end
    end
  endtask

  task automatic select_and_run(
    input int unsigned target,
    input bit offset_reset_phase
  );
    integer edge_snapshot [DESIGN_COUNT];
    logic [DESIGN_ID_WIDTH-1:0] target_id;
    begin
      target_id = DESIGN_ID_WIDTH'(target);
      if (offset_reset_phase) begin
        @(posedge clock);
        #1ns;
      end else begin
        @(negedge clock);
      end
      async_design_id = target_id;
      reset = 1'b1;

      @(posedge clock);
      #1ns;
      expect_reset_safe();

      repeat (19) @(posedge clock);
      #1ns;
      expect_reset_safe();
      if (design_id != target_id)
        $fatal(1, "design ID %0d was not synchronized during reset", target);

      if (offset_reset_phase) begin
        @(posedge clock);
        #1ns;
      end else begin
        @(negedge clock);
      end
      reset = 1'b0;
      #1ns;
      if (!$onehot(design_selected) || !design_selected[target])
        $fatal(1, "design %0d was not selected after reset", target);
      if (selection_valid || io_oe != '0)
        $fatal(1, "design %0d drove IO before reset hold completed", target);

      repeat (3) @(posedge clock);
      #1ns;
      if (!selection_valid)
        $fatal(1, "design %0d did not leave internal reset", target);
      if (design_reset[target])
        $fatal(1, "selected design %0d remained in reset", target);
      if ((design_reset | design_selected) != '1)
        $fatal(1, "an unselected design left reset");
      if (io_oe != '1 || io_out != IO_WIDTH'(target))
        $fatal(1, "IO mux did not expose selected design %0d", target);

      for (int index = 0; index < DESIGN_COUNT; index++)
        edge_snapshot[index] = clock_edges[index];

      async_design_id = target_id ^ DESIGN_ID_WIDTH'(7'h55);
      repeat (4) @(posedge clock);
      #1ns;
      if (design_id != target_id || !design_selected[target])
        $fatal(1, "runtime selector changes affected design %0d", target);
      for (int index = 0; index < DESIGN_COUNT; index++) begin
        if (index == target) begin
          if (clock_edges[index] == edge_snapshot[index])
            $fatal(1, "selected design %0d clock stopped", target);
        end else if (clock_edges[index] != edge_snapshot[index]) begin
          $fatal(1, "unselected design %0d received a clock edge", index);
        end
      end
    end
  endtask

  initial begin
    design_present[0] = 1'b1;
    design_present[1] = 1'b1;
    design_present[127] = 1'b1;

    for (int index = 0; index < DESIGN_COUNT; index++) begin
      designs_out[index] = IO_WIDTH'(index);
      designs_oe[index] = '1;
      clock_edges[index] = 0;
      clock_rise_time[index] = 0;
    end

    select_and_run(0, 1'b0);
    select_and_run(1, 1'b1);
    select_and_run(127, 1'b0);
    reject_unregistered(2);

    @(negedge clock);
    reset = 1'b1;
    @(posedge clock);
    #1ns;
    expect_reset_safe();

    $display("FRAME CONTROL TEST PASS");
    $finish;
  end

endmodule
