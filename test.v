module mux2to1 (
    input i1,
    input i2,
    input sel,
    output reg x);
    always@(*) begin
        if(sel)x=i2;
        else x=i1;    
    end
endmodule

module mux4to1 (
    input wire i1,
    input wire i2,
    input wire i3,
    input wire i4,
    input wire sel1,
    input wire sel2,
    output reg x
);
always @(*) begin
    if({sel1,sel2}==2'b00)x=i1;
    else if({sel1,sel2}==2'b01)x=i2;
    else if({sel1,sel2}==2'b10)x=i3;
    else x=i4;
end
endmodule

module encoder4to2(
    input wire i1,
    input wire i2,
    input wire i3,
    input wire i4,
    output reg s1,
    output reg s2
);
always@(*) begin
    case({i1,i2,i3,i4})
    4'b0001 : begin s1=0; s2=0;end
    4'b0010 : begin s1=0; s2=1;end
    4'b0100 : begin s1=1; s2=0;end
    4'b1000 : begin s1=1; s2=1;end
    default : begin s1=0; s2=0; end
    endcase
end
endmodule 

module priorityEnco(
    input wire i1,
    input wire i2,
    input wire i3,
    input wire i4,
    output reg s1,
    output reg s2,
    output reg valid
);
always@(*) begin
    casez({i1,i2,i3,i4})
    4'b1??? : {s1,s2,valid}=2'b111;
    4'b01?? : {s1,s2,valid}=2'b101;
    4'b001? : {s1,s2,valid}=2'b011;
    4'b0001 : {s1,s2,valid}=2'b001;
    default : {s1,s2,valid}=2'b000;
    endcase
end
endmodule 

module fsm1011(
    input wire i,
    input wire rst,
    input wire clk,
    output reg j
);
    localparam s0=4'b0000, s1=4'b0001, s2=4'b0010, s3=4'b0101, s4=4'b1011;
    logic [3:0] cs, ns;
    always@(posedge clk)begin
        if(rst)cs<=s0;
        else cs<=ns;
    end
    always@(*)begin
        case (cs)
            s0: ns= (i==1) ? s1 : s0; 
            s1: ns= (i==1) ? s1 : s2; 
            s2: ns= (i==1) ? s3 : s0; 
            s3: ns= (i==1) ? s4 : s2; 
            s4: ns= (i==1) ? s1 : s2; 
            default:  ns=s0;
        endcase
    end
    always @(*) begin
        if(cs==s4) j=1;
        else  j=0;
    end
endmodule

module counter_sync(
    input wire clk,
    input wire rst,
    input wire en,
    output reg cnt
);
    always@(posedge clk)begin
        if(rst)cnt=0;
        else if(en)cnt=cnt+1;
    end
endmodule