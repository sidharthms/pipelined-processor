`include "datapath_cache_if.vh"
`include "exec_mem_if.vh"
`include "mem_wb_if.vh"

import cpu_types_pkg::*;

typedef struct {
  logic [1:0] taken;
  word_t instr_npc;
  word_t branch_target;
  logic valid;
} branch_entry;

module branch (
  input logic CLK, nRST,
  input logic jump_instr,
  input word_t branch_target,
  input logic alu_zero,
  input word_t npc_default,
  output logic misc_npc_en,
  output word_t misc_npc,
  output logic cancel_fetch,
  output logic squash,
  output logic branch_taken,
  exec_mem_if.mem emif,
  decode_exec_if.exec deif,
  fetch_decode_if.decode fdif
);
  branch_entry prediction [3:0];
  branch_entry entry;
  logic should_branch;
  r_t decode_rtype_instr;

  int i;

  assign decode_rtype_instr = r_t'(fdif.instruction);
  always_ff @ (posedge CLK, negedge nRST) begin
    if (!nRST) begin
      for (i = 0; i < 4; i += 1) begin
        prediction[i].valid <= 0;
      end
    end
    else if (deif.branch_instr) begin
      if (!prediction[deif.instr_npc[3:2]].valid)
        prediction[deif.instr_npc[3:2]].taken <= 2'b11;
      else begin
        if (prediction[deif.instr_npc[3:2]].taken[0] == should_branch)
          prediction[deif.instr_npc[3:2]].taken[1] <= should_branch;
        prediction[deif.instr_npc[3:2]].taken[0] <= should_branch;
      end
      prediction[deif.instr_npc[3:2]].branch_target <= deif.branch_target;
      prediction[deif.instr_npc[3:2]].instr_npc <= deif.instr_npc;
      prediction[deif.instr_npc[3:2]].valid <= 1;
    end else if (jump_instr && decode_rtype_instr.opcode != JR) begin
      prediction[deif.instr_npc[3:2]].taken <= 2'b11;
      prediction[deif.instr_npc[3:2]].branch_target <= branch_target;
      prediction[deif.instr_npc[3:2]].instr_npc <= fdif.instr_npc;
      prediction[deif.instr_npc[3:2]].valid <= 1;
    end
  end

  always_comb begin
    should_branch = alu_zero == deif.branch_if_zero;
    entry = prediction[npc_default[3:2]];
    cancel_fetch = 0;
    misc_npc_en = 0;
    misc_npc = 0;
    squash = 0;
    branch_taken = 0;

    if (entry.valid && entry.instr_npc == npc_default && entry.taken[1])
    begin
      misc_npc_en = 1;
      cancel_fetch = 0;
      branch_taken = 1;
      misc_npc = entry.branch_target;
    end
    if (jump_instr && !fdif.branch_taken) begin
      misc_npc_en = 1;
      cancel_fetch = 1;
      branch_taken = 0;
      misc_npc = branch_target;
    end
    if (deif.branch_instr) begin
      if (should_branch && (!deif.branch_taken || (deif.branch_taken
          && deif.branch_target != (fdif.instr_npc - 4)))) begin
        misc_npc_en = 1;
        cancel_fetch = 1;
        squash = 1;
        misc_npc = deif.branch_target;
      end else if (!should_branch && deif.branch_taken) begin
        misc_npc_en = 1;
        cancel_fetch = 1;
        squash = 1;
        misc_npc = deif.instr_npc;
      end
    end
  end
endmodule
