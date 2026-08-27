// Select one design's payload IO. Unselected designs cannot drive the bus.

module DesignIoMux #(
  parameter int IO_WIDTH = 66,
  parameter int DESIGN_COUNT = 128,
  parameter int DESIGN_ID_WIDTH = 7
) (
  input  logic select_enable,
  input  logic [DESIGN_ID_WIDTH-1:0] design_id,
  input  wire [DESIGN_COUNT-1:0][IO_WIDTH-1:0] designs_out,
  input  wire [DESIGN_COUNT-1:0][IO_WIDTH-1:0] designs_oe,
  output logic [IO_WIDTH-1:0] io_out,
  output logic [IO_WIDTH-1:0] io_oe
);

  always_comb begin
    io_out = '0;
    io_oe = '0;
    for (int index = 0; index < DESIGN_COUNT; index++) begin
      if (select_enable && design_id == index[DESIGN_ID_WIDTH-1:0]) begin
        io_out = designs_out[index];
        io_oe = designs_oe[index];
      end
    end
  end

endmodule
