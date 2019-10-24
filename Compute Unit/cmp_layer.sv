// Created: 2019/10/15
// Creator: Xie Wenzhao
// Module explanation:

// Change history:
// 2019/10/15: file created by Xie Wenzhao
// 2019/10/16: output logic -> output wire

module cmp_layer
#(parameter DATA_WID=16, SIZE=8)
    (
    input clock,
    input rst_n,
    input [DATA_WID-1:0] weights [SIZE-1:0],
    input [DATA_WID-1:0] pixels [SIZE-1:0],
    
    output wire [47:0] psums_out [SIZE-1:0][SIZE-1:0]
);

wire [SIZE-1:0] weight_states;
wire [SIZE-1:0] pixel_states;

genvar gen_i;
generate
    for(gen_i=0;gen_i<SIZE;gen_i=gen_i+1)
    begin
        assign weight_states[gen_i] = (weights[gen_i] != 16'b0);
        assign pixel_states[gen_i] = (pixels[gen_i] != 16'b0);
    end
endgenerate

genvar gen_m,gen_n;
generate
    for(gen_m=0;gen_m<SIZE;gen_m=gen_m+1)
    begin
        for(gen_n=0;gen_n<SIZE;gen_n=gen_n+1)
        begin
            cmp_unit cmp_unit_inst(
                .clock(clock),
                .rst_n(rst_n),
                .weight(weights[gen_n]),
                .pixel(pixels[gen_m]),
                .wgt_state(weight_states[gen_n]),
                .ifm_state(pixel_states[gen_m]),
                .psum_out(psums_out[gen_m][gen_n])
            );
        end
    end
endgenerate

endmodule