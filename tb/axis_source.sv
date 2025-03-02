`timescale 1ns/1ps
`define CEIL(a, b) (((a) + (b) - 1) / (b))

module axis_source #(
  parameter  WORD_W=8, BUS_W=8, PROB_VALID=20,
  localparam WORDS_PER_BEAT = BUS_W/WORD_W
)(
  input  logic clk, s_ready,
  output logic s_valid = 0, s_last = 0,
  output logic [WORDS_PER_BEAT-1:0] s_keep = '0,
  output logic [WORDS_PER_BEAT-1:0][WORD_W-1:0] s_data = 'x
);
  task automatic axis_push_packet(input logic [WORD_W-1:0] packet [$]);

    int total_words = packet.size();
    int n_beats = `CEIL(total_words, WORDS_PER_BEAT);
    int i_words = 0;

    for (int ib=0; ib < n_beats; ib++) begin
       // randomize s_valid and wait
      while ($urandom_range(0,99) >= PROB_VALID) @(posedge clk);

      #1ps; // V_erilator wants delays
      s_valid <= 1;
      s_last  <= ib == n_beats-1;

      for (int i=0; i<WORDS_PER_BEAT; i++) 
        if (i_words < total_words) begin
          s_data[i] <= packet[i_words];
          s_keep[i] <= 1;
          i_words += 1;
        end else begin
          s_data[i] <= 'x;
          s_keep[i] <= 0;
        end

      do @(posedge clk); while (!s_ready); // wait for s_data to be accepted
      
      #1ps;
      // clear s_valid and s_data
      s_valid <= 0;
      s_data  <= 'x;
    end
  endtask

  task automatic read_file_to_queue (string filepath, output [WORD_W-1:0] q [$]);
    int fd, status;
    logic signed [WORD_W-1:0] val;
    q = {};

    fd = $fopen(filepath, "r");
    if (fd == 0) $fatal(1, "Error opening file %s", filepath);

    while (!$feof(fd)) begin
      status = $fscanf(fd,"%d\n", val);
      q.push_back(val);
    end
    $fclose(fd);
  endtask

  task automatic get_random_queue (output logic [WORD_W-1:0] q [$], input int n_words);
    q = {};
    repeat(n_words) q.push_back(WORD_W'($urandom_range(0,2**WORD_W-1)));
  endtask

endmodule
