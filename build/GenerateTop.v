// mpc-frame multi-project chip top-level template.
//
// This top level is intentionally empty. It does not instantiate any CPU, bus,
// peripheral, memory controller, simulation model, or fixed-function IP.
//
// All 73 user pads are exposed as generic bidirectional IO. The pad function,
// direction, protocol, timing, and internal implementation are decided by each
// shuttle user.

module GenerateTop(
  input clock,
  input reset,
  inout [72:0] user_io
);

  // Keep the top-level inputs referenced so strict lint flows do not report
  // them as completely unused in the empty template.
  wire unused_inputs = &{clock, reset, user_io};

endmodule
