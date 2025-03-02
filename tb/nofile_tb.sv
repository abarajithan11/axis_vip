`timescale 1ns/1ps

module nofile_tb;
  localparam  WORD_W=8, BUS_W=32,
              WORDS_PER_BEAT=BUS_W/WORD_W,
              PROB_VALID=1, PROB_READY=10,
              CLK_PERIOD=10, NUM_EXP=20;

  logic clk=0, rstn=0;
  initial forever #(CLK_PERIOD/2) clk = ~clk;

  logic s_valid, s_ready, m_valid, m_ready, s_last, m_last;
  logic [WORDS_PER_BEAT-1:0] s_keep, m_keep;
  logic [WORDS_PER_BEAT-1:0][WORD_W-1:0] s_data, m_data;
  axis_source #(.WORD_W(WORD_W), .BUS_W(BUS_W), .PROB_VALID(PROB_VALID)) source (.*);
  axis_sink   #(.WORD_W(WORD_W), .BUS_W(BUS_W), .PROB_READY(PROB_READY)) sink   (.*);
  assign {s_ready, m_valid, m_data, m_keep, m_last} = {m_ready, s_valid, s_data, s_keep, s_last};

  typedef logic [WORD_W-1:0] packet_t [$];

  packet_t tx_packets [NUM_EXP], rx_packets [NUM_EXP];
  int n_words;

  initial begin
    $dumpfile ("dump.vcd"); $dumpvars;
    repeat(5) @(posedge clk);
    rstn <= 1;

    for (int n=0; n<NUM_EXP; n++) begin
      n_words = $urandom_range(1, 100);
      source.get_random_queue(tx_packets[n], n_words);
      source.axis_push_packet(tx_packets[n]);
    end
  end

  initial begin
    $display("Waiting for packets to be received...");
    for (int n=0; n<NUM_EXP; n++) begin
      sink.axis_pull_packet(rx_packets[n]);
      if(rx_packets[n] == tx_packets[n])
        $display("Packet[%0d]: Outputs match: %p\n", n, rx_packets[n]);
      else begin
        $display("Packet[%0d]: Expected: \n%p \n != \n Received: \n%p", n, tx_packets[n], rx_packets[n]);
        $fatal(1, "Failed");
      end
    end
    $finish();
  end
endmodule