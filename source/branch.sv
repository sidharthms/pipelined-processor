`include "datapath_cache_if.vh"
`include "exec_mem_if.vh"
`include "mem_wb_if.vh"

import cpu_types_pkg::*;

typedef struct {
  logic [1:0] taken;
  word_t instr_npc;
} branch_entry;

module branch (
  input logic CLK, nRST,
  input logic jump_instr,
  input logic branch_instr,
  input word_t branch_target,
  input logic alu_zero,
  input word_t pc,
  output logic misc_npc_en,
  output word_t misc_npc,
  output logic cancel_fetch,
  exec_mem_if.mem emif,
  decode_exec_if.exec deif,
  fetch_decode_if.decode fdif
);
  branch_entry prediction [1:0];
  branch_entry entry;
  logic should_branch;

  always_ff @ (posedge CLK, negedge nRST) begin
    if (!nRST)
      prediction <= '{default:0};
    else if (deif.branch_instr) begin
      if (prediction[deif.instr_npc[1:0]].instr_npc == deif.instr_npc) begin
        if (prediction[deif.instr_npc[1:0]].taken[0] == should_branch)
          prediction[deif.instr_npc[1:0]].taken[1] <= should_branch;
        prediction[deif.instr_npc[1:0]].taken[0] <= should_branch;
      end else begin
        prediction[deif.instr_npc[1:0]].instr_npc <= deif.instr_npc;
        prediction[deif.instr_npc[1:0]].taken <= 2'b11;
      end
    end
  end

  always_comb begin
    should_branch = alu_zero == deif.branch_if_zero;
    entry = prediction[fdif.instr_npc[1:0]];
    cancel_fetch = 0;
    misc_npc_en = 0;
    misc_npc = 0;
    if (deif.branch_instr) begin
      if (should_branch && deif.branch_target != pc) begin
        cancel_fetch = 1;
        misc_npc = deif.branch_target;
      end else if (!should_branch && deif.branch_target == pc) begin
        cancel_fetch = 1;
        misc_npc = deif.instr_npc;
      end
      misc_npc_en = cancel_fetch;
    end
    if (branch_instr && (entry.instr_npc == fdif.instr_npc && entry.taken[1] ||
                         entry.instr_npc != fdif.instr_npc)) begin
      misc_npc_en = 1;
      cancel_fetch = 1;
      misc_npc = branch_target;
    end

    if (jump_instr) begin
      misc_npc_en = 1;
      cancel_fetch = 1;
      misc_npc = branch_target;
    end
  end
endmodule
