`include "datapath_cache_if.vh"
`include "fetch_decode_if.vh"
`include "exec_mem_if.vh"
`include "mem_wb_if.vh"
`include "datapath_cache_if.vh"

import cpu_types_pkg::*;

module forward (
  input logic CLK, nRST,
  input logic data_stall,
  input word_t dmemload,
  mem_wb_if.wb mwif,
  exec_mem_if.mem emif,
  decode_exec_if deif,
  fetch_decode_if.decode fdif
);
  logic mem_rs_match, mem_rt_match;
  logic wb_rs_match, wb_rt_match;

  always_comb begin
    mem_rs_match = emif.wsel == deif.rs_alu_in;
    mem_rt_match = emif.wsel == deif.rt_alu_in;
    wb_rs_match  = mwif.wsel == deif.rs_alu_in;
    wb_rt_match  = mwif.wsel == deif.rt_alu_in;

    deif.safe_alu_in1 = deif.decode_alu_in1;
    deif.safe_alu_in2 = deif.decode_alu_in2;
    deif.safe_dmemstore = deif.decode_dmemstore;
    if (emif.wsel != 0) begin
      if (emif.wdat_source == WRITE_RAM && !data_stall) begin
        if (mem_rs_match)
          deif.safe_alu_in1 = dmemload;
        if (mem_rt_match) begin
          if (deif.dmemWEN)
            deif.safe_dmemstore = dmemload;
          else
            deif.safe_alu_in2 = dmemload;
        end
      end else if (emif.wdat_source == WRITE_ALU) begin
        if (mem_rs_match)
          deif.safe_alu_in1 = emif.alu_result;
        if (mem_rt_match) begin
          if (deif.dmemWEN)
            deif.safe_dmemstore = emif.alu_result;
          else
            deif.safe_alu_in2 = emif.alu_result;
        end
      end else begin
        if (mem_rs_match)
          deif.safe_alu_in1 = emif.instr_npc;
        if (mem_rt_match) begin
          if (deif.dmemWEN)
            deif.safe_dmemstore = emif.instr_npc;
          else
            deif.safe_alu_in2 = emif.instr_npc;
        end
      end
    end
    if (mwif.wsel != 0) begin
      if (mwif.wdat_source == WRITE_RAM) begin
        if (wb_rs_match)
          deif.safe_alu_in1 = mwif.dmemload;
        if (wb_rt_match) begin
          if (deif.dmemWEN)
            deif.safe_dmemstore = mwif.dmemload;
          else
            deif.safe_alu_in2 = mwif.dmemload;
        end
      end else if (mwif.wdat_source == WRITE_ALU) begin
        if (wb_rs_match)
          deif.safe_alu_in1 = mwif.alu_result;
        if (wb_rt_match) begin
          if (deif.dmemWEN)
            deif.safe_dmemstore = mwif.alu_result;
          else
            deif.safe_alu_in2 = mwif.alu_result;
        end
      end else begin
        if (wb_rs_match)
          deif.safe_alu_in1 = mwif.instr_npc;
        if (wb_rt_match) begin
          if (deif.dmemWEN)
            deif.safe_dmemstore = mwif.instr_npc;
          else
            deif.safe_alu_in2 = mwif.instr_npc;
        end
      end
    end
  end
endmodule
