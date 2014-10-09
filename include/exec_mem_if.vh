`ifndef EXEC_MEM_IF_VH
`define EXEC_MEM_IF_VH

`include "cpu_types_pkg.vh"

interface exec_mem_if;
  import cpu_types_pkg::*;

  word_t        alu_result;

  regbits_t     wsel;
  write_t       wdat_source;

  logic         halt;
  word_t        instr_npc;

  logic         dmemREN, dmemWEN;
  word_t        dmemstore;

  modport exec (
    output  alu_result,
            wsel, wdat_source,
            instr_npc, halt,
            dmemREN, dmemWEN, dmemstore
  );

  modport mem (
    input   alu_result,
            wsel, wdat_source,
            instr_npc, halt,
            dmemREN, dmemWEN, dmemstore
  );
endinterface

`endif
