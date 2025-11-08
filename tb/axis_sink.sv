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

  // Register ready to prevent races
  logic m_ready_d;
  always_ff @(posedge clk) begin
    m_ready <= m_ready_d;
  end

  task automatic axis_pull_packet(output logic signed [WORD_W-1:0] packet [$]);
    int i_words = 0;
    bit done = 0;
    packet = {};

    // We’ll assert ready for whole cycles; sampling happens at posedge
    while (!done) begin
      // Insert random backpressure cycles with ready low
      m_ready_d = 0;
      while ($urandom_range(0,99) >= PROB_READY) @(posedge clk);

      // Arm ready for the *next* cycle
      m_ready_d = 1;

      // At each posedge: if m_valid==1, a beat is accepted
      @(posedge clk);
      if (m_valid) begin
        // Consume this beat (accepted at this posedge)
        done = m_last;
        for (int i=0; i<WORDS_PER_BEAT; i++) begin
          if (m_keep[i]) begin
            packet.push_back(m_data[i]);
            i_words++;
          end
        end
        // Optionally drop ready after one beat; or keep it high to stream
        m_ready_d = 0;  // one-beat-at-a-time policy (keeps behavior similar to your TB)
      end
      // else: keep ready_d as is (0 or 1) depending on desired backpressure policy
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