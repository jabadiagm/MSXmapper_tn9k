create_clock -name clock_27m -period 37.037 -waveform {0 18.518} [get_ports {ex_clk_27m}]
create_generated_clock -name clock_72m -source [get_ports {ex_clk_27m}] -master_clock clock_27m -multiply_by 8 -divide_by 3 [get_nets {clk_72m}]
