`include "cpu_types_pkg.vh"

import cpu_types_pkg::*;

module alu (
  input aluop_t aluop,
  input word_t port_a,
  input word_t port_b,
  output logic negative,
  output logic overflow,
  output logic zero,
  output word_t result
);

logic [30:0] unused;
logic carry_in;
logic carry_out;

always_comb
begin
  carry_in = 0;
  carry_out = 0;
  casez(aluop)
    ALU_SLL: result = port_a << port_b;
    ALU_SRL: result = port_a >> port_b;
    ALU_ADD: begin
      {carry_in,  unused} = port_a[30:0] + port_b[30:0];
      {carry_out, result} = port_a + port_b;
    end
    ALU_SUB: begin
      {carry_in,  unused} = port_a[30:0] - port_b[30:0];
      {carry_out, result} = port_a - port_b;
    end
    ALU_AND: result = port_a & port_b;
    ALU_OR:  result = port_a | port_b;
    ALU_XOR: result = port_a ^ port_b;
    ALU_NOR: result = ~(port_a | port_b);
    ALU_SLT: result = $signed(port_a) < $signed(port_b);
    ALU_SLTU: result = $unsigned(port_a) < $unsigned(port_b);
    default: result = 0;
  endcase
  negative = result[31];
  overflow = carry_out ^ carry_in;
  zero = result == 0;
end
endmodule
