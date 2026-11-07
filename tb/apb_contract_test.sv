`timescale 1ns/1ps
// Scalar APB driver with a four-word reference memory independent of the DUT.
module apb_contract_test;
  logic PCLK=0, PRESETn=0;
  always #5 PCLK=~PCLK;
  apb_if bus(PCLK,PRESETn);
  apb_slave_ram dut(bus);

  logic [31:0] expected_mem[0:3];
  int checks=0, probes=0, guards=0, resets=0, errors=0;
  int unsigned rng=32'h28ab4b05;

  function automatic bit valid_address(input int unsigned a);
    return a<=12 && (a & 3)==0;
  endfunction
  function automatic logic [31:0] next_word();
    rng ^= rng << 13;
    rng ^= rng >> 17;
    rng ^= rng << 5;
    return rng;
  endfunction
  task automatic check_value(input logic [31:0] observed,input logic [31:0] wanted,
                        input string label,input int unsigned address);
    if(observed !== wanted)
      $fatal(1,"APB_CONTRACT_MISMATCH %s addr=%02h wanted=%08h observed=%08h",
             label,address,wanted,observed);
    checks++;
  endtask
  task automatic clear_reference;
    for(int i=0;i<4;i++) expected_mem[i]=0;
  endtask
  task automatic idle;
    bus.PSEL=0; bus.PENABLE=0; bus.PWRITE=0;
    bus.PADDR=0; bus.PWDATA=0;
  endtask

  task automatic transfer(input int unsigned address,input bit write_enable,
                          input logic [31:0] value,input bit is_probe);
    bit legal;
    logic [31:0] expected_read;
    legal=valid_address(address);
    expected_read=(legal && !write_enable) ? expected_mem[address>>2] : 0;
    @(negedge PCLK);
    bus.PADDR=address[7:0]; bus.PWRITE=write_enable; bus.PWDATA=value;
    bus.PSEL=1; bus.PENABLE=0;
    #1;
    check_value({31'b0,bus.PREADY},0,"setup ready",address);
    check_value({31'b0,bus.PSLVERR},0,"setup error",address);
    check_value(bus.PRDATA,0,"setup read data",address);
    @(negedge PCLK);
    bus.PENABLE=1;
    #1;
    check_value({31'b0,bus.PREADY},1,"access ready",address);
    check_value({31'b0,bus.PSLVERR},legal ? 0 : 1,"access error",address);
    check_value(bus.PRDATA,expected_read,"access read data",address);
    @(posedge PCLK);
    if(legal && write_enable) expected_mem[address>>2]=value;
    if(!legal) errors++;
    @(negedge PCLK);
    idle();
    #1;
    check_value({31'b0,bus.PREADY},0,"idle ready",address);
    check_value({31'b0,bus.PSLVERR},0,"idle error",address);
    if(is_probe) probes++; else guards++;
  endtask

  task automatic guard_words(input string label);
    for(int i=0;i<4;i++) transfer(i*4,0,0,0);
  endtask

  initial begin
    idle(); clear_reference();
    repeat(3) @(posedge PCLK);
    @(negedge PCLK); PRESETn=1;
    guard_words("initial reset");
    for(int i=0;i<4;i++) transfer(i*4,1,32'hA5000000 ^ (i*32'h00112233),0);
    guard_words("all words filled");
    transfer(8'h10,1,32'hDEADBEEF,0);
    transfer(8'h01,1,32'hBADC0FFE,0);
    guard_words("boundary and misalignment suppression");

    // Exactly 256 addresses in both directions; guard every write by reading all words.
    for(int a=0;a<256;a++) begin
      transfer(a,0,0,1);
      transfer(a,1,next_word(),1);
      guard_words("post-write isolation");
    end
    transfer(8'hff,0,0,0);
    transfer(8'h0c,1,32'h11223344,0);
    transfer(8'h0c,0,0,0);

    // Reset asserted during an ACCESS write before its accepting rising edge.
    @(negedge PCLK);
    bus.PADDR=8'h00; bus.PWDATA=32'hFEE1DEAD; bus.PWRITE=1;
    bus.PSEL=1; bus.PENABLE=0;
    @(negedge PCLK); bus.PENABLE=1;
    #2; PRESETn=0; clear_reference(); resets++;
    repeat(2) @(posedge PCLK);
    @(negedge PCLK); idle(); PRESETn=1;
    guard_words("reset canceled pending write");

    if(probes != 512) $fatal(1,"APB_PROBE_COUNT wanted=512 observed=%0d",probes);
    $display("APB_MODPORT_CONTRACT_PASS probes=%0d guards=%0d checks=%0d errors=%0d resets=%0d seed=0x28AB4B05",
             probes,guards,checks,errors,resets);
    $finish;
  end
  initial begin #5000000; $fatal(1,"APB_CONTRACT_TIMEOUT"); end
endmodule
