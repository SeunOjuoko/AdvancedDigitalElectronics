module AHBPmodPrescaler(
  input wire inCLK,
  output wire outCLK
    );

reg counter;

always @(posedge inCLK)
  counter <= counter + 1'b1;
  
assign outCLK = counter == 1'b1;

endmodule
