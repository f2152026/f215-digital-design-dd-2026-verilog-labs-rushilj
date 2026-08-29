// cla4.v  (Task 5 version)
// Same gate-level 4-bit CLA as Task 3/4, extended with two extra outputs:
//   bg  -- block generate:  this block produces a carry regardless of cin
//           bg = g3 | p3.g2 | p3.p2.g1 | p3.p2.p1.g0
//   bp  -- block propagate: an incoming carry ripples through all 4 bits
//           bp = p3 & p2 & p1 & p0
// The second-level lookahead unit in cla64_hier uses bg/bp to compute each
// block's carry-in directly, eliminating the block-to-block ripple.

module cla4(
  input  [3:0] a,
  input  [3:0] b,
  input        cin,
  output [3:0] sum,
  output       cout,
  output       bg,
  output       bp
);

  wire p0, p1, p2, p3;
  wire g0, g1, g2, g3;
  wire c1, c2, c3;
  wire c1_t1;
  wire c2_t1, c2_t2;
  wire c3_t1, c3_t2, c3_t3;
  wire c4_t1, c4_t2, c4_t3, c4_t4;
  wire bg_t1, bg_t2, bg_t3;

  // Step 1: generate and propagate signals
  xor #(2) (p0, a[0], b[0]);
  xor #(2) (p1, a[1], b[1]);
  xor #(2) (p2, a[2], b[2]);
  xor #(2) (p3, a[3], b[3]);
  and #(2) (g0, a[0], b[0]);
  and #(2) (g1, a[1], b[1]);
  and #(2) (g2, a[2], b[2]);
  and #(2) (g3, a[3], b[3]);

  // Step 2: direct carry equations
  and #(2) (c1_t1, p0, cin);
  or  #(2) (c1, g0, c1_t1);

  and #(2) (c2_t1, p1, g0);
  and #(2) (c2_t2, p1, p0, cin);
  or  #(2) (c2, g1, c2_t1, c2_t2);

  and #(2) (c3_t1, p2, g1);
  and #(2) (c3_t2, p2, p1, g0);
  and #(2) (c3_t3, p2, p1, p0, cin);
  or  #(2) (c3, g2, c3_t1, c3_t2, c3_t3);

  and #(2) (c4_t1, p3, g2);
  and #(2) (c4_t2, p3, p2, g1);
  and #(2) (c4_t3, p3, p2, p1, g0);
  and #(2) (c4_t4, p3, p2, p1, p0, cin);
  or  #(2) (cout, g3, c4_t1, c4_t2, c4_t3, c4_t4);

  // Step 3: sum bits
  xor #(2) (sum[0], p0, cin);
  xor #(2) (sum[1], p1, c1);
  xor #(2) (sum[2], p2, c2);
  xor #(2) (sum[3], p3, c3);

  // Block-level summary signals (independent of cin)
  // bg = g3 | p3.g2 | p3.p2.g1 | p3.p2.p1.g0
  and #(2) (bg_t1, p3, g2);
  and #(2) (bg_t2, p3, p2, g1);
  and #(2) (bg_t3, p3, p2, p1, g0);
  or  #(2) (bg, g3, bg_t1, bg_t2, bg_t3);

  // bp = p3 & p2 & p1 & p0
  and #(2) (bp, p3, p2, p1, p0);

endmodule
