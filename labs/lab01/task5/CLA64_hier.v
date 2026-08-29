// CLA64_hier.v  (Task 5 -- Bonus)
// Hierarchical 64-bit carry-lookahead adder.
//
// Structure (2 levels):
//   Level 1 -- 16 four-bit CLA blocks (cla4), each exposing its block-level
//              generate (bg) and propagate (bp) summaries.
//   Level 2 -- a 16-term carry-lookahead unit that computes each block's
//              carry-in directly from bg[0..15], bp[0..15], and cin, with no
//              block-to-block ripple.
//
// Delay breakdown vs cla64_blocked (Task 4(b)):
//   cla64_blocked: P/G (2) + carry level 1 (4) + sum (2) = 8 time units for
//     each block, but the carry-in to block k ripples through k blocks of
//     (carry compute), so worst case = 2 + (carry_per_block)*16 + 2.
//     Each cla4 block's carry: 2 AND + 2 OR = 4 units. So worst case is
//     2 + 4*16 + 2 = 68 (though within each block it's still 2-level).
//     Actually cla4_blocked: carry ripples BETWEEN blocks (not within).
//     Within a block: 2-level, fast. Between blocks: ripple of 16 stages.
//     Each stage adds 4 units (the cla4 carry path). Worst: 2+4*16+2 = 68.
//
//   cla64_hier: P/G (2) + bg/bp (4) + second-level carry (4) + sum (2) = 12.
//     All block carry-ins land at time 10; sums settle at 12. Regardless of
//     which of the 16 blocks you're in.
//
// This matches the O(log n) prediction from Tutorial 3 Q4(d).

