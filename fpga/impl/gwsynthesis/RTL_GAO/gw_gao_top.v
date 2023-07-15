module gw_gao(
    bus_reset_n,
    ex_bus_data_reverse_n,
    ex_bus_mreq_n,
    ex_bus_rd_n,
    ex_bus_sltsl_n,
    psram_read,
    psram_write,
    psram_busy,
    \mapper_reg0[7] ,
    \mapper_reg0[6] ,
    \mapper_reg0[5] ,
    \mapper_reg0[4] ,
    \mapper_reg0[3] ,
    \mapper_reg0[2] ,
    \mapper_reg0[1] ,
    \mapper_reg0[0] ,
    \mapper_reg1[7] ,
    \mapper_reg1[6] ,
    \mapper_reg1[5] ,
    \mapper_reg1[4] ,
    \mapper_reg1[3] ,
    \mapper_reg1[2] ,
    \mapper_reg1[1] ,
    \mapper_reg1[0] ,
    \mapper_reg2[7] ,
    \mapper_reg2[6] ,
    \mapper_reg2[5] ,
    \mapper_reg2[4] ,
    \mapper_reg2[3] ,
    \mapper_reg2[2] ,
    \mapper_reg2[1] ,
    \mapper_reg2[0] ,
    \mapper_reg3[7] ,
    \mapper_reg3[6] ,
    \mapper_reg3[5] ,
    \mapper_reg3[4] ,
    \mapper_reg3[3] ,
    \mapper_reg3[2] ,
    \mapper_reg3[1] ,
    \mapper_reg3[0] ,
    mapper_read,
    bus_data_reverse,
    \mono1/counting ,
    mapper_write,
    \check_fsm_counter_max[7] ,
    \check_fsm_counter_max[6] ,
    \check_fsm_counter_max[5] ,
    \check_fsm_counter_max[4] ,
    \check_fsm_counter_max[3] ,
    \check_fsm_counter_max[2] ,
    \check_fsm_counter_max[1] ,
    \check_fsm_counter_max[0] ,
    clk_72m,
    tms_pad_i,
    tck_pad_i,
    tdi_pad_i,
    tdo_pad_o
);

input bus_reset_n;
input ex_bus_data_reverse_n;
input ex_bus_mreq_n;
input ex_bus_rd_n;
input ex_bus_sltsl_n;
input psram_read;
input psram_write;
input psram_busy;
input \mapper_reg0[7] ;
input \mapper_reg0[6] ;
input \mapper_reg0[5] ;
input \mapper_reg0[4] ;
input \mapper_reg0[3] ;
input \mapper_reg0[2] ;
input \mapper_reg0[1] ;
input \mapper_reg0[0] ;
input \mapper_reg1[7] ;
input \mapper_reg1[6] ;
input \mapper_reg1[5] ;
input \mapper_reg1[4] ;
input \mapper_reg1[3] ;
input \mapper_reg1[2] ;
input \mapper_reg1[1] ;
input \mapper_reg1[0] ;
input \mapper_reg2[7] ;
input \mapper_reg2[6] ;
input \mapper_reg2[5] ;
input \mapper_reg2[4] ;
input \mapper_reg2[3] ;
input \mapper_reg2[2] ;
input \mapper_reg2[1] ;
input \mapper_reg2[0] ;
input \mapper_reg3[7] ;
input \mapper_reg3[6] ;
input \mapper_reg3[5] ;
input \mapper_reg3[4] ;
input \mapper_reg3[3] ;
input \mapper_reg3[2] ;
input \mapper_reg3[1] ;
input \mapper_reg3[0] ;
input mapper_read;
input bus_data_reverse;
input \mono1/counting ;
input mapper_write;
input \check_fsm_counter_max[7] ;
input \check_fsm_counter_max[6] ;
input \check_fsm_counter_max[5] ;
input \check_fsm_counter_max[4] ;
input \check_fsm_counter_max[3] ;
input \check_fsm_counter_max[2] ;
input \check_fsm_counter_max[1] ;
input \check_fsm_counter_max[0] ;
input clk_72m;
input tms_pad_i;
input tck_pad_i;
input tdi_pad_i;
output tdo_pad_o;

