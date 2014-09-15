`include "register_file_if.vh"
`include "cpu_types_pkg.vh"

import cpu_types_pkg::*;

module register_file (
  input CLK, nRST,
  register_file_if.rf rfif
);

word_t rf[31:0];

always_ff @(posedge CLK, negedge nRST)
begin
  if (!nRST)
    rf[31:0] <= '{default:0};
  else if (rfif.WEN && rfif.wsel != 0)
    rf[rfif.wsel] <= rfif.wdat;
  else
    rf[0] = '0;
end
always_comb
begin
  rfif.rdat1 = rf[rfif.rsel1];
  rfif.rdat2 = rf[rfif.rsel2];
end
endmodule
