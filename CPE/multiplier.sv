// Created date : 2019/9/25
// Coder : Wenzhao Xie
// Last revised : 2019/9/26
/*
模块功能说明：
    在由control logic发出的kernel_run信号置高后，kernel元素从信号输入端输入，在输入完9个之后，kernel_run信号
应该拉低。之后，mult_run信号应该被置高，每个乘法单元做乘法之后把积存入寄存器，下一个周期进行加法树操作，输出kernel
的psum。
    应该注意的点是，与reg_chain模块的数据对齐，以及乘法、累加等操作的中间结果的位宽截位。
*/
// To do: how to reset?

module multiplier
#(parameter KERNEL_SIZE = 3, WIDTH = 16, LST_BIT = 0, MST_BIT = 35)
    (
    input clock,
    input kernel_run,
    input mult_run,
    input [WIDTH-1:0] kernel_input,
    input [WIDTH-1:0] pixels [KERNEL_SIZE*KERNEL_SIZE-1:0],

    output reg [23:0] psum_kernel
);

interger j;

reg [WIDTH-1:0] kernel_reg [KERNEL_SIZE*KERNEL_SIZE-1:0];
reg [2*WIDTH-1:0] product_reg [KERNEL_SIZE*KERNEL_SIZE-1:0];

reg [35:0] inter_reg [6:0];

genvar i;
generate
    for(i=0;i<KERNEL_SIZE*KERNEL_SIZE-1;i=i+1)
    begin:kernel_reg
        always@(posedge clock)
            if(kernel_run)
                kernel_reg[i] <= kernel_reg[i+1];
    end
endgenerate

always@(posedge clock)
    if(kernel_run) kernel_reg[0] <= kernel_input;

/*
mult0
     + ——→ inter0
mult1
                  + ——→ inter4
mult2
     + ——→ inter1
mult3
                                + ——→ inter6 + mult8 = psum_kernel
mult4
     + ——→ inter2
mult5
                  + ——→ inter5
mult6
     + ——→ inter3 
mult7
*/
always@(posedge clock) begin
    if(mult_run) begin
        for(j=0;j<KERNEL_SIZE*KERNEL_SIZE;i=j+1) begin
            product_reg[j] <= kernel_reg[j] * pixels[j];
        end

        inter_reg[0] <= product_reg[0] + product_reg[1];
        inter_reg[1] <= product_reg[2] + product_reg[3];
        inter_reg[2] <= product_reg[4] + product_reg[5];
        inter_reg[3] <= product_reg[6] + product_reg[7];

        inter_reg[4] <= inter_reg[0] + inter_reg[1];
        inter_reg[5] <= inter_reg[2] + inter_reg[3];
        inter_reg[6] <= inter_reg[4] + inter_reg[5];
        
        psum_kernel <= inter_reg[6] + product_reg[8];
    end
end

// 截位操作

endmodule