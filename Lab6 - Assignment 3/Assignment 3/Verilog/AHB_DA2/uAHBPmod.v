
module AHBPmod(
  input wire HCLK,
  input wire HRESETn,
  input wire [31:0] HADDR,
  input wire [1:0] HTRANS,
  input wire [31:0] HWDATA,
  input wire HWRITE,
  input wire HSEL,
  input wire HREADY,
  
  output wire Sync,                     //Sync (Select Pin) Output
  output wire ChannelA,                     //Data in Channel A
  output wire ChannelB,                     //Data in Channel B
  output wire HREADYOUT,
  output wire [31:0] HRDATA,
  output wire SCLK
);
  reg [31:0] last_HADDR;
  reg [1:0] last_HTRANS;
  reg last_HWRITE;
  reg last_HSEL;
  reg [4:0] Counter;
  wire Prescale;
  
  AHBPmodPrescaler uAHBPmodPrescaler(
    .inCLK(HCLK),
    .outCLK(Prescale)
  );
  
  assign SCLK = Prescale;
 

  reg [11:0]  Wave;                       //Wave register (12-bit) holds the current
  reg [4:0] Count;                        //Count register (5-bit) counts number of clock cycles since the last output update, set to 5'b0.
  

  reg RegSync;                               //Sync register (1-bit) pulses the da2_CS output whenever a new output value is available set to 1'b1 (high output)
 
  reg RegChannelA;                          //Channel A register (1-bit) outputs the current bit of the Wave register, set to 1'b1.  
 
  reg RegChannelB;                          //Channel B register (1-bit) represents the DA2_DINB input signal
  
  
  assign HREADYOUT = 1'b1;
  
  // data phase
  // read bus
  // using read bus signals, write new smaple
always @(posedge SCLK)
  begin
    if(last_HWRITE & last_HSEL & last_HTRANS[1])
    begin
      Wave <= HWDATA;
    end
  end
  
  // Set Registers from address phase  
  always @(posedge SCLK)
  begin
    if(HREADY)
    begin
      last_HADDR <= HADDR;
      last_HTRANS <= HTRANS;
      last_HWRITE <= HWRITE;
      last_HSEL <= HSEL;
    end
  end
  
//Always block specifies behavior of module on each positive edge of the "HCLK" input.
  always @(posedge SCLK) begin
  if (Counter == 5'b00000)
    RegSync = 1'b0;
  case(Counter)
    5'b00000: RegChannelA <= 1'b0;
    5'b00001: RegChannelA <= 1'b0;
    5'b00010: RegChannelA <= 1'b0;
    5'b00011: RegChannelA <= 1'b0;
    5'b00100: RegChannelA <= Wave[11];
    5'b00101: RegChannelA <= Wave[10];
    5'b00110: RegChannelA <= Wave[9];
    5'b00111: RegChannelA <= Wave[8];
    5'b01000: RegChannelA <= Wave[7];
    5'b01001: RegChannelA <= Wave[6];
    5'b01010: RegChannelA <= Wave[5];
    5'b01011: RegChannelA <= Wave[4];
    5'b01100: RegChannelA <= Wave[3];
    5'b01101: RegChannelA <= Wave[2];
    5'b01110: RegChannelA <= Wave[1];
    5'b01111: RegChannelA <= Wave[0];
   endcase

    if (Counter == 5'b10000) begin
    RegSync = 1'b1;
    Counter = 5'b00000;
	end
	else
	begin
	      Counter = Counter + 1;
	end
   // set wave ot whatever is new on the bus
   //Wave <= NextWave;
  end
  

  assign Sync = RegSync;    //Assigns values of Sync to output wire
  assign ChannelA = RegChannelA;    //Assigns values of Channel A to output wire
  assign ChannelB = RegChannelB;    //Assigns values of Channel B to output wire
  
endmodule