wire bus_reset_n;
wire ex_bus_data_reverse_n;
wire ex_bus_mreq_n;
wire ex_bus_rd_n;
wire ex_bus_sltsl_n;
wire psram_read;
wire psram_write;
wire psram_busy;
wire \mapper_reg0[7] ;
wire \mapper_reg0[6] ;
wire \mapper_reg0[5] ;
wire \mapper_reg0[4] ;
wire \mapper_reg0[3] ;
wire \mapper_reg0[2] ;
wire \mapper_reg0[1] ;
wire \mapper_reg0[0] ;
wire \mapper_reg1[7] ;
wire \mapper_reg1[6] ;
wire \mapper_reg1[5] ;
wire \mapper_reg1[4] ;
wire \mapper_reg1[3] ;
wire \mapper_reg1[2] ;
wire \mapper_reg1[1] ;
wire \mapper_reg1[0] ;
wire \mapper_reg2[7] ;
wire \mapper_reg2[6] ;
wire \mapper_reg2[5] ;
wire \mapper_reg2[4] ;
wire \mapper_reg2[3] ;
wire \mapper_reg2[2] ;
wire \mapper_reg2[1] ;
wire \mapper_reg2[0] ;
wire \mapper_reg3[7] ;
wire \mapper_reg3[6] ;
wire \mapper_reg3[5] ;
wire \mapper_reg3[4] ;
wire \mapper_reg3[3] ;
wire \mapper_reg3[2] ;
wire \mapper_reg3[1] ;
wire \mapper_reg3[0] ;
wire mapper_read;
wire bus_data_reverse;
wire \mono1/counting ;
wire mapper_write;
wire \check_fsm_counter_max[7] ;
wire \check_fsm_counter_max[6] ;
wire \check_fsm_counter_max[5] ;
wire \check_fsm_counter_max[4] ;
wire \check_fsm_counter_max[3] ;
wire \check_fsm_counter_max[2] ;
wire \check_fsm_counter_max[1] ;
wire \check_fsm_counter_max[0] ;
wire clk_72m;
wire tms_pad_i;
wire tck_pad_i;
wire tdi_pad_i;
wire tdo_pad_o;
wire tms_i_c;
wire tck_i_c;
wire tdi_i_c;
wire tdo_o_c;
wire [9:0] control0;
wire gao_jtag_tck;
wire gao_jtag_reset;
wire run_test_idle_er1;
wire run_test_idle_er2;
wire shift_dr_capture_dr;
wire update_dr;
wire pause_dr;
wire enable_er1;
wire enable_er2;
wire gao_jtag_tdi;
wire tdo_er1;

IBUF tms_ibuf (
    .I(tms_pad_i),
    .O(tms_i_c)
);

IBUF tck_ibuf (
    .I(tck_pad_i),
    .O(tck_i_c)
);

IBUF tdi_ibuf (
    .I(tdi_pad_i),
    .O(tdi_i_c)
);

OBUF tdo_obuf (
    .I(tdo_o_c),
    .O(tdo_pad_o)
);

GW_JTAG  u_gw_jtag(
    .tms_pad_i(tms_i_c),
    .tck_pad_i(tck_i_c),
    .tdi_pad_i(tdi_i_c),
    .tdo_pad_o(tdo_o_c),
    .tck_o(gao_jtag_tck),
    .test_logic_reset_o(gao_jtag_reset),
    .run_test_idle_er1_o(run_test_idle_er1),
    .run_test_idle_er2_o(run_test_idle_er2),
    .shift_dr_capture_dr_o(shift_dr_capture_dr),
    .update_dr_o(update_dr),
    .pause_dr_o(pause_dr),
    .enable_er1_o(enable_er1),
    .enable_er2_o(enable_er2),
    .tdi_o(gao_jtag_tdi),
    .tdo_er1_i(tdo_er1),
    .tdo_er2_i(1'b0)
);

gw_con_top  u_icon_top(
    .tck_i(gao_jtag_tck),
    .tdi_i(gao_jtag_tdi),
    .tdo_o(tdo_er1),
    .rst_i(gao_jtag_reset),
    .control0(control0[9:0]),
    .enable_i(enable_er1),
    .shift_dr_capture_dr_i(shift_dr_capture_dr),
    .update_dr_i(update_dr)
);

ao_top_0  u_la0_top(
    .control(control0[9:0]),
    .trig0_i(mapper_read),
    .trig1_i(mapper_write),
    .trig2_i(bus_reset_n),
    .trig3_i({\check_fsm_counter_max[7] ,\check_fsm_counter_max[6] ,\check_fsm_counter_max[5] ,\check_fsm_counter_max[4] ,\check_fsm_counter_max[3] ,\check_fsm_counter_max[2] ,\check_fsm_counter_max[1] ,\check_fsm_counter_max[0] }),
    .data_i({bus_reset_n,ex_bus_data_reverse_n,ex_bus_mreq_n,ex_bus_rd_n,ex_bus_sltsl_n,psram_read,psram_write,psram_busy,\mapper_reg0[7] ,\mapper_reg0[6] ,\mapper_reg0[5] ,\mapper_reg0[4] ,\mapper_reg0[3] ,\mapper_reg0[2] ,\mapper_reg0[1] ,\mapper_reg0[0] ,\mapper_reg1[7] ,\mapper_reg1[6] ,\mapper_reg1[5] ,\mapper_reg1[4] ,\mapper_reg1[3] ,\mapper_reg1[2] ,\mapper_reg1[1] ,\mapper_reg1[0] ,\mapper_reg2[7] ,\mapper_reg2[6] ,\mapper_reg2[5] ,\mapper_reg2[4] ,\mapper_reg2[3] ,\mapper_reg2[2] ,\mapper_reg2[1] ,\mapper_reg2[0] ,\mapper_reg3[7] ,\mapper_reg3[6] ,\mapper_reg3[5] ,\mapper_reg3[4] ,\mapper_reg3[3] ,\mapper_reg3[2] ,\mapper_reg3[1] ,\mapper_reg3[0] ,mapper_read,bus_data_reverse,\mono1/counting }),
    .clk_i(clk_72m)
);

endmodule
