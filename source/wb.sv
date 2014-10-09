`include "mem_wb_if.vh"

import cpu_types_pkg::*;

module wb (
  input logic CLK, nRST,
  output logic halt,
  output logic WEN,
  output regbits_t wsel,
  output word_t wdat,
  mem_wb_if.wb in
);

  always @ (posedge CLK, negedge nRST) begin
    if (!nRST)
      halt <= 0;
    else
      halt <= in.halt;
  end
  always_comb begin
    WEN = 1;
    wsel = in.wsel;
    wdat = 0;
    case (in.wdat_source)
      WRITE_ALU     : wdat = in.alu_result;
      WRITE_RAM     : wdat = in.dmemload;
      WRITE_NPC     : wdat = in.instr_npc;
    endcase
  end
endmodule
