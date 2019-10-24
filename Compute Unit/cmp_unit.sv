// Created: 2019/10/15
// Creator: Xie Wenzhao
// Module explanation:

// Change history:
// 2019/10/15: file created by Xie Wenzhao

module cmp_unit
#(parameter DATA_WID=16)
    (
    input clock,
    input rst_n,
    input [DATA_WID-1:0] weight,
    input [DATA_WID-1:0] pixel,
    input wgt_state,
    input ifm_state,
    
    output logic [47:0] psum_out
);

reg [DATA_WID-1:0] wgt_reg;
reg [DATA_WID-1:0] pixel_reg;
wire reg_gate;

assign reg_gate = wgt_state && ifm_state; // 1 means they are all not 0

always@(posedge clock) begin
    if(!rst_n) begin
        wgt_reg <= 'b0;
        pixel_reg <= 'b0;
    end
    else if(reg_gate) begin
            wgt_reg <= weight;
            pixel_reg <= pixel;
        end
end

assign psum_out = reg_gate ? wgt_reg * pixel_reg : 0;

endmodule