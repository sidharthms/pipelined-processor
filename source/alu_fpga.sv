`include "cpu_types_pkg.vh"

module alu_fpga (
  input logic CLOCK_50,
  input logic [3:0] KEY,
  input logic [17:0] SW,
  output logic [17:0] LEDR,
  output logic [7:0] LEDG,
  output logic [6:0] HEX0,
  output logic [6:0] HEX1,
  output logic [6:0] HEX2,
  output logic [6:0] HEX3,
  output logic [6:0] HEX4,
  output logic [6:0] HEX5,
  output logic [6:0] HEX6,
  output logic [6:0] HEX7
);

  logic [6:0] HEX [7:0];
  assign HEX0 = HEX[0];
  assign HEX1 = HEX[1];
  assign HEX2 = HEX[2];
  assign HEX3 = HEX[3];
  assign HEX4 = HEX[4];
  assign HEX5 = HEX[5];
  assign HEX6 = HEX[6];
  assign HEX7 = HEX[7];

  word_t port_a;
  word_t port_b;
  word_t result;

  alu ALU(
    .aluop(aluop_t'(~KEY)),
    .port_a,
    .port_b,
    .negative(LEDR[0]),
    .overflow(LEDR[1]),
    .zero(LEDR[2]),
    .result);

  always_ff @(posedge CLOCK_50)
  begin
    if (~KEY[0])
    begin
      unique case (SW[17:16])
        0: port_a[15:0] = SW[15:0];
        1: port_a[31:16] = SW[15:0];
        2: port_b[15:0] = SW[15:0];
        3: port_b[31:16] = SW[15:0];
      endcase
    end
  end

  always_comb
  begin
    for (int i = 0; i < 8; i+=1)
    begin
      unique casez (result[i*4+:4])
        'h0: HEX[i] = 7'b1000000;
        'h1: HEX[i] = 7'b1111001;
        'h2: HEX[i] = 7'b0100100;
        'h3: HEX[i] = 7'b0110000;
        'h4: HEX[i] = 7'b0011001;
        'h5: HEX[i] = 7'b0010010;
        'h6: HEX[i] = 7'b0000010;
        'h7: HEX[i] = 7'b1111000;
        'h8: HEX[i] = 7'b0000000;
        'h9: HEX[i] = 7'b0010000;
        'ha: HEX[i] = 7'b0001000;
        'hb: HEX[i] = 7'b0000011;
        'hc: HEX[i] = 7'b0100111;
        'hd: HEX[i] = 7'b0100001;
        'he: HEX[i] = 7'b0000110;
        'hf: HEX[i] = 7'b0001110;
        default: HEX[i] = 7'b1000000;
      endcase
    end
  end
endmodule
