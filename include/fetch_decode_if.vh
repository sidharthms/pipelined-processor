`ifndef FETCH_DECODE_IF_VH
`define FETCH_DECODE_IF_VH

`include "cpu_types_pkg.vh"

interface fetch_decode_if;
  import cpu_types_pkg::*;

  word_t instruction, instr_npc;
  word_t branch_target;
  logic branch_taken;

  modport fetch (
    output  instruction, instr_npc, branch_taken,
    input   branch_target
  );

  modport decode (
    input   instruction, instr_npc, branch_taken,
    output  branch_target
  );
endinterface

`endif
