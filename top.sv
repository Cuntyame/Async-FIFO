interface fifo_if (input logic wclk, input logic rclk);
    
    // Declare your resets (wrst_n, rrst_n)
    logic rrst_n;
    logic wrst_n;

    // Declare your write domain signals (w_en, data_in, full)
    logic w_en;
    logic full;
    logic r_en;
    logic empty;
    logic [15:0] data_in;
    logic [15:0] data_out;
    // Declare your read domain signals (r_en, data_out, empty)
endinterface

module hulk;
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
    reg [15:0] queue[$];
    initial begin
        wrst_n=0;
        rrst_n=0;
        wclk=0;
        w_en=0;
        r_en=0;
        rclk=0;
        #5
        wrst_n=1;
        rrst_n=1;
    end
    always begin
        #7 wclk=~wclk;
    end
    always begin
        #13 rclk=~rclk;
    end

initial begin
        logic [15:0] data;
        logic [15:0] rando;
        logic en;
  		logic ren;
  		// int size=0;
        fork 
        repeat(100) begin
            @(posedge wclk);
            rando=$urandom_range(0,16'hFFFF);
            en=$urandom_range(0,1);
            data_in<=rando;
            if(!full && en)begin
                queue.push_back(rando);
                w_en<=en;
            //   size=size+1;
            end 
        //   else if(full)$display("%0d",size);
            else w_en<=0;
            $display("time=%0t full=%b empty=%b queue_size=%0d",
         $time, full, empty, queue.size());
        end
        repeat(50) begin
            @(posedge rclk);
            ren=$urandom_range(0,1);
          	if(!empty && ren)begin
                r_en<=ren;
                data=queue.pop_front();
                @(posedge rclk);
                r_en<=0;
                #1
                if(data!=data_out)begin
                    $display("ERROR");
                    $display("%0d != %0d ",data,data_out);
                end
            end
        //   else if(empty)size=0;
            else r_en<=0;
		end
        join
$finish;
end
endmodule