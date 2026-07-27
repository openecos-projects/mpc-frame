module apb_delayer (
    input  wire        clock,
    input  wire        reset,
    input  wire        in_psel,
    input  wire        in_penable,
    input  wire        in_pwrite,
    input  wire [31:0] in_paddr,
    input  wire [2:0]  in_pprot,
    input  wire [31:0] in_pwdata,
    input  wire [3:0]  in_pstrb,
    output wire        in_pready,
    output wire        in_pslverr,
    output wire [31:0] in_prdata,
    output wire        out_psel,
    output wire        out_penable,
    output wire        out_pwrite,
    output wire [31:0] out_paddr,
    output wire [2:0]  out_pprot,
    output wire [31:0] out_pwdata,
    output wire [3:0]  out_pstrb,
    input  wire        out_pready,
    input  wire        out_pslverr,
    input  wire [31:0] out_prdata
);
  assign out_psel = in_psel;
  assign out_penable = in_penable;
  assign out_pwrite = in_pwrite;
  assign out_paddr = in_paddr;
  assign out_pprot = in_pprot;
  assign out_pwdata = in_pwdata;
  assign out_pstrb = in_pstrb;

  assign in_pready = out_pready;
  assign in_pslverr = out_pslverr;
  assign in_prdata = out_prdata;

  wire unused = clock & reset;
endmodule
