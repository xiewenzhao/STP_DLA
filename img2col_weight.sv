// Created date: 2019/10/19
// Creator: Xie Wenzhao
// Description: 一个img2col_weigth单元有8个子单元，一个子单元对应一个kernel set，即产生一列weight matrix的值。
//              上级DLA buffer只会存储8个kernel set的值，每个kernel set可以存储很多个kernel(暂定最多64个)。
//              相对应的，cubic前的weight buffer只会有有限个channel的kernel,所以采用ping-pang设计weight buffer，
//              交替读写weight buffer。

module img2col_weight
#(parameter DATA_WID=16, SIZE=8)
    (
    input clock,
    input rst_n,
    input i2c_wgt_start,

    input [2:0] chn_one_time,
    input [2:0] chn_rpt_times,
    input [3:0] kernel_size,
    input [DATA_WID-1:0] wgt_in [SIZE-1:0],
    
    output reg i2c_ready;

    output reg [9:0] wgt_rd_addr [SIZE-1:0],   // 9*64
    output reg wgt_rd_en [SIZE-1:0],

    output reg [9:0] wgt_rd_addr [SIZE-1:0],   // 9*64
    output reg [DATA_WID-1:0] wgt_out [SIZE-1:0]
);

integer i;

reg [2:0] chn_num,chn_times;
reg [2:0] chn_num_cnt,chn_times_cnt;

reg [2:0] state,next_state;
parameter IDLE  =  3'b000,
          START =  3'b001,
          RUN   =  3'b010,
          HOLD  =  3'b011;

reg [1:0] rd_state,wr_state;
parameter SET   = 2'b00,
          WAIT  = 2'b01,
          ACK   = 2'b10;

always@(posedge clock) begin    // state状态转换
    if(!rst_n) state <= IDLE;
    else state <= next_state;
end

always@(posedge clock) begin    // next_state状态转换
    if(!rst_n) next_state <= IDLE;
    else begin
        case(state)
            IDLE: begin
                if(i2c_wgt_start) next_state <= START;
                else next_state <= IDLE;
            end
            START: begin
                next_state <= RUN;
            end
            RUN: begin
                
            end
            HOLD: begin

            end
        endcase
    end
end

always@(posedge clock) begin    // state状态行为
    case(state)
        IDLE:;
        START: begin
            i2c_ready <= 1'b1;
            chn_num <= chn_one_time;
            chn_times <= chn_rpt_times;
            chn_num_cnt <= chn_one_time;
            chn_times_cnt <= chn_rpt_times;
            for(i=0;i<8;i=i+1) begin
                wgt_rd_en[i] <= 1'b1;
                wgt_rd_addr[i] <= 'b0;
            end
        end
        RUN: begin
            
        end
        HOLD: begin

        end
        default:;
    endcase
end

genvar gv_i;
generate
    for(gv_i=0;gv_i<SIZE;gv_i=gv_i+1) begin
        assign wgt_addr[gv_i] = wgt_rd_addr;
    end
endgenerate