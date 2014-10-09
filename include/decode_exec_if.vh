`ifndef DECODE_EXEC_IF_VH
`define DECODE_EXEC_IF_VH

`include "cpu_types_pkg.vh"

interface decode_exec_if;
  import cpu_types_pkg::*;

  word_t        decode_alu_in1, decode_alu_in2;
  word_t        safe_alu_in1, safe_alu_in2;
  regbits_t     rs_alu_in, rt_alu_in;
  aluop_t       alu_aluop;

  regbits_t     wsel;
  write_t       wdat_source;

  logic         branch_instr;
  logic         branch_if_zero;
  word_t        branch_target;

  logic         halt;
  word_t        instr_npc;

  logic         dmemREN, dmemWEN;
  word_t        decode_dmemstore;
  word_t        safe_dmemstore;

  modport decode (
    output  decode_alu_in1, decode_alu_in2, alu_aluop,
            rs_alu_in, rt_alu_in,
            wsel, wdat_source,
            branch_instr, branch_if_zero, branch_target,
            halt, instr_npc,
            dmemREN, dmemWEN, decode_dmemstore
  );

  modport exec (
    input   safe_alu_in1, safe_alu_in2, alu_aluop,
            rs_alu_in, rt_alu_in,
            wsel, wdat_source,
            branch_instr, branch_if_zero, branch_target,
            halt, instr_npc,
            dmemREN, dmemWEN, safe_dmemstore
  );
endinterface

`endif
