# AXI Stream VIPs

This repository contains an AXI Stream Source (acts as master) and an AXI Stream Sink (acts as slave) VIPs. These VIPs are written in SystemVerilog and can be used to verify the AXIS interfaces in a design. `file_tb` and `nofile_tb` show two ways of using the IPs

## AXIS Source

- Takes a queue of any length and sends it out as an AXI Stream
- Toggles `s_valid` with given probability
- Asserts `s_last` and `s_keep` accordingly
- Has tasks to generate random data, or read from existing files

## AXIS Sink

- Receives an AXI Stream and gives it as a queue
- Toggles `m_ready` with given probability
- Follows `m_last` and `m_keep` to read any length of data
- Has tasks to write queues to files

