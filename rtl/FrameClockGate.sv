// Technology-independent glitch-free clock gate.
// The enable latch may be replaced with a process ICG cell during tapeout.

module FrameClockGate (
  input  logic clock,
  input  logic enable,
  output wire  gated_clock
);

  logic enable_latched;

  always_latch begin
    if (!clock)
      enable_latched = enable;
  end

  assign gated_clock = clock & enable_latched;

endmodule
