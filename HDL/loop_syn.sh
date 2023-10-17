#/bin/bash
extract() {
	local value=$(echo "$1" | grep -E "$2.*$" | grep -Eo "([0-9]*[.])?[0-9]+")
	#[ -z "$value" ] && value=0
	echo $value
}

# loop by clk
echo "clk, area" > result.csv
for clk in $(seq 10.0 0.1 10.0)
do
	echo "create_clock -period $clk -name clk [get_ports clk]" > clk.sdc
	make syn
	area_log=$(< area.log)
	if grep -wq "VIOLATED" timing.log; then
		echo "period=		$clk: Timing violated, not record"
	else
		area=$(extract "$area_log" "Total cell area:")
		echo "period=		$clk: area:			$area"
		echo "$clk,$area" >> result.csv
	fi
done
