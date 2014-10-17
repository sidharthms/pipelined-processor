`include "fetch_decode_if.vh"
`include "datapath_cache_if.vh"

import cpu_types_pkg::*;

module fetch (
  input logic CLK, nRST,
  input logic en, zero,
  input logic misc_npc_en,
  input word_t misc_npc,
  input logic ihit,
  input logic halt,
  input word_t imemload,
  input branch_taken,
  output word_t npc_default,
  output logic imemREN,
  output word_t imemaddr,
  fetch_decode_if.fetch out
);
  // pc init
  parameter PC_INIT = 0;

  word_t pc, npc;
  logic pause;
  always_ff @ (posedge CLK, negedge nRST) begin
    if (!nRST) begin
      pc                <= PC_INIT;
      out.instr_npc     <= 'd0;
      out.instruction   <= 'd0;
      out.branch_taken  <= 0;
    end else if (!pause) begin
      pc                <= npc;
      out.instr_npc     <= npc_default;
      if (ihit && !zero) begin
        out.instruction <= imemload;
        out.branch_taken  <= branch_taken;
      end else begin
        out.instruction <= 'd0;
        out.branch_taken  <= 0;
      end
    end
  end

  always_comb begin
    imemREN = 1;
    imemaddr = pc;
    npc_default = pc + 4;
    pause = !en || !ihit || halt;
    if (misc_npc_en)
      npc = misc_npc;
    else
      npc = npc_default;
  end
endmodule
