// Created date : 2019/9/25
// Coder : Wenzhao Xie
// Last revised : 2019/9/25
/* 
模块功能说明：
    chain_run信号由外部control logic输入，chain_run拉高后应该一直保持，直至该tile的卷积做完。
在chain_run有效期间，pixel数据从数据输入端流入，以脉动形式在寄存器链内传播。chain_run信号应该
在最后一个pixel流入寄存器链的第一个寄存器后拉低。
    这里的pixel数据，与multiplier的kernel数据之间的对齐，要由control logic做好。
*/
// To do: how to reset?

module reg_chain
#(parameter WIDTH = 16, SEL_WIDTH = 5)
    (
    input clock,
    input chain_run,
    input [WIDTH-1:0] pixel_in,
    input [SEL_WIDTH-1:0] sel
    
    output wire [WIDTH-1:0] pixels_4_mult [KERNEL_SIZE*KERNEL_SIZE-1:0]
);

parameter KERNEL_SIZE = 3;

reg [WIDTH-1:0] pixel_reg_row0 [2**SEL_WIDTH-1:0];
reg [WIDTH-1:0] pixel_reg_row1 [2**SEL_WIDTH-1:0];
reg [WIDTH-1:0] pixel_reg_row2 [KERNEL_SIZE-1:0];

genvar i;
generate
    for(i=2**SEL_WIDTH-1;i>0;i=i-1) 
    begin:pixel_reg_row0
        always@(posedge clock)
            if(chain_run)
                pixel_reg_row0[i] <= (chain_run==1) ? pixel_reg_row0[i-1]:pixel_reg_row0[i];
    end
endgenerate

genvar j;
generate
    for(j=2**SEL_WIDTH-1;j>0;j=j-1) 
    begin:pixel_reg_row1
        always@(posedge clock)
            if(chain_run)
                pixel_reg_row1[j] <= (chain_run==1) ? pixel_reg_row1[j-1]:pixel_reg_row1[j];
    end
endgenerate

genvar k;
generate
    for(k=KERNEL_SIZE-1;k>0;k=k-1) 
    begin:pixel_reg_row2
        always@(posedge clock)
            if(chain_run)
                pixel_reg_row2[k] <= (chain_run==1) ? pixel_reg_row2[k-1]:pixel_reg_row2[k];
    end
endgenerate

always@(posedge clock) begin
    if(chain_run) begin
        pixel_reg_row0[0] <= pixel_in;
        pixel_reg_row1[0] <= pixel_reg_row0[sel];
        pixel_reg_row2[0] <= pixel_reg_row1[sel];
    end
end

always@(*) begin
    pixels_4_mult[0] = pixel_reg_row2[2];
    pixels_4_mult[1] = pixel_reg_row2[1];
    pixels_4_mult[2] = pixel_reg_row2[0];

    pixels_4_mult[3] = pixel_reg_row1[2];
    pixels_4_mult[4] = pixel_reg_row1[1];
    pixels_4_mult[5] = pixel_reg_row1[0];

    pixels_4_mult[6] = pixel_reg_row1[2];
    pixels_4_mult[7] = pixel_reg_row1[1];
    pixels_4_mult[8] = pixel_reg_row1[0];
end

endmodule