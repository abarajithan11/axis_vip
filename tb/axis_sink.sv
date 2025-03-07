`timescale 1ns/1ps

module axis_sink #(
  parameter  WORD_W=8, BUS_W=32, PROB_READY=20,
             WORDS_PER_BEAT = BUS_W/WORD_W
)(
  input  logic clk, m_valid, m_last,
  output logic m_ready = 0,
  input  logic [WORDS_PER_BEAT-1:0] m_keep,
  input  logic [WORDS_PER_BEAT-1:0][WORD_W-1:0] m_data
);

  task automatic axis_pull_packet(output logic signed [WORD_W-1:0] packet [$]);
    
    int i_words = 0;
    bit done = 0;
    packet = {};

    // loop over beats
    while (!done) begin

      do begin 
        #1ps m_ready <= 0; // keep m_ready low with probability (1-PROB_READY)
        while ($urandom_range(0,99) >= PROB_READY) @(posedge clk);
        #1ps m_ready <= 1;
        @(posedge clk); // keep m_ready high for one cycle
      end while (!m_valid); // if m_valid is high, break out of loop
      
      // can sample everything
      done = m_last;
      for (int i=0; i<WORDS_PER_BEAT; i++) 
        if (m_keep[i]) begin
          packet.push_back(m_data[i]);
          i_words += 1;
        end
    end
  endtask

  task automatic write_queue_to_file (string filepath, input logic signed [WORD_W-1:0] q [$]);
    int fd;
    fd = $fopen(filepath, "w");
    if (fd == 0) $fatal(1, "Error opening file %s", filepath);
    foreach (q[i]) $fwrite(fd, "%d\n", q[i]);
    $fclose(fd);
  endtask
endmodule