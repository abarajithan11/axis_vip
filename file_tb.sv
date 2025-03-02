`timescale 1ns/1ps

module file_tb;
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
  packet_t tx_packet, rx_packet, temp, exp;
  string path_tx, path_rx;
  int n_words;

  initial begin
    $dumpfile ("dump.vcd"); $dumpvars;
    repeat(5) @(posedge clk);
    rstn <= 1;

    for (int n=0; n<NUM_EXP; n++) begin
      n_words = $urandom_range(1, 100);

      path_tx = $sformatf("tx_%0d.txt", n);
      // Prepare a random file
      source.get_random_queue(temp, n_words);
      sink.write_queue_to_file(path_tx, temp);
      // Read the file back & push
      source.read_file_to_queue(path_tx, tx_packet);
      source.axis_push_packet(tx_packet);
    end
  end

  initial begin
    $display("Waiting for packets to be received...");
    for (int n=0; n<NUM_EXP; n++) begin

      path_rx = $sformatf("rx_%0d.txt", n);

      sink.axis_pull_packet(rx_packet);
      sink.write_queue_to_file(path_rx, rx_packet);

      source.read_file_to_queue(path_tx, exp);
      if(exp == rx_packet)
        $display("Packet[%0d]: Outputs match: %p\n", n, rx_packet);
      else begin
        $display("Packet[%0d]: Expected: \n%p \n != \n Received: \n%p", n, exp, rx_packet);
        $fatal(1, "Failed");
      end
    end
    $finish();
  end
endmodule