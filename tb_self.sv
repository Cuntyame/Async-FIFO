module test;
    reg        wclk;
    reg        w_en;
    reg [15:0] data_in;
    reg        wrst_n;
    wire        full;

    reg        rclk;
    reg        rrst_n;
    reg        r_en;
    wire [15:0] data_out;
    wire        empty;
    async_fifo DUT(
        .wclk(wclk),
        .wrst_n(wrst_n),
        .w_en(w_en),
        .data_in(data_in),
        .full(full),

        .rclk(rclk),
        .rrst_n(rrst_n),
        .r_en(r_en),
        .data_out(data_out),
        .empty(empty)
    );
  initial begin
    $dumpfile("dump.vcd");
    $dumpvars(0,test);
  end
    initial wclk=0;
    always begin
        #13 wclk=~wclk;
    end
    initial rclk=0;
    always begin
        #5 rclk=~rclk;
    end
  logic [15:0] data;
  logic [15:0] q[$];
  logic [15:0] ans;
  logic [3:0] num;
  bit f;
  bit e;
  bit wen;
  bit ren;
  bit empt;
  property full_pro;
    @(posedge wclk)
      full && w_en|=>$stable(wptr);
  endproperty
// 	integer data=1111;
  task read_data(output [15:0] ext);
        // e=0;
        e=1;
//         if(q.size()==0)begin
//           e=0;
//           return;
//         end
    	 wait(q.size() != 0);  
        wait(!empty);
        @(posedge rclk);
        #1 r_en<=1;
        @(posedge rclk);
        if(!empty)begin
          ans=q.pop_front();
          // num=num-1;
        end
        #1 r_en<=0;
        ext=data_out;
        // return ans;
    endtask
  task automatic write_data(input [15:0] d_in);
        @(posedge wclk);
        #1 w_en<=1;
        data_in<=d_in;
        @(posedge wclk);
        if(!full)begin
          q.push_back(d_in);
          // num=num+1;
        end
        // if(!full)f=0;
        // else f=1;
        #1 w_en<=0;    
  endtask
  task rst();
    wrst_n=0;
    rrst_n=0;
    repeat(3) @(posedge rclk);
    wrst_n=1;
    rrst_n=1;
    num=0;
  endtask
    initial begin
        $monitor("%0t --> %0h : data_in, %0h : data_out ",$time,data_in,data_out);
        wrst_n=0;
      	data=16'h1111;
        rrst_n=0;
        r_en=0;
        empt=0;
        rst();
      fork
      repeat(17)begin
        wen=$urandom();
          if(wen)begin
            // if(!full)q.push_back(data);
            write_data(data);
            data=data+1111;
          end
      end
        repeat(58)begin
        ren=$urandom();
          if(ren)begin
          // if(!empty)empt=0;
          // else empt=1;
          read_data(ans);
          if(e==1 && data_out!=ans)$display("failed");
        end
      end
      join
      // @(posedge rclk);
      // #1 r_en=1;
      // @(posedge rclk);
      // #1 r_en=0;
      //   #10 wrst_n=1;rrst_n=1;
//         r_en=0;
//         rst();
        
//         write_data(data);
//         read_data();
//       read_data();
//     //   for (int i = 0;i<4 ;i=i+1 ) begin
//     //         @(posedge wclk);
//     //   #1
//     //         w_en<=1;data_in<=data;
//     //         @(posedge wclk);
//     //         #1 w_en<=0;
//     //         data<=data+1111;
// //         end
//         // while  (empty==0) begin
// //             @(posedge rclk);
// //       wrst_n=0;
// //       r_en<=1;
      
// //             @(posedge rclk);
// // //             #1 r_en<=0;
// //             @(posedge rclk);
// //             r_en<=1;
// //             @(posedge rclk);
// //             r_en<=1;
// //             @(posedge rclk);
// //             r_en<=1;
// //             @(posedge rclk);
// //             r_en<=1;
//             // @(posedge rclk);
//             // r_en<=0;
//         // end
//       @(posedge rclk);
//   $finish;
    // 0. Initialize all inputs safely to 0
    // w_en = 0;
    // r_en = 0;
    // data_in = 0;

    // $display("--- TEST 1: Reset at Startup ---");
    // rst();
    
    // $display("--- TEST 2: Clean Reset ---");
    // write_data(16'hAAAA);
    // read_data();
    // // The FIFO is now empty. Hit it with a reset.
    // rst();
    // // Prove it still works after a clean reset
    // write_data(16'hBBBB);
    // read_data();
    
    // $display("--- TEST 3: Mid-Flight Reset ---");
    // // Write two packets back-to-back, but DO NOT read them. 
    // write_data(16'h1111);
    // write_data(16'h2222);
    // // The FIFO and synchronizers are currently full of active data. 
    // // Hit it with a violent reset to see if it recovers safely.
    // rst();
    // // Write a final packet to prove the pointers cleared out the old 1111/2222 data.
    // write_data(16'h9999);
    // read_data();

    // Give the simulator a little time to finish the last waveform cycle
    #100;
    $finish;
    end
endmodule