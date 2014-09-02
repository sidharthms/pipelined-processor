`include "cpu_types_pkg.vh"

// mapped timing needs this. 1ns is too fast
`timescale 1 ns / 1 ns

module alu_tb;
  import cpu_types_pkg::*;

  parameter PERIOD = 1;

  logic clk = 0;
  logic n_rst;
  aluop_t aluop;
  word_t port_a;
  word_t port_b;
  logic negative;
  logic overflow;
  logic zero;
  word_t result;

  word_t computed_result;

  logic all_passed = 1;

  static int unsigned test_data[6] = '{ 32'd29, 32'd678978, 32'd1672548245,
    32'd1875421645, 32'd2861325642, 32'd4200100100 };

  alu DUT(
    .aluop,
    .port_a,
    .port_b,
    .negative,
    .overflow,
    .zero,
    .result);

  initial
  begin : TEST_PROC
    // --------------------------- ALU_SLL
    // Test SLL
    for (int i = 0; i < 6; i+=1)
    begin
      port_a = test_data[i];
      port_b = i;
      aluop = ALU_SLL;
      #(PERIOD);
      computed_result = test_data[i] << i;
      assert(result == computed_result)
      else
        $display("Error: incorrect result for opcode %d", aluop,
                 "in test case %d", i);
      assert(overflow == 0)
      else
        $display("Error: incorrect overflow flag for opcode %d", aluop,
                 "in test case %d", i);
    end

    // --------------------------- ALU_SRL
    // Test SRL
    for (int i = 0; i < 6; i+=1)
    begin
      port_a = test_data[i];
      port_b = i;
      aluop = ALU_SRL;
      #(PERIOD);
      computed_result = test_data[i] >> i;
      assert(result == computed_result)
      else
        $display("Error: incorrect result for opcode %d", aluop,
                 "in test case %d", i);
      assert(overflow == 0)
      else
        $display("Error: incorrect overflow flag for opcode %d", aluop,
                 "in test case %d", i);
    end

    // --------------------------- ALU_ADD
    // Test regular add.
    port_a = test_data[0];
    port_b = test_data[1];
    aluop = ALU_ADD;
    #(PERIOD);
    computed_result = test_data[0] + test_data[1];
    assert(result == computed_result)
    else
      $display("Error: incorrect result for opcode %d", aluop,
               "in test case 1");
    assert(negative == $signed(computed_result) < 0)
    else
      $display("Error: incorrect neg flag for opcode %d", aluop,
               "in test case 1");
    assert(zero == (computed_result == 0))
    else
      $display("Error: incorrect zero flag for opcode %d", aluop,
               "in test case 1");
    assert(overflow == 0)
    else
      $display("Error: incorrect overflow flag for opcode %d", aluop,
               "in test case 1");

    // Test add with neg number case 1.
    port_a = test_data[0];
    port_b = -test_data[1];
    aluop = ALU_ADD;
    #(PERIOD);
    computed_result = test_data[0] - test_data[1];
    assert(result == computed_result)
    else
      $display("Error: incorrect result for opcode %d", aluop,
               "in test case 2");
    assert(negative == $signed(computed_result) < 0)
    else
      $display("Error: incorrect neg flag for opcode %d", aluop,
               "in test case 2");
    assert(zero == (computed_result == 0))
    else
      $display("Error: incorrect zero flag for opcode %d", aluop,
               "in test case 2");
    assert(overflow == 0)
    else
      $display("Error: incorrect overflow flag for opcode %d", aluop,
               "in test case 2");

    // Test add with neg number case 2.
    port_a = -test_data[0];
    port_b = test_data[1];
    aluop = ALU_ADD;
    #(PERIOD);
    computed_result = - test_data[0] + test_data[1];
    assert(result == computed_result)
    else
      $display("Error: incorrect result for opcode %d", aluop,
               "in test case 3");
    assert(negative == $signed(computed_result) < 0)
    else
      $display("Error: incorrect neg flag for opcode %d", aluop,
               "in test case 3");
    assert(zero == (computed_result == 0))
    else
      $display("Error: incorrect zero flag for opcode %d", aluop,
               "in test case 3");
    assert(overflow == 0)
    else
      $display("Error: incorrect overflow flag for opcode %d", aluop,
               "in test case 3");

    // Test add with overflow case 1.
    port_a = test_data[2];
    port_b = test_data[3];
    aluop = ALU_ADD;
    #(PERIOD);
    computed_result = test_data[2] + test_data[3];
    assert(result == computed_result)
    else
      $display("Error: incorrect result for opcode %d", aluop,
               "in test case 4");
    assert(negative == $signed(computed_result) < 0)
    else
      $display("Error: incorrect neg flag for opcode %d", aluop,
               "in test case 4");
    assert(zero == (computed_result == 0))
    else
      $display("Error: incorrect zero flag for opcode %d", aluop,
               "in test case 4");
    assert(overflow == 1)
    else
      $display("Error: incorrect overflow flag for opcode %d", aluop,
               "in test case 4");

    // Test add with overflow case 2.
    port_a = -test_data[2];
    port_b = -test_data[3];
    aluop = ALU_ADD;
    #(PERIOD);
    computed_result = - test_data[2] - test_data[3];
    assert(result == computed_result)
    else
      $display("Error: incorrect result for opcode %d", aluop,
               "in test case 5");
    assert(negative == $signed(computed_result) < 0)
    else
      $display("Error: incorrect neg flag for opcode %d", aluop,
               "in test case 5");
    assert(zero == (computed_result == 0))
    else
      $display("Error: incorrect zero flag for opcode %d", aluop,
               "in test case 5");
    assert(overflow == 1)
    else
      $display("Error: incorrect overflow flag for opcode %d", aluop,
               "in test case 5");

    // Test add with zero result.
    port_a = test_data[2];
    port_b = -test_data[2];
    aluop = ALU_ADD;
    #(PERIOD);
    computed_result = 0;
    assert(result == computed_result)
    else
      $display("Error: incorrect result for opcode %d", aluop,
               "in test case 6");
    assert(negative == $signed(computed_result) < 0)
    else
      $display("Error: incorrect neg flag for opcode %d", aluop,
               "in test case 6");
    assert(zero == (computed_result == 0))
    else
      $display("Error: incorrect zero flag for opcode %d", aluop,
               "in test case 6");
    assert(overflow == 0)
    else
      $display("Error: incorrect overflow flag for opcode %d", aluop,
               "in test case 6");

    // --------------------------- ALU_SUB
    // Test regular sub.
    port_a = test_data[0];
    port_b = test_data[1];
    aluop = ALU_SUB;
    #(PERIOD);
    computed_result = test_data[0] - test_data[1];
    assert(result == computed_result)
    else
      $display("Error: incorrect result for opcode %d", aluop,
               "in test case 1");
    assert(negative == $signed(computed_result) < 0)
    else
      $display("Error: incorrect neg flag for opcode %d", aluop,
               "in test case 1");
    assert(zero == (computed_result == 0))
    else
      $display("Error: incorrect zero flag for opcode %d", aluop,
               "in test case 1");
    assert(overflow == 0)
    else
      $display("Error: incorrect overflow flag for opcode %d", aluop,
               "in test case 1");

    // Test sub with neg number case 1.
    port_a = test_data[0];
    port_b = -test_data[1];
    aluop = ALU_SUB;
    #(PERIOD);
    computed_result = test_data[0] + test_data[1];
    assert(result == computed_result)
    else
      $display("Error: incorrect result for opcode %d", aluop,
               "in test case 2");
    assert(negative == $signed(computed_result) < 0)
    else
      $display("Error: incorrect neg flag for opcode %d", aluop,
               "in test case 2");
    assert(zero == (computed_result == 0))
    else
      $display("Error: incorrect zero flag for opcode %d", aluop,
               "in test case 2");
    assert(overflow == 0)
    else
      $display("Error: incorrect overflow flag for opcode %d", aluop,
               "in test case 2");

    // Test sub with neg number case 2.
    port_a = -test_data[0];
    port_b = test_data[1];
    aluop = ALU_SUB;
    #(PERIOD);
    computed_result = - test_data[0] - test_data[1];
    assert(result == computed_result)
    else
      $display("Error: incorrect result for opcode %d", aluop,
               "in test case 3");
    assert(negative == $signed(computed_result) < 0)
    else
      $display("Error: incorrect neg flag for opcode %d", aluop,
               "in test case 3");
    assert(zero == (computed_result == 0))
    else
      $display("Error: incorrect zero flag for opcode %d", aluop,
               "in test case 3");
    assert(overflow == 0)
    else
      $display("Error: incorrect overflow flag for opcode %d", aluop,
               "in test case 3");

    // Test sub with overflow case 1.
    port_a = test_data[2];
    port_b = -test_data[3];
    aluop = ALU_SUB;
    #(PERIOD);
    computed_result = test_data[2] + test_data[3];
    assert(result == computed_result)
    else
      $display("Error: incorrect result for opcode %d", aluop,
               "in test case 4");
    assert(negative == $signed(computed_result) < 0)
    else
      $display("Error: incorrect neg flag for opcode %d", aluop,
               "in test case 4");
    assert(zero == (computed_result == 0))
    else
      $display("Error: incorrect zero flag for opcode %d", aluop,
               "in test case 4");
    assert(overflow == 1)
    else
      $display("Error: incorrect overflow flag for opcode %d", aluop,
               "in test case 4");

    // Test add with overflow case 2.
    port_a = -test_data[2];
    port_b = test_data[3];
    aluop = ALU_SUB;
    #(PERIOD);
    computed_result = - test_data[2] - test_data[3];
    assert(result == computed_result)
    else
      $display("Error: incorrect result for opcode %d", aluop,
               "in test case 5");
    assert(negative == $signed(computed_result) < 0)
    else
      $display("Error: incorrect neg flag for opcode %d", aluop,
               "in test case 5");
    assert(zero == (computed_result == 0))
    else
      $display("Error: incorrect zero flag for opcode %d", aluop,
               "in test case 5");
    assert(overflow == 1)
    else
      $display("Error: incorrect overflow flag for opcode %d", aluop,
               "in test case 5");

    // Test add with zero result.
    port_a = test_data[2];
    port_b = test_data[2];
    aluop = ALU_SUB;
    #(PERIOD);
    computed_result = 0;
    assert(result == computed_result)
    else
      $display("Error: incorrect result for opcode %d", aluop,
               "in test case 6");
    assert(negative == $signed(computed_result) < 0)
    else
      $display("Error: incorrect neg flag for opcode %d", aluop,
               "in test case 6");
    assert(zero == (computed_result == 0))
    else
      $display("Error: incorrect zero flag for opcode %d", aluop,
               "in test case 6");
    assert(overflow == 0)
    else
      $display("Error: incorrect overflow flag for opcode %d", aluop,
               "in test case 6");

    // --------------------------- ALU_AND
    for (int i = 0; i < 6; i+=1)
      for (int j = 0; j < 6; j+=1)
      begin
        port_a = test_data[i];
        port_b = test_data[j];
        aluop = ALU_AND;
        #(PERIOD);
        computed_result = port_a & port_b;
        assert(result == computed_result)
        else
          $display("Error: incorrect result for opcode %d", aluop,
                   "in test case %d", i);
        assert(overflow == 0)
        else
          $display("Error: incorrect overflow flag for opcode %d", aluop,
                   "in test case %d", i);
      end

    // --------------------------- ALU_OR
    for (int i = 0; i < 6; i+=1)
      for (int j = 0; j < 6; j+=1)
      begin
        port_a = test_data[i];
        port_b = test_data[j];
        aluop = ALU_OR;
        #(PERIOD);
        computed_result = port_a | port_b;
        assert(result == computed_result)
        else
          $display("Error: incorrect result for opcode %d", aluop,
                   "in test case %d", i);
        assert(overflow == 0)
        else
          $display("Error: incorrect overflow flag for opcode %d", aluop,
                   "in test case %d", i);
      end

    // --------------------------- ALU_XOR
    for (int i = 0; i < 6; i+=1)
      for (int j = 0; j < 6; j+=1)
      begin
        port_a = test_data[i];
        port_b = test_data[j];
        aluop = ALU_XOR;
        #(PERIOD);
        computed_result = port_a ^ port_b;
        assert(result == computed_result)
        else
          $display("Error: incorrect result for opcode %d", aluop,
                   "in test case %d", i);
        assert(overflow == 0)
        else
          $display("Error: incorrect overflow flag for opcode %d", aluop,
                   "in test case %d", i);
      end

    // --------------------------- ALU_NOR
    for (int i = 0; i < 6; i+=1)
      for (int j = 0; j < 6; j+=1)
      begin
        port_a = test_data[i];
        port_b = test_data[j];
        aluop = ALU_NOR;
        #(PERIOD);
        computed_result = ~(port_a | port_b);
        assert(result == computed_result)
        else
          $display("Error: incorrect result for opcode %d", aluop,
                   "in test case %d", i);
        assert(overflow == 0)
        else
          $display("Error: incorrect overflow flag for opcode %d", aluop,
                   "in test case %d", i);
      end

    // --------------------------- ALU_SLT
    for (int i = 0; i < 6; i+=1)
      for (int j = 0; j < 6; j+=1)
      begin
        port_a = test_data[i];
        port_b = test_data[j];
        aluop = ALU_SLT;
        #(PERIOD);
        computed_result = $signed(test_data[i]) < $signed(test_data[j]);
        assert(result == computed_result)
        else
          $display("Error: incorrect result for opcode %d", aluop,
                   "in test case %d", i);
        assert(overflow == 0)
        else
          $display("Error: incorrect overflow flag for opcode %d", aluop,
                   "in test case %d", i);
      end

    // --------------------------- ALU_SLTU
    for (int i = 0; i < 6; i+=1)
      for (int j = 0; j < 6; j+=1)
      begin
        port_a = test_data[i];
        port_b = test_data[j];
        aluop = ALU_SLTU;
        #(PERIOD);
        computed_result = test_data[i] < test_data[j];
        assert(result == computed_result)
        else
          $display("Error: incorrect result for opcode %d", aluop,
                   "in test case %d", i);
        assert(overflow == 0)
        else
          $display("Error: incorrect overflow flag for opcode %d", aluop,
                   "in test case %d", i);
      end
    $finish;
  end
endmodule
