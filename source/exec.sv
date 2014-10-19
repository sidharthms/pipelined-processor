`include "decode_exec_if.vh"
`include "exec_mem_if.vh"

import cpu_types_pkg::*;

module exec (
  input logic CLK, nRST,
  input logic en, zero,
  output logic alu_zero,
  output word_t alu_result,
  decode_exec_if.exec in,
  exec_mem_if.exec out
);
  // ALU signals
  aluop_t alu_aluop;
  word_t  alu_port_a;
  word_t  alu_port_b;
  logic   alu_negative;
  logic   alu_overflow;

  alu alu_module(
    .aluop(alu_aluop),
    .port_a(alu_port_a),
    .port_b(alu_port_b),
    .negative(alu_negative),
    .overflow(alu_overflow),
    .zero(alu_zero),
    .result(alu_result));

  always_ff @ (posedge CLK, negedge nRST)
  begin
    if(!nRST) begin
      out.dmemWEN      <= 0;
      out.dmemREN      <= 0;
      out.halt         <= 0;
      out.alu_result   <= 0;
      out.wsel         <= 0;
      out.wdat_source  <= write_t'(0);
      out.instr_npc    <= 0;
      out.dmemstore    <= 0;
    end else if (en && zero) begin
      out.dmemWEN      <= 0;
      out.dmemREN      <= 0;
      out.halt         <= 0;
      out.alu_result   <= 0;
      out.wsel         <= 0;
      out.wdat_source  <= write_t'(0);
      out.instr_npc    <= 0;
      out.dmemstore    <= 0;
    end else if (en && !zero) begin
      out.dmemWEN      <= in.dmemWEN;
      out.dmemREN      <= in.dmemREN;
      out.halt         <= in.halt;
      out.alu_result   <= alu_result;
      out.wsel         <= in.wsel;
      out.wdat_source  <= in.wdat_source;
      out.instr_npc    <= in.instr_npc;
      out.dmemstore    <= in.safe_dmemstore;
    end
  end

  always_comb begin
    alu_aluop  = in.alu_aluop;
    alu_port_a = in.safe_alu_in1;
    alu_port_b = in.safe_alu_in2;
  end
endmodule
