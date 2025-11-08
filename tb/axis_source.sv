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

  // Register outputs on posedge to avoid race conditions
  logic s_valid_d, s_last_d;
  logic [WORDS_PER_BEAT-1:0]                s_keep_d;
  logic [WORDS_PER_BEAT-1:0][WORD_W-1:0]    s_data_d;

  always_ff @(posedge clk) begin
    s_valid <= s_valid_d;
    s_last  <= s_last_d;
    s_keep  <= s_keep_d;
    s_data  <= s_data_d;
  end

  task automatic axis_push_packet(input logic signed [WORD_W-1:0] packet [$]);
    int total_words = packet.size();
    int n_beats = `CEIL(total_words, WORDS_PER_BEAT);
    int i_words = 0;

    // Between beats: keep outputs deasserted in the next cycle
    s_valid_d = 0; s_last_d = 0; s_keep_d = '0; s_data_d = 'x;

    for (int ib=0; ib < n_beats; ib++) begin
      // random idle cycles before we start the next beat
      while ($urandom_range(0,99) >= PROB_VALID) @(posedge clk);

      // Prepare the beat for the *next* cycle
      s_valid_d = 1;
      s_last_d  = (ib == n_beats-1);
      for (int i=0; i<WORDS_PER_BEAT; i++) begin
        if (i_words < total_words) begin
          s_data_d[i] = packet[i_words];
          s_keep_d[i] = 1;
          i_words++;
        end else begin
          s_data_d[i] = 'x;
          s_keep_d[i] = 0;
        end
      end

      // Wait until handshake occurs at a posedge (ready==1 while we hold valid)
      @(posedge clk); // first cycle the beat becomes visible
      while (!s_ready) @(posedge clk);

      // Transfer happened at the last posedge; deassert for the next cycle
      s_valid_d = 0;
      s_keep_d  = '0;
      s_data_d  = 'x;
      s_last_d  = 0;
      // (optional idle cycles will be inserted by the next PROB_VALID loop)
    end
  endtask

  task automatic read_file_to_queue (string filepath, output logic signed [WORD_W-1:0] q [$]);
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

  task automatic get_random_queue (output logic signed [WORD_W-1:0] q [$], input int n_words);
    q = {};
    repeat(n_words) q.push_back(WORD_W'($urandom_range(0,2**WORD_W-1)));
  endtask

endmodule
