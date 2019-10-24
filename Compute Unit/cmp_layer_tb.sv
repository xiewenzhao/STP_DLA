// Create data: 2019/10/24
// Creator: Xie Wenzhao

module cmp_layer_tb();

reg clock;
reg rst_n;

initial begin
    clock = 0;
    forever #5 clock = ~clock;
end

initial begin
    rst_n = 1;
    #50 rst_n = 0;
    #50 rst_n = 1;
end

integer i;
reg [15:0] weights [7:0];
reg [15:0] pixels  [7:0];
wire [31:0] psums_out [7:0][7:0];

cmp_layer cmp_layer_inst(
    .clock(clock),
    .rst_n(rst_n),
    .weights(weights),
    .pixels(pixels),
    .psums_out(psums_out));

reg test_go;
reg [2:0] test_cnt;
initial begin
    test_cnt = 'b0;
    test_go = 0;
    for(i=0;i<8;i=i+1) weights[i] = 'b0;
    for(i=0;i<8;i=i+1) pixels[i] = 'b0;
    #150 test_go = 0;
end

always@(posedge clock) begin
    if(test_go && test_cnt<=3'011) begin
        test_cnt <= test_cnt + 1;
        case(test_cnt)
            3'b000: begin
                for(i=0;i<8;i=i+1) weights[i] = i;
                for(i=0;i<8;i=i+1) pixels[i] = i + 1;
            end
            3'b001: begin
                for(i=0;i<8;i=i+1) weights[i] = i + 16;
                for(i=0;i<8;i=i+1) pixels[i] = i + 16;
            end
            3'b010: begin
                for(i=0;i<8;i=i+1) weights[i] = -1 * (i*16);
                for(i=0;i<8;i=i+1) pixels[i] = i*16;
            end
            3'b011: begin
                for(i=0;i<8;i=i+1) weights[i] = -1 * (i+32);
                for(i=0;i<8;i=i+1) pixels[i] = -1 * (i+64);
            end
        endcase
    end
end

endmodule