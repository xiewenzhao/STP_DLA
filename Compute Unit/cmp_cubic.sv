// Created: 2019/10/15
// Creator: Xie Wenzhao
// Module explanation:

// Change history:
// 2019/10/15: file created by Xie Wenzhao

module cmp_cubic
#(parameter DATA_WID=16, SIZE=8)
    (   
    input clock,
    input rst_n,
    input [DATA_WID-1:0] weights [SIZE-1:0][SIZE-1:0],
    input [DATA_WID-1:0] pixels [SIZE-1:0][SIZE-1:0],

    output [47:0] acc_out [SIZE-1:0][SIZE-1:0]
);

integer i,j,k;

reg [47:0] acc_reg [SIZE-1:0][SIZE-1:0];

wire [47:0] psums_wire0 [SIZE-1:0][SIZE-1:0];
cmp_layer cmp_layer_inst0(
    .clock(clock),
    .rst_n(rst_n),
    .weights(weights[0][SIZE-1:0]),
    .pixels(pixels[0][SIZE-1:0]),
    .psums_out(psums_wire0)
);

wire [47:0] psums_wire1 [SIZE-1:0][SIZE-1:0];
cmp_layer cmp_layer_inst1(
    .clock(clock),
    .rst_n(rst_n),
    .weights(weights[1][SIZE-1:0]),
    .pixels(pixels[1][SIZE-1:0]),
    .psums_out(psums_wire1)
);

wire [47:0] psums_wire2 [SIZE-1:0][SIZE-1:0];
cmp_layer cmp_layer_inst2(
    .clock(clock),
    .rst_n(rst_n),
    .weights(weights[2][SIZE-1:0]),
    .pixels(pixels[2][SIZE-1:0]),
    .psums_out(psums_wire2)
);

wire [47:0] psums_wire3 [SIZE-1:0][SIZE-1:0];
cmp_layer cmp_layer_inst3(
    .clock(clock),
    .rst_n(rst_n),
    .weights(weights[3][SIZE-1:0]),
    .pixels(pixels[3][SIZE-1:0]),
    .psums_out(psums_wire3)
);

wire [47:0] psums_wire4 [SIZE-1:0][SIZE-1:0];
cmp_layer cmp_layer_inst0(
    .clock(clock),
    .rst_n(rst_n),
    .weights(weights[4][SIZE-1:0]),
    .pixels(pixels[4][SIZE-1:0]),
    .psums_out(psums_wire4)
);

wire [47:0] psums_wire5 [SIZE-1:0][SIZE-1:0];
cmp_layer cmp_layer_inst5(
    .clock(clock),
    .rst_n(rst_n),
    .weights(weights[5][SIZE-1:0]),
    .pixels(pixels[5][SIZE-1:0]),
    .psums_out(psums_wire5)
);

wire [47:0] psums_wire6 [SIZE-1:0][SIZE-1:0];
cmp_layer cmp_layer_inst6(
    .clock(clock),
    .rst_n(rst_n),
    .weights(weights[6][SIZE-1:0]),
    .pixels(pixels[6][SIZE-1:0]),
    .psums_out(psums_wire6)
);

wire [47:0] psums_wire7 [SIZE-1:0][SIZE-1:0];
cmp_layer cmp_layer_inst7(
    .clock(clock),
    .rst_n(rst_n),
    .weights(weights[7][SIZE-1:0]),
    .pixels(pixels[7][SIZE-1:0]),
    .psums_out(psums_wire7)
);

always@(posedge clock) begin
    if(!rst_n) begin
        for(j=0;j<SIZE;j=j+1) 
            for(k=0;k<SIZE;k=k+1)
                acc_reg[j][k] <= 'b0;
    end
    else begin
        for(j=0;j<SIZE;j=j+1)
            for(k=0;k<SIZE;k=k+1)
                for(i=0;i<SIZE;i=i+1)
                    acc_reg[j][k] <= psums_wire0[j][k] + psums_wire1[j][k] + psums_wire2[j][k] 
                                     psums_wire3[j][k] + psums_wire4[j][k] + psums_wire5[j][k]
                                     psums_wire6[j][k] + psums_wire7[j][k] ;
    end
end

genvar gen_i,gen_j,gen_k;
generate
    for(gen_j=0;gen_j<SIZE;gen_j=gen_j+1)
    begin
        for(gen_k=0;gen_k<SIZE;gen_k=gen_k+1)
        begin
            assign acc_out[gen_j][gen_k] = acc_reg[gen_j][gen_k];
        end
    end
endgenerate

endmodule