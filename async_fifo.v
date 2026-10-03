module graytobin (
  input bit[4:0] gray,
  output bit[4:0] bin);
    assign bin[4] = gray[4];
    assign bin[3] = gray[3] ^ bin[4];
    assign bin[2] = gray[2] ^ bin[3];
    assign bin[1] = gray[1] ^ bin[2];
    assign bin[0] = gray[0] ^ bin[1];
endmodule

module bintogray (
  input bit[4:0] bin ,
  output bit[4:0] gray);
    assign gray=bin^bin>>1;
      // assign gray[0]=bin[0];
      // assign gray[1]=gray[0]^bin[1];
      // assign gray[2]=gray[1]^bin[2];
      // assign gray[3]=gray[2]^bin[3];
      // assign gray[4]=gray[3]^bin[4];
     
endmodule

module dff (
  input wire clk,
  input wire [4:0] d ,
  input wire rst,
  output reg [4:0] q);
  always @( negedge rst,posedge clk ) begin  
    if(!rst) q<=0;
    else q<=d;
  end
endmodule

module wrt_pt_hldr (
    input  wire       wrst_n,
    input  wire       w_en,
    input  wire [4:0] g_rptr,
    input  wire       wclk,
    output wire       full,      // Changed to wire (driven by assign)
    output wire [3:0] wptr,      // Changed to wire (driven by assign)
    output reg  [4:0] b_wptr,
    output wire [4:0] g_wptr     // Changed to wire (driven by bintogray module)
);
    wire [4:0] g_rptr_1, g_rptr_sync;
    always @(negedge wrst_n , posedge wclk ) begin
      if(!wrst_n)b_wptr<=5'b0;
      else if(!full && w_en)b_wptr <= b_wptr+1;
    end 
    dff dff1(wclk,g_rptr,wrst_n,g_rptr_1);
    dff dff2 (wclk,g_rptr_1,wrst_n,g_rptr_sync);
    bintogray bg (b_wptr,g_wptr);
    wire [4:0] b_rptr_sync;
    graytobin gb(g_rptr_sync,b_rptr_sync);
    assign wptr= b_wptr[3:0];   
    assign full = (b_wptr == {~b_rptr_sync[4], b_rptr_sync[3:0]}); 
endmodule

module rd_pt_hldr (
    input  wire       rrst_n,
    input  wire       r_en,
    input  wire [4:0] g_wptr,
    input  wire       rclk,
    output wire       empty,     // Changed to wire (driven by assign)
    output wire [3:0] rptr,      // Changed to wire (driven by assign)
    output wire [4:0] g_rptr,    // Replaced the duplicated g_wptr inout port
    output reg  [4:0] b_rptr     // Changed from inout to output reg
);
    always @(negedge rrst_n, posedge rclk) begin
      if(!rrst_n) b_rptr <= 5'b0;
      else if(!empty && r_en) b_rptr <= b_rptr + 1;
    end
    
    bintogray bg(b_rptr, g_rptr);
    wire [4:0] g_wptr_1, g_wptr_sync;
    
    dff dff1(rclk, g_wptr, rrst_n, g_wptr_1);
    dff dff2(rclk, g_wptr_1, rrst_n, g_wptr_sync);
    
    assign rptr = b_rptr[3:0]; // Fixed typo: r_ptr -> rptr
    assign empty = (g_rptr == g_wptr_sync);
endmodule

module fifo(
  input wire wrst_n,
  input wire rrst_n,
  input wire [15:0] data_in,
  input wire w_en,
  input wire wclk,
  input wire full,
  input [3:0]wptr,
  input wire r_en,
  input wire rclk,
  input wire empty,
  input wire [3:0]rptr,
  output reg [15:0] data_out
  );
  reg [15:0] arr [15:0] ;
  always@( posedge wclk)begin
    if(!full && w_en )arr[wptr]<=data_in;
  end
  always @(posedge rclk) begin
    if(!empty && r_en )data_out <= arr[rptr];
  end
endmodule

module async_fifo (
    // These are the external ports the testbench talks to
    input  wire        wclk,
    input  wire        wrst_n,
    input  wire        w_en,
    input  wire [15:0] data_in,
    output wire        full,

    input  wire        rclk,
    input  wire        rrst_n,
    input  wire        r_en,
    output wire [15:0] data_out,
    output wire        empty
);

    // Internal routing wires to connect the blocks together
    wire [3:0] wptr;
    wire [3:0] rptr;
    wire [4:0] g_wptr;
    wire [4:0] g_rptr;

    // Instantiate Write Handler
    wrt_pt_hldr u_wrt_handler (
        .wclk   (wclk),
        .wrst_n (wrst_n),
        .w_en   (w_en),
        .g_rptr (g_rptr), // Receiving Gray read pointer from Read domain
        .full   (full),
        .wptr   (wptr),
        .b_wptr (),       // Leave unconnected
        .g_wptr (g_wptr)  // Broadcasting Gray write pointer to Read domain
    );

    // Instantiate Read Handler
    rd_pt_hldr u_rd_handler (
        .rclk   (rclk),
        .rrst_n (rrst_n),
        .r_en   (r_en),
        .g_wptr (g_wptr), // Receiving Gray write pointer from Write domain
        .empty  (empty),
        .rptr   (rptr),
        .g_rptr (g_rptr), // Broadcasting Gray read pointer to Write domain
        .b_rptr ()        // Leave unconnected
    );

    // Instantiate Dual-Port RAM (your 'fifo' module)
    fifo u_memory (
        .wrst_n   (wrst_n),
        .rrst_n   (rrst_n),
        .wclk     (wclk),
        .w_en     (w_en),
        .wptr     (wptr),
        .data_in  (data_in),
        .full     (full),
        
        .rclk     (rclk),
        .r_en     (r_en),
        .rptr     (rptr),
        .data_out (data_out),
        .empty    (empty)
    );

endmodule