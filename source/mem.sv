`include "mem_wb_if.vh"
`include "exec_mem_if.vh"

import cpu_types_pkg::*;

module mem (
  input logic CLK, nRST,
  input logic en,
  input logic dhit,
  input word_t dmemload,
  input logic data_shadow,
  output logic data_stall,
  output word_t mem_data,
  output logic dmemREN, dmemWEN,
  output word_t dmemaddr, dmemstore,
  exec_mem_if.mem in,
  mem_wb_if.mem out
);
  logic shadow_stage;

  always_ff @ (posedge CLK, negedge nRST)
  begin
    if(!nRST) begin
      out.alu_result  <= 0;
      out.wsel        <= 0;
      out.wdat_source <= write_t'(0);
      out.halt        <= 0;
      out.instr_npc   <= 0;
      out.dmemload    <= 0;
      mem_data        <= 0;
      shadow_stage    <= 0;
    end
    else begin
      if (en) begin
        out.alu_result  <= in.alu_result;
        out.wsel        <= in.wsel;
        out.wdat_source <= in.wdat_source;
        out.halt        <= in.halt;
        out.instr_npc   <= in.instr_npc;
        out.dmemload    <= shadow_stage ? mem_data : dmemload;
      end
      if (dhit)
        mem_data        <= dmemload;
      if (data_shadow && dhit && !shadow_stage)
        shadow_stage  <= 1;
      else
        shadow_stage  <= 0;
    end
  end

  always_comb begin
    dmemaddr        = in.alu_result;
    dmemREN         = in.dmemREN && !shadow_stage;
    dmemWEN         = in.dmemWEN && !shadow_stage;
    dmemstore       = in.dmemstore;
    data_stall      = ((in.dmemREN || in.dmemWEN) && !dhit || data_shadow) && !shadow_stage;

  end
endmodule
