// Create Date: 2019/10/24
// Creator: Xie Wenzhao

module i2c_wgt_tb();

localparam TRUE  = 1,
           FALSE = 0;

reg clock;
reg rst_n;
reg i2c_wgt_start;
reg i2c_chn_sel;

reg [6:0] chn_num;
reg [3:0] kernel_size;
reg [15:0] wgt_in;

wire i2c_ready;

wire [7:0] wgt_rd_addr;
wire wgt_rd_en;

wire [7:0] wgt_wr_addr;
wire wgt_wr_en;
wire [15:0] wgt_out;
wire chn_sel;

img2col_weight i2c_wgt_inst(
    .clock(clock),
    .rst_n(rst_n),
    .i2c_wgt_start(i2c_wgt_start),
    .i2c_chn_sel(i2c_chn_sel),

    .chn_num(chn_num),
    .kernel_size(kernel_size),
    .wgt_in(wgt_in);

    .i2c_ready(i2c_ready),

    .wgt_rd_addr(wgt_rd_addr),
    .wgt_rd_en(wgt_rd_en),
    
    .wgt_wr_addr(wgt_wr_addr),
    .wgt_wr_en(wgt_wr_en),
    .wgt_out(wgt_out),
    .chn_sel(chn_sel));

reg [15:0] dina;
reg wea;
reg [7:0] addra;
reg bram_wr_go;
reg bram_wr_done;
reg [7:0] bram_wr_cnt; // 0110_1011(107=3*3*12-1)

blk_mem_gen blk_mem_gen_inst0(
    .clka(clock),
    .dina(dina),
    .addra(addra),
    .wea(wea),

    .clkb(clock),
    .doutb(wgt_in),
    .enb(wgt_rd_en),
    .addrb(wgt_rd_addr));

initial begin
    clock = 0;
    forever #5 clock = ~clock;
end

initial begin
    rst_n = 1;
    #50  rst_n = 0;
    #100 rst_n = 1;
end

// This is the bram data in part.
initial begin
    bram_wr_go = FALSE;
    bram_wr_done = FALSE;
    bram_wr_cnt = 'b0;

    #100 bram_wr_go = TRUE;
end

always@(posedge clock) begin
    if(bram_wr_go == TRUE) begin
        if(bram_wr_cnt <= 8'b1000_1111) begin
            wea <= TRUE;
            dina <= {8'b0,bram_wr_cnt};
            addra <= bram_wr_cnt;
            bram_wr_cnt <= bram_wr_cnt + 1;
        end
        else begin
            wea <= FALSE;
            bram_wr_done <= TRUE;
        end
    end 
end
// Bram data in part finishes.

// This is the bram data read part.
always@(posedge clock) begin
    if(bram_wr_done == TRUE && i2c_ready == FALSE) begin
        i2c_chn_sel <= 0;
        chn_num <= 8'b0110_1011; //107=3*3*12-1
        kernel_size <= 4'b0011;
        i2c_wgt_start <= TRUE;
    end
    else if(i2c_ready == TRUE) begin
        i2c_wgt_start <= FALSE;
    end
end

endmodule