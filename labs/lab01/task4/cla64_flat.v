// cla64_flat.v
// A flat, unblocked 64-bit carry-lookahead adder: every carry is computed
// directly (two-level, no rippling), exactly like cla4.v, just scaled to
// 64 bits.

module cla64_flat(
  input  [63:0] a,
  input  [63:0] b,
  input         cin,
  output [63:0] sum,
  output        cout
);

  wire [63:0] p, g;
  wire [64:1] c;   // c[1]..c[64] are the 64 carries; think of cin as c[0]

  // ---------------------------------------------------------------------
  // Step 1: generate/propagate signals
  // ---------------------------------------------------------------------
  genvar i;
  generate
    for (i = 0; i < 64; i = i + 1) begin : gen_pg
      xor #(2) (p[i], a[i], b[i]);
      and #(2) (g[i], a[i], b[i]);
    end
  endgenerate

  // ---------------------------------------------------------------------
  // Step 2: 64 direct carry equations (2-level fan-in logic)
  // ---------------------------------------------------------------------
  assign #(2) c[1]  = g[0] | (p[0] & cin);
  assign #(2) c[2]  = g[1] | (p[1] & g[0]) | (p[1] & p[0] & cin);
  assign #(2) c[3]  = g[2] | (p[2] & g[1]) | (p[2] & p[1] & g[0]) | (p[2] & p[1] & p[0] & cin);
  assign #(2) c[4]  = g[3] | (p[3] & g[2]) | (p[3] & p[2] & g[1]) | (p[3] & p[2] & p[1] & g[0]) | (p[3] & p[2] & p[1] & p[0] & cin);
  
  // High fan-in carry generation using reduction and indexing
  // In real hardware synthesis, flat CLA scales up to massive AND/OR fan-in
  genvar k, j;
  generate
    for (k = 5; k <= 64; k = k + 1) begin : gen_carries
      wire [k:0] terms;
      assign terms[0] = g[k-1];
      for (j = 1; j < k; j = j + 1) begin : gen_terms
        assign terms[j] = (&p[k-1:k-j]) & g[k-j-1];
      end
      assign terms[k] = (&p[k-1:0]) & cin;
      assign #(2) c[k] = |terms;
    end
  endgenerate

  assign cout = c[64];

  // ---------------------------------------------------------------------
  // Step 3: sum bits
  // ---------------------------------------------------------------------
  assign #(2) sum = p ^ {c[63:1], cin};

endmodule