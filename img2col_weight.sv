// Created date: 2019/10/19
// Creator: Xie Wenzhao
//
// Description: 
// 一个img2col_weigth单元有8个子单元，一个子单元对应一个kernel set，即产生一列weight matrix的值。
// 上级DLA buffer只会存储8个kernel set的值，每个kernel set可以存储很多个kernel(暂定最多64个)。
// 相对应的，cubic前的weight buffer只会有有限个channel的kernel(暂定8个),所以采用ping-pang设计，
// 交替读写weight buffer。

module img2col_weight
#(parameter DATA_WID=16, SIZE=8)
    (
    input                               clock,
    input                               rst_n,
    input                               i2c_wgt_start,      // 大循环开始信号
    input                               i2c_wgt_continue,   // 小循环开始信号

    input             [2:0]             chn_one_time,       // 一次img2col小循环转换的kernel数
    input             [2:0]             chn_rpt_times,      // 一次img2col大循环包含的小循环数
    input             [3:0]             kernel_size,        
    input             [DATA_WID-1:0]    wgt_in,
    
    output    reg                       i2c_ready;          // img2col单元已准备好，ctrl模块可以暂时撤去控制信号
    output    reg                       chn_one_time_done;  // 一次小循环完成
    output    reg                       chn_rpt_done;       // 一次大循环完成

    output    wire    [9:0]             wgt_rd_addr,        // 9*64
    output    reg                       wgt_rd_en,

    output    wire    [6:0]             wgt_wr_addr,   // 9*8
    output    reg     [DATA_WID-1:0]    wgt_out
);

parameter TRUE  = 1,
          FALSE = 0;

reg [2:0] state,next_state;
parameter IDLE  =  3'b000,
          START =  3'b001,
          RUN   =  3'b010,
          HOLD  =  3'b011;

// BRAM write latency 0, read latency 2.
reg [2:0] rd_state;
parameter SILENT  =  3'b000,
          SET     =  3'b001,
          WAIT0   =  3'b010,
          WAIT1   =  3'b011,
          WAIT2   =  3'b100,
          READING =  3'b101;

reg [2:0] chn_num,chn_times;
reg [2:0] chn_num_cnt,chn_times_cnt;

reg base_addr_go;
reg shift_addr_go;
reg [6:0] wgt_shift_addr;
reg [9:0] wgt_rd_base_addr;
assign wgt_rd_addr = wgt_rd_base_addr + wgt_shift_addr;

reg wr_go;
reg wr_en_delay_reg0,wr_en_delay_reg1,wr_en_delay_reg2;
reg [6:0] wr_addr_delay_reg0,wr_addr_delay_reg1,wr_addr_delay_reg2;
reg [DATA_WID-1:0] wr_data_delay_reg0,wr_data_delay_reg1,wr_data_delay_reg2;
reg [6:0] wgt_wr_addr;

always@(posedge clock) begin    // state状态转换
    if(!rst_n) state <= IDLE;
    else state <= next_state;
end

always@(posedge clock) begin    // next_state状态转换
    if(!rst_n) next_state <= IDLE;
    else begin
        case(state)
            IDLE: 
                if(i2c_wgt_start) next_state <= START;
                else next_state <= IDLE;
            START: next_state <= RUN;
            RUN: begin
                if(chn_num_cnt == chn_num)
                    if(chn_times_cnt == chn_times) next_state <= IDLE;
                    else next_state <= HOLD;
            end
            HOLD: begin

            end
            default: next_state <= IDLE;
        endcase
    end
end

always@(posedge clock) begin    // state状态行为
    case(state)
        IDLE: begin
            rd_state <= SILENT;
        end;
        START: begin
            i2c_ready <= TRUE;
            chn_num <= chn_one_time;
            chn_times <= chn_rpt_times;
            rd_state <= SET;
        end
        RUN: begin
            case(rd_state)
            SET: begin
                base_addr_go <= TRUE;
                shift_addr_go <= TRUE;
                chn_one_time_done <= FALSE;
                chn_rpt_done <= FALSE;
                rd_state <= WAIT0;
            end
            WAIT0: rd_state <= WAIT1;
            WAIT1: rd_state <= WAIT2;
            WAIT2: rd_state <= READING;
            READING: begin
                wr_go <= TRUE;      // TODO: write wr block
                if(chn_num_cnt == chn_num) begin
                    chn_one_time_done <= TRUE;
                    shift_addr_go <= FLASE;
                    rd_state <= SILENT;
                    if(chn_times_cnt == chn_times) begin
                        base_addr_go <= FALSE;
                        chn_rpt_done <= TRUE;
                    end
                end
            end
            default:;
            endcase
        end
        HOLD: begin

        end
        default:;
    endcase
end

always@(posedge clock) begin        // Weight read address generation block.
    if(!rst_n) begin
        base_addr_go <= FALSE;
        shift_addr_go <= FALSE;
    end
    else begin
        if(base_addr_go) begin
            if(shift_addr_go) begin
                wgt_rd_en <= TRUE;
                wgt_shift_addr <= chn_num_cnt;
                if(chn_num_cnt != chn_num) chn_num_cnt <= chn_num_cnt + 1;
                else begin
                    chn_num_cnt <= 'b0;
                    wgt_shift_addr <= 'b0;
                    wgt_rd_base_addr <= wgt_rd_base_addr + wgt_shift_addr;
                    wgt_rd_en <= FALSE;
                    if(chn_times_cnt == chn_times) chn_times_cnt <= 'b0;
                    else chn_times_cnt <= chn_times_cnt + 1;
                end
                // TODO: need to be check. what if chn_num is 0(which means there is only 1 ifmap channel)
            end
            else begin
                wgt_rd_en <= FALSE;
                chn_num_cnt <= 'b0;
            end
        end
        else begin
            wgt_rd_base_addr <= 'b0; // wgt_rd_base_addr initialization.
            chn_times_cnt <= 'b0;
        end
    end
end

always@(posedge clock) begin        // Weight write address generation block.
    if(!rst_n) begin

    end
    else begin

    end
end
