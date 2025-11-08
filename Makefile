file: tb/file_tb.sv tb/axis_source.sv tb/axis_sink.sv
	mkdir -p build
	verilator --binary -j 0 -O3 --trace --top file_tb -Mdir build/ $^
	mkdir -p run
	@cd run && ../build/Vfile_tb

nofile: tb/nofile_tb.sv tb/axis_source.sv tb/axis_sink.sv
	mkdir -p build
	verilator --binary -j 0 -O3 --trace --top nofile_tb -Mdir build/ $^ -DFILE_TEST
	mkdir -p run
	@cd run && ../build/Vnofile_tb

file_xsim:
	echo "log_wave -recursive *; run all; exit" > run/cfg.tcl
	@cd run && xvlog --sv $^ ../tb/file_tb.sv ../tb/axis_source.sv ../tb/axis_sink.sv
	@cd run && xelab file_tb --debug typical --snapshot file_tb
	@cd run && mkdir -p run
	@cd run && xsim file_tb --tclbatch cfg.tcl

nofile_xsim: 
	echo "log_wave -recursive *; run all; exit" > run/cfg.tcl
	@cd run && xvlog --sv ../tb/nofile_tb.sv ../tb/axis_source.sv ../tb/axis_sink.sv
	@cd run && xelab nofile_tb --debug typical --snapshot nofile_tb
	@cd run && mkdir -p run
	@cd run && xsim nofile_tb --tclbatch cfg.tcl

clean:
	rm -rf build run

all: file nofile

all_xsim: file_xsim nofile_xsim
