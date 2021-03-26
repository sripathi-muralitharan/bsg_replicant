/*
 * bp_nonsynth_tag_master
 * 
 * This module consolidates all tag master related logic. Takes inspiration
 * from the manycore counterpart
 *
 */

module bp_nonsynth_tag_master
  import bsg_tag_pkg::*;
  import bsg_noc_pkg::*;
  #()
  ( input clk_i
  , input reset_i

  // done signal for peripherals
  , output tag_done_o
  , output  bsg_tag_s [2:0] bsg_tags_o
  );

  // There are only three clients - 1 host link and 2 dram links
  localparam num_clients_lp = 3;
  localparam payload_width_lp = 7;
  localparam max_payload_width_lp = 10;
  localparam lg_payload_width_lp = `BSG_WIDTH(max_payload_width_lp);
  localparam rom_data_width_lp = 4+1+`BSG_SAFE_CLOG2(num_clients_lp)+1+lg_payload_width_lp+max_payload_width_lp;
  localparam rom_addr_width_lp = 12;

  // BSG TAG trace replay
  logic tr_valid_lo, tr_data_lo, tr_done_lo;
  logic [rom_data_width_lp-1:0] rom_data;
  logic [rom_addr_width_lp-1:0] rom_addr;

  bsg_tag_trace_replay
   #(.rom_addr_width_p(rom_addr_width_lp)
    ,.rom_data_width_p(rom_data_width_lp)
    ,.num_clients_p(num_clients_lp)
    ,.max_payload_width_p(max_payload_width_lp)
    )
   tr
    (.clk_i(blackparrot_clk)
    ,.reset_i(blackparrot_reset)
    ,.en_i(1'b1)

    ,.rom_addr_o(rom_addr)
    ,.rom_data_i(rom_data)

    ,.valid_i(1'b0)
    ,.data_i('0)
    ,.ready_o()

    ,.valid_o(tr_valid_lo)
    ,.en_r_o()
    ,.tag_data_o(tr_data_lo)
    ,.yumi_i(tr_valid_lo)
     
    ,.done_o(tag_done_o)
    ,.error_o()
    ); 

  // BSG TAG boot rom
  bsg_nonsynth_test_rom
   #(.filename_p("trace.tr")
    ,.data_width_p(rom_data_width_lp)
    ,.addr_width_p(rom_addr_width_lp)
    )
   rom
    (.addr_i(rom_addr)
    ,.data_o(rom_data)
    );

  // BSG TAG MASTER
  bsg_tag_s [2:0] bsg_tag_li;
  bsg_tag_master
   #(.els_p(num_clients_lp), .lg_width_p(lg_payload_width_lp))
   btm
    (.clk_i(blackparrot_clk)
    ,.data_i(tr_valid_lo & tr_data_lo)
    ,.en_i(1'b1)
    ,.clients_r_o(bsg_tag_li)
    );

endmodule