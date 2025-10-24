
wire kernel_monitor_reset;
wire kernel_monitor_clock;
wire kernel_monitor_report;
assign kernel_monitor_reset = ~ap_rst_n;
assign kernel_monitor_clock = ap_clk;
assign kernel_monitor_report = 1'b0;
wire [2:0] axis_block_sigs;
wire [2:0] inst_idle_sigs;
wire [0:0] inst_block_sigs;
wire kernel_block;

assign axis_block_sigs[0] = ~stream_o_TDATA_blk_n;
assign axis_block_sigs[1] = ~grp_axis_read_lines_33_1920_stream_dim_t_axis_s_fu_313.stream_i_TDATA_blk_n;
assign axis_block_sigs[2] = ~grp_execute_Pipeline_VITIS_LOOP_318_2_fu_361.stream_o_TDATA_blk_n;

assign inst_block_sigs[0] = 1'b0;

assign inst_idle_sigs[0] = 1'b0;
assign inst_idle_sigs[1] = grp_axis_read_lines_33_1920_stream_dim_t_axis_s_fu_313.ap_idle;
assign inst_idle_sigs[2] = grp_execute_Pipeline_VITIS_LOOP_318_2_fu_361.ap_idle;

execute_hls_deadlock_idx0_monitor execute_hls_deadlock_idx0_monitor_U (
    .clock(kernel_monitor_clock),
    .reset(kernel_monitor_reset),
    .axis_block_sigs(axis_block_sigs),
    .inst_idle_sigs(inst_idle_sigs),
    .inst_block_sigs(inst_block_sigs),
    .block(kernel_block)
);


always @ (kernel_block or kernel_monitor_reset) begin
    if (kernel_block == 1'b1 && kernel_monitor_reset == 1'b0) begin
        find_kernel_block = 1'b1;
    end
    else begin
        find_kernel_block = 1'b0;
    end
end
