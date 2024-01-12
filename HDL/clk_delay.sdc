set half_period [expr 0.5 * $period]
create_clock -period $period -name clk -waveform [list 0.0 $half_period] [get_ports clk]
set_input_delay $half_period -clock clk [remove_from_collection [all_inputs] [get_ports clk]]
set_output_delay -clock clk $half_period [all_outputs]