module cla64_hier(
  input  [63:0] a,
  input  [63:0] b,
  input         cin,
  output [63:0] sum,
  output        cout
);

  // Block-level generate and propagate from each cla4 block
  wire [15:0] bg, bp;
  // Block carry-ins: cin_blk[k] is the carry into block k
  wire [15:0] cin_blk;
  assign cin_blk[0] = cin;

  // Instantiate 16 four-bit CLA blocks
  cla4 block0  (.a(a[ 3: 0]),  .b(b[ 3: 0]),  .cin(cin_blk[0]),  .sum(sum[ 3: 0]),  .cout(), .bg(bg[0]),  .bp(bp[0]));
  cla4 block1  (.a(a[ 7: 4]),  .b(b[ 7: 4]),  .cin(cin_blk[1]),  .sum(sum[ 7: 4]),  .cout(), .bg(bg[1]),  .bp(bp[1]));
  cla4 block2  (.a(a[11: 8]),  .b(b[11: 8]),  .cin(cin_blk[2]),  .sum(sum[11: 8]),  .cout(), .bg(bg[2]),  .bp(bp[2]));
  cla4 block3  (.a(a[15:12]),  .b(b[15:12]),  .cin(cin_blk[3]),  .sum(sum[15:12]),  .cout(), .bg(bg[3]),  .bp(bp[3]));
  cla4 block4  (.a(a[19:16]),  .b(b[19:16]),  .cin(cin_blk[4]),  .sum(sum[19:16]),  .cout(), .bg(bg[4]),  .bp(bp[4]));
  cla4 block5  (.a(a[23:20]),  .b(b[23:20]),  .cin(cin_blk[5]),  .sum(sum[23:20]),  .cout(), .bg(bg[5]),  .bp(bp[5]));
  cla4 block6  (.a(a[27:24]),  .b(b[27:24]),  .cin(cin_blk[6]),  .sum(sum[27:24]),  .cout(), .bg(bg[6]),  .bp(bp[6]));
  cla4 block7  (.a(a[31:28]),  .b(b[31:28]),  .cin(cin_blk[7]),  .sum(sum[31:28]),  .cout(), .bg(bg[7]),  .bp(bp[7]));
  cla4 block8  (.a(a[35:32]),  .b(b[35:32]),  .cin(cin_blk[8]),  .sum(sum[35:32]),  .cout(), .bg(bg[8]),  .bp(bp[8]));
  cla4 block9  (.a(a[39:36]),  .b(b[39:36]),  .cin(cin_blk[9]),  .sum(sum[39:36]),  .cout(), .bg(bg[9]),  .bp(bp[9]));
  cla4 block10 (.a(a[43:40]),  .b(b[43:40]),  .cin(cin_blk[10]), .sum(sum[43:40]),  .cout(), .bg(bg[10]), .bp(bp[10]));
  cla4 block11 (.a(a[47:44]),  .b(b[47:44]),  .cin(cin_blk[11]), .sum(sum[47:44]),  .cout(), .bg(bg[11]), .bp(bp[11]));
  cla4 block12 (.a(a[51:48]),  .b(b[51:48]),  .cin(cin_blk[12]), .sum(sum[51:48]),  .cout(), .bg(bg[12]), .bp(bp[12]));
  cla4 block13 (.a(a[55:52]),  .b(b[55:52]),  .cin(cin_blk[13]), .sum(sum[55:52]),  .cout(), .bg(bg[13]), .bp(bp[13]));
  cla4 block14 (.a(a[59:56]),  .b(b[59:56]),  .cin(cin_blk[14]), .sum(sum[59:56]),  .cout(), .bg(bg[14]), .bp(bp[14]));
  cla4 block15 (.a(a[63:60]),  .b(b[63:60]),  .cin(cin_blk[15]), .sum(sum[63:60]),  .cout(), .bg(bg[15]), .bp(bp[15]));

  // Second-level lookahead: compute cin_blk[1..15] and cout directly.
  // cin_blk[k] = bg[k-1] | bp[k-1].bg[k-2] | ... | bp[k-1]...bp[0].cin
  // This mirrors the cla4 carry equations, just with bg/bp instead of g/p.
  assign #(2) cin_blk[1]  = bg[0] | (bp[0] & cin);
  assign #(2) cin_blk[2]  = bg[1] | (bp[1] & bg[0]) | (bp[1] & bp[0] & cin);
  assign #(2) cin_blk[3]  = bg[2] | (bp[2] & bg[1]) | (bp[2] & bp[1] & bg[0]) | (bp[2] & bp[1] & bp[0] & cin);
  assign #(2) cin_blk[4]  = bg[3] | (bp[3] & bg[2]) | (bp[3] & bp[2] & bg[1]) | (bp[3] & bp[2] & bp[1] & bg[0]) | (bp[3] & bp[2] & bp[1] & bp[0] & cin);
  assign #(2) cin_blk[5]  = bg[4] | (bp[4] & bg[3]) | (bp[4] & bp[3] & bg[2]) | (bp[4] & bp[3] & bp[2] & bg[1]) | (bp[4] & bp[3] & bp[2] & bp[1] & bg[0]) | (bp[4] & bp[3] & bp[2] & bp[1] & bp[0] & cin);
  assign #(2) cin_blk[6]  = bg[5] | (bp[5] & bg[4]) | (bp[5] & bp[4] & bg[3]) | (bp[5] & bp[4] & bp[3] & bg[2]) | (bp[5] & bp[4] & bp[3] & bp[2] & bg[1]) | (bp[5] & bp[4] & bp[3] & bp[2] & bp[1] & bg[0]) | (bp[5] & bp[4] & bp[3] & bp[2] & bp[1] & bp[0] & cin);
  assign #(2) cin_blk[7]  = bg[6] | (bp[6] & bg[5]) | (bp[6] & bp[5] & bg[4]) | (bp[6] & bp[5] & bp[4] & bg[3]) | (bp[6] & bp[5] & bp[4] & bp[3] & bg[2]) | (bp[6] & bp[5] & bp[4] & bp[3] & bp[2] & bg[1]) | (bp[6] & bp[5] & bp[4] & bp[3] & bp[2] & bp[1] & bg[0]) | (bp[6] & bp[5] & bp[4] & bp[3] & bp[2] & bp[1] & bp[0] & cin);
  assign #(2) cin_blk[8]  = bg[7] | (bp[7] & bg[6]) | (bp[7] & bp[6] & bg[5]) | (bp[7] & bp[6] & bp[5] & bg[4]) | (bp[7] & bp[6] & bp[5] & bp[4] & bg[3]) | (bp[7] & bp[6] & bp[5] & bp[4] & bp[3] & bg[2]) | (bp[7] & bp[6] & bp[5] & bp[4] & bp[3] & bp[2] & bg[1]) | (bp[7] & bp[6] & bp[5] & bp[4] & bp[3] & bp[2] & bp[1] & bg[0]) | (bp[7] & bp[6] & bp[5] & bp[4] & bp[3] & bp[2] & bp[1] & bp[0] & cin);
  assign #(2) cin_blk[9]  = bg[8] | (bp[8] & bg[7]) | (bp[8] & bp[7] & bg[6]) | (bp[8] & bp[7] & bp[6] & bg[5]) | (bp[8] & bp[7] & bp[6] & bp[5] & bg[4]) | (bp[8] & bp[7] & bp[6] & bp[5] & bp[4] & bg[3]) | (bp[8] & bp[7] & bp[6] & bp[5] & bp[4] & bp[3] & bg[2]) | (bp[8] & bp[7] & bp[6] & bp[5] & bp[4] & bp[3] & bp[2] & bg[1]) | (bp[8] & bp[7] & bp[6] & bp[5] & bp[4] & bp[3] & bp[2] & bp[1] & bg[0]) | (bp[8] & bp[7] & bp[6] & bp[5] & bp[4] & bp[3] & bp[2] & bp[1] & bp[0] & cin);
  assign #(2) cin_blk[10] = bg[9] | (bp[9] & bg[8]) | (bp[9] & bp[8] & bg[7]) | (bp[9] & bp[8] & bp[7] & bg[6]) | (bp[9] & bp[8] & bp[7] & bp[6] & bg[5]) | (bp[9] & bp[8] & bp[7] & bp[6] & bp[5] & bg[4]) | (bp[9] & bp[8] & bp[7] & bp[6] & bp[5] & bp[4] & bg[3]) | (bp[9] & bp[8] & bp[7] & bp[6] & bp[5] & bp[4] & bp[3] & bg[2]) | (bp[9] & bp[8] & bp[7] & bp[6] & bp[5] & bp[4] & bp[3] & bp[2] & bg[1]) | (bp[9] & bp[8] & bp[7] & bp[6] & bp[5] & bp[4] & bp[3] & bp[2] & bp[1] & bg[0]) | (bp[9] & bp[8] & bp[7] & bp[6] & bp[5] & bp[4] & bp[3] & bp[2] & bp[1] & bp[0] & cin);
  assign #(2) cin_blk[11] = bg[10] | (bp[10] & bg[9]) | (bp[10] & bp[9] & bg[8]) | (bp[10] & bp[9] & bp[8] & bg[7]) | (bp[10] & bp[9] & bp[8] & bp[7] & bg[6]) | (bp[10] & bp[9] & bp[8] & bp[7] & bp[6] & bg[5]) | (bp[10] & bp[9] & bp[8] & bp[7] & bp[6] & bp[5] & bg[4]) | (bp[10] & bp[9] & bp[8] & bp[7] & bp[6] & bp[5] & bp[4] & bg[3]) | (bp[10] & bp[9] & bp[8] & bp[7] & bp[6] & bp[5] & bp[4] & bp[3] & bg[2]) | (bp[10] & bp[9] & bp[8] & bp[7] & bp[6] & bp[5] & bp[4] & bp[3] & bp[2] & bg[1]) | (bp[10] & bp[9] & bp[8] & bp[7] & bp[6] & bp[5] & bp[4] & bp[3] & bp[2] & bp[1] & bg[0]) | (bp[10] & bp[9] & bp[8] & bp[7] & bp[6] & bp[5] & bp[4] & bp[3] & bp[2] & bp[1] & bp[0] & cin);
  assign #(2) cin_blk[12] = bg[11] | (bp[11] & bg[10]) | (bp[11] & bp[10] & bg[9]) | (bp[11] & bp[10] & bp[9] & bg[8]) | (bp[11] & bp[10] & bp[9] & bp[8] & bg[7]) | (bp[11] & bp[10] & bp[9] & bp[8] & bp[7] & bg[6]) | (bp[11] & bp[10] & bp[9] & bp[8] & bp[7] & bp[6] & bg[5]) | (bp[11] & bp[10] & bp[9] & bp[8] & bp[7] & bp[6] & bp[5] & bg[4]) | (bp[11] & bp[10] & bp[9] & bp[8] & bp[7] & bp[6] & bp[5] & bp[4] & bg[3]) | (bp[11] & bp[10] & bp[9] & bp[8] & bp[7] & bp[6] & bp[5] & bp[4] & bp[3] & bg[2]) | (bp[11] & bp[10] & bp[9] & bp[8] & bp[7] & bp[6] & bp[5] & bp[4] & bp[3] & bp[2] & bg[1]) | (bp[11] & bp[10] & bp[9] & bp[8] & bp[7] & bp[6] & bp[5] & bp[4] & bp[3] & bp[2] & bp[1] & bg[0]) | (bp[11] & bp[10] & bp[9] & bp[8] & bp[7] & bp[6] & bp[5] & bp[4] & bp[3] & bp[2] & bp[1] & bp[0] & cin);
  assign #(2) cin_blk[13] = bg[12] | (bp[12] & bg[11]) | (bp[12] & bp[11] & bg[10]) | (bp[12] & bp[11] & bp[10] & bg[9]) | (bp[12] & bp[11] & bp[10] & bp[9] & bg[8]) | (bp[12] & bp[11] & bp[10] & bp[9] & bp[8] & bg[7]) | (bp[12] & bp[11] & bp[10] & bp[9] & bp[8] & bp[7] & bg[6]) | (bp[12] & bp[11] & bp[10] & bp[9] & bp[8] & bp[7] & bp[6] & bg[5]) | (bp[12] & bp[11] & bp[10] & bp[9] & bp[8] & bp[7] & bp[6] & bp[5] & bg[4]) | (bp[12] & bp[11] & bp[10] & bp[9] & bp[8] & bp[7] & bp[6] & bp[5] & bp[4] & bg[3]) | (bp[12] & bp[11] & bp[10] & bp[9] & bp[8] & bp[7] & bp[6] & bp[5] & bp[4] & bp[3] & bg[2]) | (bp[12] & bp[11] & bp[10] & bp[9] & bp[8] & bp[7] & bp[6] & bp[5] & bp[4] & bp[3] & bp[2] & bg[1]) | (bp[12] & bp[11] & bp[10] & bp[9] & bp[8] & bp[7] & bp[6] & bp[5] & bp[4] & bp[3] & bp[2] & bp[1] & bg[0]) | (bp[12] & bp[11] & bp[10] & bp[9] & bp[8] & bp[7] & bp[6] & bp[5] & bp[4] & bp[3] & bp[2] & bp[1] & bp[0] & cin);
  assign #(2) cin_blk[14] = bg[13] | (bp[13] & bg[12]) | (bp[13] & bp[12] & bg[11]) | (bp[13] & bp[12] & bp[11] & bg[10]) | (bp[13] & bp[12] & bp[11] & bp[10] & bg[9]) | (bp[13] & bp[12] & bp[11] & bp[10] & bp[9] & bg[8]) | (bp[13] & bp[12] & bp[11] & bp[10] & bp[9] & bp[8] & bg[7]) | (bp[13] & bp[12] & bp[11] & bp[10] & bp[9] & bp[8] & bp[7] & bg[6]) | (bp[13] & bp[12] & bp[11] & bp[10] & bp[9] & bp[8] & bp[7] & bp[6] & bg[5]) | (bp[13] & bp[12] & bp[11] & bp[10] & bp[9] & bp[8] & bp[7] & bp[6] & bp[5] & bg[4]) | (bp[13] & bp[12] & bp[11] & bp[10] & bp[9] & bp[8] & bp[7] & bp[6] & bp[5] & bp[4] & bg[3]) | (bp[13] & bp[12] & bp[11] & bp[10] & bp[9] & bp[8] & bp[7] & bp[6] & bp[5] & bp[4] & bp[3] & bg[2]) | (bp[13] & bp[12] & bp[11] & bp[10] & bp[9] & bp[8] & bp[7] & bp[6] & bp[5] & bp[4] & bp[3] & bp[2] & bg[1]) | (bp[13] & bp[12] & bp[11] & bp[10] & bp[9] & bp[8] & bp[7] & bp[6] & bp[5] & bp[4] & bp[3] & bp[2] & bp[1] & bg[0]) | (bp[13] & bp[12] & bp[11] & bp[10] & bp[9] & bp[8] & bp[7] & bp[6] & bp[5] & bp[4] & bp[3] & bp[2] & bp[1] & bp[0] & cin);
  assign #(2) cin_blk[15] = bg[14] | (bp[14] & bg[13]) | (bp[14] & bp[13] & bg[12]) | (bp[14] & bp[13] & bp[12] & bg[11]) | (bp[14] & bp[13] & bp[12] & bp[11] & bg[10]) | (bp[14] & bp[13] & bp[12] & bp[11] & bp[10] & bg[9]) | (bp[14] & bp[13] & bp[12] & bp[11] & bp[10] & bp[9] & bg[8]) | (bp[14] & bp[13] & bp[12] & bp[11] & bp[10] & bp[9] & bp[8] & bg[7]) | (bp[14] & bp[13] & bp[12] & bp[11] & bp[10] & bp[9] & bp[8] & bp[7] & bg[6]) | (bp[14] & bp[13] & bp[12] & bp[11] & bp[10] & bp[9] & bp[8] & bp[7] & bp[6] & bg[5]) | (bp[14] & bp[13] & bp[12] & bp[11] & bp[10] & bp[9] & bp[8] & bp[7] & bp[6] & bp[5] & bg[4]) | (bp[14] & bp[13] & bp[12] & bp[11] & bp[10] & bp[9] & bp[8] & bp[7] & bp[6] & bp[5] & bp[4] & bg[3]) | (bp[14] & bp[13] & bp[12] & bp[11] & bp[10] & bp[9] & bp[8] & bp[7] & bp[6] & bp[5] & bp[4] & bp[3] & bg[2]) | (bp[14] & bp[13] & bp[12] & bp[11] & bp[10] & bp[9] & bp[8] & bp[7] & bp[6] & bp[5] & bp[4] & bp[3] & bp[2] & bg[1]) | (bp[14] & bp[13] & bp[12] & bp[11] & bp[10] & bp[9] & bp[8] & bp[7] & bp[6] & bp[5] & bp[4] & bp[3] & bp[2] & bp[1] & bg[0]) | (bp[14] & bp[13] & bp[12] & bp[11] & bp[10] & bp[9] & bp[8] & bp[7] & bp[6] & bp[5] & bp[4] & bp[3] & bp[2] & bp[1] & bp[0] & cin);

  // cout = second-level carry out of block 15
  assign #(2) cout = bg[15] | (bp[15] & bg[14]) | (bp[15] & bp[14] & bg[13]) | (bp[15] & bp[14] & bp[13] & bg[12]) | (bp[15] & bp[14] & bp[13] & bp[12] & bg[11]) | (bp[15] & bp[14] & bp[13] & bp[12] & bp[11] & bg[10]) | (bp[15] & bp[14] & bp[13] & bp[12] & bp[11] & bp[10] & bg[9]) | (bp[15] & bp[14] & bp[13] & bp[12] & bp[11] & bp[10] & bp[9] & bg[8]) | (bp[15] & bp[14] & bp[13] & bp[12] & bp[11] & bp[10] & bp[9] & bp[8] & bg[7]) | (bp[15] & bp[14] & bp[13] & bp[12] & bp[11] & bp[10] & bp[9] & bp[8] & bp[7] & bg[6]) | (bp[15] & bp[14] & bp[13] & bp[12] & bp[11] & bp[10] & bp[9] & bp[8] & bp[7] & bp[6] & bg[5]) | (bp[15] & bp[14] & bp[13] & bp[12] & bp[11] & bp[10] & bp[9] & bp[8] & bp[7] & bp[6] & bp[5] & bg[4]) | (bp[15] & bp[14] & bp[13] & bp[12] & bp[11] & bp[10] & bp[9] & bp[8] & bp[7] & bp[6] & bp[5] & bp[4] & bg[3]) | (bp[15] & bp[14] & bp[13] & bp[12] & bp[11] & bp[10] & bp[9] & bp[8] & bp[7] & bp[6] & bp[5] & bp[4] & bp[3] & bg[2]) | (bp[15] & bp[14] & bp[13] & bp[12] & bp[11] & bp[10] & bp[9] & bp[8] & bp[7] & bp[6] & bp[5] & bp[4] & bp[3] & bp[2] & bg[1]) | (bp[15] & bp[14] & bp[13] & bp[12] & bp[11] & bp[10] & bp[9] & bp[8] & bp[7] & bp[6] & bp[5] & bp[4] & bp[3] & bp[2] & bp[1] & bg[0]) | (bp[15] & bp[14] & bp[13] & bp[12] & bp[11] & bp[10] & bp[9] & bp[8] & bp[7] & bp[6] & bp[5] & bp[4] & bp[3] & bp[2] & bp[1] & bp[0] & cin);

endmodule
