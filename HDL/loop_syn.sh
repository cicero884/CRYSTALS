#/bin/bash
extract() {
	local value=$(echo "$1" | grep -E "$2.*$" | grep -Eo "([0-9]*[.])?[0-9]+")
	#[ -z "$value" ] && value=0
	echo $value
}

#variable=MWR2MM_D
variable=KRED_MULCUT
file=mo_mul.svh

# loop by clk
echo "clk, area" > result.csv
for var in {1..4}
do
	echo "clk, area" > result${var}.csv
	sed -i "s/$variable=[0-9]/$variable=$var/" $file
	for clk in $(seq 1.0 0.1 5.0)
	do
		half_cycle=$(bc <<< "scale=4; $clk/3")
		echo "create_clock -period $clk -name clk -waveform {$clk $half_cycle} [get_ports clk]" > clk.sdc
		# TODO add half inout delay?(not here)
		#echo "set_input_delay $half_cycle -clock clk [remove_from_collection [all_inputs] [get_ports clk]] -clock_fall"
		#echo "set_output_delay -clock clk -clock_fall 0.500 [all_outputs]"
		make syn
		area_log=$(< area.log)
		if grep -wq "VIOLATED" timing.log; then
			echo "period=		$clk: Timing violated, not record"
		else
			area=$(extract "$area_log" "Total cell area:")
			echo "period=		$clk: area:			$area"
			echo "$clk,$area" >> result${var}.csv
		fi
	done
done
