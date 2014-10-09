`ifndef MEM_WB_IF_VH
`define MEM_WB_IF_VH

`include "cpu_types_pkg.vh"

interface mem_wb_if;
  import cpu_types_pkg::*;

  word_t        alu_result;

  regbits_t     wsel;
  write_t       wdat_source;

  word_t        instr_npc;
  logic         halt;

  word_t        dmemload;

  modport mem (
    output  alu_result,
            wsel, wdat_source,
            halt, instr_npc,
            dmemload
  );

  modport wb (
    input   alu_result,
            wsel, wdat_source,
            halt, instr_npc,
            dmemload
  );
endinterface

`endif
