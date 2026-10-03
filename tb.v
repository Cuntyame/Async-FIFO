module testbench;
    // Inputs to DUT (Testbench drives these, so they are reg)
    reg [15:0] data_in;
    reg        w_en;
    reg        wclk;
    // reg        [3:0]wptr;
    
    reg        r_en;
    reg        rclk;
    // reg        [3:0]rptr;
    reg        wrst_n;
    reg        rrst_n;
    // Outputs from DUT (DUT drives these, so they are wire)
    wire [15:0] data_out;
    wire        full;
    wire        empty;
    // Instantiate the Top-Level Wrapper, NOT just the RAM
    async_fifo DUT (
        .rrst_n (rrst_n),
        .wrst_n (wrst_n),
        .wclk     (wclk),
        // .wptr   (wptr),
        .w_en     (w_en),
        .data_in  (data_in),
        .full     (full),        
        .rclk     (rclk),
        // .rptr   (rptr),
        .r_en     (r_en),
        .data_out (data_out),
        .empty    (empty)
    );
    initial wclk=0;
    always #5 wclk=~wclk;
    initial rclk=0;
    always #23 rclk=~rclk;
    initial begin
    //   $monitor($time ," data_in=%b ,w_en=%b ,full=%b ,r_en=%b ,empty=%b , data_out=%b",data_in,w_en,full,r_en,empty,data_out);
      $monitor($time, " wptr=%b rptr=%b | w_en=%b data_in=%h | r_en=%b empty=%b data_out=%h", 
         DUT.wptr, DUT.rptr, w_en, data_in, r_en, empty, data_out);
      r_en=0; w_en=0;
      wrst_n=0; rrst_n=0;
      
      #20; 
      wrst_n=1; rrst_n=1;
      #20;
      
      @(posedge wclk);
      w_en=1;
      data_in=1234;
      
      @(posedge wclk);
      w_en=0;

      #50;
 
      @(posedge rclk);
      r_en=1;
      
      @(posedge rclk);
      r_en=0;

      #50;
      $finish;
    end//   #5 wrst_n=1;rrst_n=1;
    //   #5 wrst_n=1;rrst_n=1;
    //   #5 w_en=1;
    //   #5 data_in=1244;r_en=1;
    //   #5 w_en=0;
    //   #5 w_en=1;
    //   #5 data_in=1254;r_en=1;
    //   #5 w_en=0;
    //   #5 w_en=1;
    //   #5 data_in=1274;r_en=1;
    //   #5 w_en=0;
    //   #5 w_en=1;
    //   #5 data_in=1284;r_en=1;
    //   #5 w_en=0;
    //   #5 w_en=1;
    //   #5 data_in=1294;r_en=1;
    //   #5 w_en=0;
    //   #5 w_en=1;
    //   #5 data_in=1204;r_en=1;
    //   #5 w_en=0;
    // end
      
    //   #5 w_en=1;data_in=2345;w_en=0;r_en=1;
    //   #5 w_en=1;data_in=3456;w_en=0;r_en=1;
    //   #5 w_en=1;data_in=4567;w_en=0;r_en=1;
    //   #5 w_en=1;data_in=5678;w_en=0;r_en=1;
    //   #5 w_en=1;data_in=6789;w_en=0;r_en=1;
    //   #5 w_en=1;data_in=7890;w_en=0;r_en=1;
    //   #5 w_en=1;data_in=8901;w_en=0;r_en=1;
    //   #5 w_en=1;data_in=9012;w_en=0;r_en=1;
    //   #5 w_en=1;data_in=0123;w_en=0;r_en=1;
endmodule