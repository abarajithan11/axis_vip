file: tb/file_tb.sv tb/axis_source.sv tb/axis_sink.sv
	mkdir -p build
	verilator --binary -j 0 -O3 --trace --top file_tb -Mdir build/ $^ --Wno-INITIALDLY
	mkdir -p run
	@cd run && ../build/Vfile_tb

nofile: tb/nofile_tb.sv tb/axis_source.sv tb/axis_sink.sv
	mkdir -p build
	verilator --binary -j 0 -O3 --trace --top nofile_tb -Mdir build/ $^ --Wno-INITIALDLY -DFILE_TEST
	mkdir -p run
	@cd run && ../build/Vnofile_tb

clean:
	rm -rf build run

all: file nofile