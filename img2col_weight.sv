// Created date: 2019/10/19
// Creator: Xie Wenzhao
//
// Description: 
// 一个img2col_weigth单元有8个子单元，一个子单元对应一个kernel set，即产生一列weight matrix的值。
// 上级DLA buffer只会存储8个kernel set的值，每个kernel set可以存储很多个kernel(暂定长度121*2，
// 可以存储11^11^1*2,9^9^1^*2,7^7^2*2,5^5^4*2,3^3^12*2,1^1^121*2)，每次img2col开始时，ctrl模块
// 告诉本模块kernel的size，和转换的kernel的数目。
// 此外，采用ping-pang设计，交替读写weight buffer。

module img2col_weight
#(parameter DATA_WID=16)
    (
    input                               clock,
    input                               rst_n,
    input                               i2c_wgt_start,      // img2col开始信号
    input                               i2c_chn_sel,        // 选择哪一个传输通道

    input             [6:0]             chn_num,            // 一次img2col转换的kernel数。最多128（1*1）
    input             [3:0]             kernel_size,        // 可为1,3,5,7,9,11
    input             [DATA_WID-1:0]    wgt_in,             // INT16
    
    output    reg                       i2c_ready,          // img2col单元已准备好，ctrl模块可以暂时撤去控制信号

    output    wire    [7:0]             wgt_rd_addr,        // maximum:1111_0001,half:1000_0000
    output    reg                       wgt_rd_en,

    output    reg     [7:0]             wgt_wr_addr,        // maximum:1111_0001,half:1000_0000
    output    reg                       wgt_wr_en,
    output    wire    [DATA_WID-1:0]    wgt_out,
    output    wire                      chn_sel
);

localparam TRUE  = 1,
           FALSE = 0;

localparam MID_ADDR =  8'b1000_0000;

localparam IDLE     =  3'b001,     // main state
           START    =  3'b010,
           WAIT     =  3'b100;

reg [3:0] state;
reg [3:0] next_state;

reg [6:0] chn_num_store;            // kernel number ready to img2col, maximum is 12(3^3)
reg [6:0] chn_num_cnt;              // number of kernels that already transfer
reg [3:0] ksize;                    // kernel size
reg [6:0] kernel_cnt;

reg i2c_sel;
reg rd_done;
reg wr_done;
assign chn_sel = i2c_sel;

reg img2col_go;
reg [7:0] wgt_addr;                 // kernel address, maximum is 127.
assign wgt_rd_addr = wgt_addr;

reg wr_done_delay0;
reg wr_en_delay_reg0;
reg [6:0] wr_addr_delay_reg0;
reg [DATA_WID-1:0] wr_data_delay_reg0;
assign wgt_out = wgt_in;

always@(posedge clock or negedge rst_n) begin    // state状态转换
    if(!rst_n) state <= IDLE;
    else state <= next_state;
end

always@(*) begin                                 // next_state状态转换
    case(state)
        IDLE: 
            if(i2c_wgt_start==TRUE) next_state = START;
            else next_state = IDLE;
        START: 
            if(i2c_ready == TRUE) next_state = WAIT;
            else next_state = START;
        WAIT: begin
            if((rd_done==TRUE)&&(wr_done==TRUE)) next_state = IDLE;
            else next_state = WAIT;
        end
        default: next_state = IDLE;
    endcase
end

always@(posedge clock or negedge rst_n) begin    // state状态行为
    if(!rst_n) begin
        // TODO: add rst
        i2c_sel <= 0;
        rd_done <= FALSE;
        i2c_ready <= FALSE;
        img2col_go <= FALSE;
    end
    else begin
        case(state)
            IDLE: begin
                i2c_ready <= FALSE;
            end
            START: begin
                i2c_ready <= TRUE;
                img2col_go <= TRUE;
                i2c_sel <= i2c_chn_sel;             // wr/rd channel select
                chn_num_store <= chn_num;           // store kernel number
                ksize <= kernel_size;               // store kernel size
                rd_done <= FALSE;
            end
            WAIT: begin
                if((chn_num_cnt == chn_num_store)&&(kernel_cnt==ksize**2-1)) rd_done <= TRUE;
            end
            default:;
        endcase
    end
end

always@(posedge clock or negedge rst_n) begin        // This block generates the rd signals.
    if(!rst_n) begin
        wgt_addr <= 'b0;
        chn_num_cnt <= 'b0;
        kernel_cnt <= 'b0;
        wgt_rd_en <= FALSE;
    end
    else begin
        if(img2col_go) begin
            wgt_rd_en <= TRUE;
            if(kernel_cnt != ksize**2-1) kernel_cnt <= kernel_cnt + 1;
            else begin
                kernel_cnt <= 'b0;
                if(chn_num_cnt != chn_num_store) chn_num_cnt <= chn_num_cnt + 1;
                else begin
                    chn_num_cnt <= 'b0;
                    wgt_addr <= 'b0;
                    wgt_rd_en <= FALSE;
                end
            end
            if(i2c_sel==1) wgt_addr <= MID_ADDR + (chn_num_cnt*ksize**2) + kernel_cnt;
            else wgt_addr <= (chn_num_cnt*ksize**2) + kernel_cnt; 
            // TODO: need to be check. what if chn_num is 0(which means there is only 1 ifmap channel)
        end
        else begin
            wgt_addr <= 'b0;
            chn_num_cnt <= 'b0;
            kernel_cnt <= 'b0;
            wgt_rd_en <= FALSE;
        end
    end
end

always@(posedge clock or negedge rst_n) begin       // wr address and enable signal generate
    if(!rst_n) begin
        wr_en_delay_reg0 <= 'b0;
        wgt_wr_en <= 'b0;
        wr_addr_delay_reg0 <= 'b0;
        wgt_wr_addr <= 'b0;
    end
    else begin
        wr_en_delay_reg0 <= wgt_rd_en;
        wgt_wr_en <= wr_en_delay_reg0;

        wr_addr_delay_reg0 <= wgt_addr;
        wgt_wr_addr <= wr_addr_delay_reg0;

        wr_done_delay0 <= rd_done;
        wr_done <= wr_done_delay0;
    end
end

endmodule
