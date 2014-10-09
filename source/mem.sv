`include "mem_wb_if.vh"
`include "exec_mem_if.vh"

import cpu_types_pkg::*;

module mem (
  input logic CLK, nRST,
  input logic dhit,
  input word_t dmemload,
  output logic data_stall,
  output word_t mem_data,
  output logic dmemREN, dmemWEN,
  output word_t dmemaddr, dmemstore,
  exec_mem_if.mem in,
  mem_wb_if.mem out
);

  word_t last_npc;

  always_ff @ (posedge CLK, negedge nRST)
  begin
    if(!nRST) begin
      out.alu_result  <= 0;
      out.wsel        <= 0;
      out.wdat_source <= write_t'(0);
      out.halt        <= 0;
      out.instr_npc   <= 0;
      out.dmemload    <= 0;
      last_npc        <= 0;
      mem_data        <= 0;
    end
    else begin
      if (!data_stall) begin
        out.alu_result  <= in.alu_result;
        out.wsel        <= in.wsel;
        out.wdat_source <= in.wdat_source;
        out.halt        <= in.halt;
        out.instr_npc   <= in.instr_npc;
        out.dmemload    <= mem_data;
      end
      if (dhit)
        mem_data  <= dmemload;
      if (dhit || (!in.dmemREN && !in.dmemWEN))
        last_npc <= in.instr_npc;
    end
  end

  always_comb begin
    dmemaddr        <= in.alu_result;
    dmemREN         <= in.dmemREN && (last_npc != in.instr_npc);
    dmemWEN         <= in.dmemWEN && (last_npc != in.instr_npc);
    dmemstore       <= in.dmemstore;
    data_stall           <= (in.dmemREN || in.dmemWEN) && (last_npc != in.instr_npc);
  end
endmodule
