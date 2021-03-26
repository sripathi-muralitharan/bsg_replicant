// Testbench for HammerParrot. Modelled after dpi-top.v in bigblade-vcs/hardware

/*
 * This testbench is structured like this where 
 * V = Vanilla Cores forming the compute array
 * M = Vcaches forming the memory system and connects to HBM memory
 * IO = I/O Complex with SPMD loader and monitor
 * BP = BlackParrot. 1 BlackParrot tile occupies 3 manycore tile locations
 * 00 = Tie offs
 *
 * [ IO ][ M ][ M ][ M ][ M ][ M ][ M ][ M ][ M ][ M ][ M ][ M ][ M ][ M ][ M ][ M ][ M ]
 * [ BP ][ V ][ V ][ V ][ V ][ V ][ V ][ V ][ V ][ V ][ V ][ V ][ V ][ V ][ V ][ V ][ v ]
 * [ BP ][ V ][ V ][ V ][ V ][ V ][ V ][ V ][ V ][ V ][ V ][ V ][ V ][ V ][ V ][ V ][ v ]
 * [ BP ][ V ][ V ][ V ][ V ][ V ][ V ][ V ][ V ][ V ][ V ][ V ][ V ][ V ][ V ][ V ][ v ]
 * [ 00 ][ V ][ V ][ V ][ V ][ V ][ V ][ V ][ V ][ V ][ V ][ V ][ V ][ V ][ V ][ V ][ v ]
 * [ 00 ][ V ][ V ][ V ][ V ][ V ][ V ][ V ][ V ][ V ][ V ][ V ][ V ][ V ][ V ][ V ][ v ]
 * [ 00 ][ V ][ V ][ V ][ V ][ V ][ V ][ V ][ V ][ V ][ V ][ V ][ V ][ V ][ V ][ V ][ v ]
 * [ 00 ][ V ][ V ][ V ][ V ][ V ][ V ][ V ][ V ][ V ][ V ][ V ][ V ][ V ][ V ][ V ][ v ]
 * [ 00 ][ V ][ V ][ V ][ V ][ V ][ V ][ V ][ V ][ V ][ V ][ V ][ V ][ V ][ V ][ V ][ v ]
 * [ 00 ][ M ][ M ][ M ][ M ][ M ][ M ][ M ][ M ][ M ][ M ][ M ][ M ][ M ][ M ][ M ][ M ]
 */

module hammerparrot_tb_top
 import cl_manycore_pkg::*;
 import bsg_manycore_pkg::*;
 import bsg_manycore_addr_pkg::*;
 import bsg_bladerunner_pkg::*;
 import bsg_bladerunner_mem_cfg_pkg::*;
 import bsg_manycore_endpoint_to_fifos_pkg::*;

 import bp_common_pkg::*;
 import bp_be_pkg::*;
 import bp_me_pkg::*;
 import bsg_noc_pkg::*;
 import bsg_wormhole_router_pkg::*;
 import bsg_tag_pkg::*;

 #(localparam bp_params_e bp_params_p = e_bp_bigblade_unicore_cfg
  `declare_bp_proc_params(bp_params_p)
  `declare_bp_bedrock_mem_if_widths(paddr_width_p, cce_block_width_p, lce_id_width_p, lce_assoc_p, cce))
  ();

  // Uncomment this to enable VCD Dumping
   /*
   initial begin
      $display("[%0t] Tracing to vlt_dump.vcd...\n", $time);
      $dumpfile("dump.vcd");
      $dumpvars();
   end
    */
  initial begin
    #0;
    
    $display("==================== BSG MACHINE SETTINGS: ====================");

    $display("[INFO][TESTBENCH] bsg_machine_pods_x_gp                 = %d", bsg_machine_pods_x_gp);
    $display("[INFO][TESTBENCH] bsg_machine_pods_y_gp                 = %d", bsg_machine_pods_y_gp);

    $display("[INFO][TESTBENCH] bsg_machine_pod_tiles_x_gp            = %d", bsg_machine_pod_tiles_x_gp);
    $display("[INFO][TESTBENCH] bsg_machine_pod_tiles_y_gp            = %d", bsg_machine_pod_tiles_y_gp);
    $display("[INFO][TESTBENCH] bsg_machine_pod_tiles_subarray_x_gp   = %d", bsg_machine_pod_tiles_subarray_x_gp);
    $display("[INFO][TESTBENCH] bsg_machine_pod_tiles_subarray_y_gp   = %d", bsg_machine_pod_tiles_subarray_y_gp);
    $display("[INFO][TESTBENCH] bsg_machine_pod_llcaches_gp           = %d", bsg_machine_pod_llcaches_gp);

    $display("[INFO][TESTBENCH] bsg_machine_noc_cfg_gp                = %s", bsg_machine_noc_cfg_gp.name());
    $display("[INFO][TESTBENCH] bsg_machine_noc_ruche_factor_X_gp     = %d", bsg_machine_noc_ruche_factor_X_gp);

    $display("[INFO][TESTBENCH] bsg_machine_noc_epa_width_gp          = %d", bsg_machine_noc_epa_width_gp);
    $display("[INFO][TESTBENCH] bsg_machine_noc_data_width_gp         = %d", bsg_machine_noc_data_width_gp);
    $display("[INFO][TESTBENCH] bsg_machine_noc_coord_x_width_gp      = %d", bsg_machine_noc_coord_x_width_gp);
    $display("[INFO][TESTBENCH] bsg_machine_noc_coord_y_width_gp      = %d", bsg_machine_noc_coord_y_width_gp);
    $display("[INFO][TESTBENCH] bsg_machine_noc_pod_coord_x_width_gp  = %d", bsg_machine_noc_pod_coord_x_width_gp);
    $display("[INFO][TESTBENCH] bsg_machine_noc_pod_coord_y_width_gp  = %d", bsg_machine_noc_pod_coord_y_width_gp);

    $display("[INFO][TESTBENCH] bsg_machine_llcache_sets_gp           = %d", bsg_machine_llcache_sets_gp);
    $display("[INFO][TESTBENCH] bsg_machine_llcache_ways_gp           = %d", bsg_machine_llcache_ways_gp);
    $display("[INFO][TESTBENCH] bsg_machine_llcache_line_words_gp     = %d", bsg_machine_llcache_line_words_gp);
    $display("[INFO][TESTBENCH] bsg_machine_llcache_words_gp          = %d", bsg_machine_llcache_words_gp);
    $display("[INFO][TESTBENCH] bsg_machine_llcache_miss_fifo_els_gp  = %d", bsg_machine_llcache_miss_fifo_els_gp);
    $display("[INFO][TESTBENCH] bsg_machine_llcache_channel_width_gp  = %d", bsg_machine_llcache_channel_width_gp);

    $display("[INFO][TESTBENCH] bsg_machine_dram_bank_words_gp        = %d", bsg_machine_dram_bank_words_gp);
    $display("[INFO][TESTBENCH] bsg_machine_dram_channels_gp          = %d", bsg_machine_dram_channels_gp);
    $display("[INFO][TESTBENCH] bsg_machine_dram_words_gp             = %d", bsg_machine_dram_words_gp);
    $display("[INFO][TESTBENCH] bsg_machine_dram_cfg_gp               = %s", bsg_machine_dram_cfg_gp.name());

    $display("[INFO][TESTBENCH] bsg_machine_io_coord_x_gp             = %d", bsg_machine_io_coord_x_gp);
    $display("[INFO][TESTBENCH] bsg_machine_io_coord_y_gp             = %d", bsg_machine_io_coord_y_gp);

    $display("[INFO][TESTBENCH] bsg_machine_enable_vcore_profiling_lp = %d", bsg_machine_enable_vcore_profiling_lp);
    $display("[INFO][TESTBENCH] bsg_machine_enable_router_profiling_lp= %d", bsg_machine_enable_router_profiling_lp);
    $display("[INFO][TESTBENCH] bsg_machine_enable_cache_profiling_lp = %d", bsg_machine_enable_cache_profiling_lp);

    $display("[INFO][TESTBENCH] bsg_machine_name_gp                   = %s", bsg_machine_name_gp);
  end

  localparam bsg_machine_llcache_data_width_lp = bsg_machine_noc_data_width_gp;
  localparam bsg_machine_llcache_addr_width_lp=(bsg_machine_noc_epa_width_gp-1+`BSG_SAFE_CLOG2(bsg_machine_noc_data_width_gp>>3));

  localparam bsg_machine_wh_flit_width_lp = bsg_machine_llcache_channel_width_gp;
  localparam bsg_machine_wh_ruche_factor_lp = 2;
  localparam bsg_machine_wh_cid_width_lp = `BSG_SAFE_CLOG2(bsg_machine_wh_ruche_factor_lp*2);
  localparam bsg_machine_wh_len_width_lp = `BSG_SAFE_CLOG2(1 + ((bsg_machine_llcache_line_words_gp * bsg_machine_llcache_data_width_lp) / bsg_machine_llcache_channel_width_gp));
  localparam bsg_machine_wh_coord_width_lp = bsg_machine_noc_coord_x_width_gp;

// These are macros... for reasons. 
`ifndef BSG_MACHINE_DISABLE_VCORE_PROFILING
  localparam bsg_machine_enable_vcore_profiling_lp = 1;
`else
  localparam bsg_machine_enable_vcore_profiling_lp = 0;
`endif

`ifndef BSG_MACHINE_DISABLE_ROUTER_PROFILING
  localparam bsg_machine_enable_router_profiling_lp = 1;
`else
  localparam bsg_machine_enable_router_profiling_lp = 0;
`endif

`ifndef BSG_MACHINE_DISABLE_CACHE_PROFILING
  localparam bsg_machine_enable_cache_profiling_lp = 1;
`else
  localparam bsg_machine_enable_cache_profiling_lp = 0;
`endif

  // Clock generator period
  localparam lc_cycle_time_ps_lp = 1000;

  // Reset generator depth
  localparam reset_depth_lp = 3;

  // Global Counter for Profilers, Tracing, Debugging
  localparam global_counter_width_lp = 64;
  logic [global_counter_width_lp-1:0] global_ctr;

  logic host_clk;
  logic host_reset;

  // bsg_nonsynth_clock_gen and bsg_nonsynth_reset_gen BOTH have bit
  // inputs and outputs (they're non-synthesizable). Casting between
  // logic and bit can produce unexpected edges as logic types switch
  // from X to 0/1 at Time 0 in simulation. This means that the input
  // and outputs of both modules must have type bit, AND the wires
  // between them. Therefore, we use bit_clk and bit_reset for the
  // inputs/outputs of these modules to avoid unexpected
  // negative/positive edges and other modules can choose between bit
  // version (for non-synthesizable modules) and the logic version
  // (otherwise).
  bit   bit_clk;
  bit   bit_reset;
  logic core_clk;
  logic core_reset;

  // reset_done is deasserted when tag programming is done.
  logic core_reset_done_lo, core_reset_done_r;

  logic mem_clk;
  logic mem_reset;

  logic cache_clk;
  logic cache_reset;

  // Snoop wires for Print Stat
  logic                                       print_stat_v;
  logic [bsg_machine_noc_data_width_gp-1:0]   print_stat_tag;

  logic [bsg_machine_noc_coord_x_width_gp-1:0] host_x_coord_li = (bsg_machine_noc_coord_x_width_gp)'(bsg_machine_io_coord_x_gp);
  logic [bsg_machine_noc_coord_y_width_gp-1:0] host_y_coord_li = (bsg_machine_noc_coord_y_width_gp)'(bsg_machine_io_coord_y_gp);

  `declare_bsg_manycore_link_sif_s(bsg_machine_noc_epa_width_gp, bsg_machine_noc_data_width_gp, bsg_machine_noc_coord_x_width_gp, bsg_machine_noc_coord_y_width_gp);

  bsg_manycore_link_sif_s host_link_sif_li;
  bsg_manycore_link_sif_s host_link_sif_lo;

  // Trace Enable wire for runtime argument to enable tracing (+trace)
  logic                                        trace_en;
  logic                                        log_en;
  logic                                        dpi_trace_en;
  logic                                        dpi_log_en;
  logic                                        tag_done_lo;
  assign trace_en = dpi_trace_en;
  assign log_en = dpi_log_en;

  // -Verilator uses a clock generator that is controlled by C/C++
  // (bsg_nonsynth_dpi_clock_gen), whereas VCS uses the normal
  // nonsynthesizable clock generator (bsg_nonsynth_clock_gen)
`ifdef VERILATOR
  bsg_nonsynth_dpi_clock_gen
`else
  bsg_nonsynth_clock_gen
`endif
    #(.cycle_time_p(lc_cycle_time_ps_lp))
  core_clk_gen
    (.o(bit_clk));
  assign core_clk = bit_clk;

  bsg_nonsynth_reset_gen
    #(.num_clocks_p(1)
      ,.reset_cycles_lo_p(0)
      ,.reset_cycles_hi_p(16)
      )
  reset_gen
    (.clk_i(bit_clk)
    ,.async_reset_o(bit_reset)
    );
  assign core_reset = bit_reset;

  bsg_nonsynth_dpi_gpio
     #(
       .width_p(2)
       ,.init_o_p('0)
       ,.use_output_p('1)
       ,.debug_p('1)
       )
   trace_control
     (.gpio_o({dpi_log_en, dpi_trace_en})
      ,.gpio_i('0)
      );

  // BlackParrot Tag master
  bsg_tag_s [2:0] bp_tag_lo;
  logic bp_tag_done_lo;
  bp_nonsynth_tag_master
    bp_tag_master
    (.clk_i(core_clk)
    ,.tag_done_o(bp_tag_done_lo)
    ,.reset_i(core_reset)
    ,.bsg_tag_o(bp_tag_lo)
    );

  // Manycore Tag master
  logic mc_tag_done_lo;
  bsg_tag_s [bsg_machine_pods_y_gp-1:0][bsg_machine_pods_x_gp-1:0] pod_tags_lo;
  bsg_tag_s [bsg_machine_pods_x_gp-1:0] io_tags_lo;
  bsg_nonsynth_manycore_tag_master
    #(.num_pods_x_p(bsg_machine_pods_x_gp)
     ,.num_pods_y_p(bsg_machine_pods_y_gp)
     ,.wh_cord_width_p(bsg_machine_wh_cord_width_lp)
     ) 
    mtm
    (.clk_i(clk_i)
    ,.reset_i(reset_i)
    
    ,.tag_done_o(mc_tag_done_lo)
    ,.pod_tags_o(pod_tags_lo)
    ,.io_tags_o(io_tags_lo)
    );

  assign core_reset_done_lo = bp_tag_done_lo & mc_tag_done_lo;

  bsg_dff_chain
    #(.width_p(1)
     ,.num_stages_p(reset_depth_lp)
     )
    reset_dff
     (.clk_i(core_clk)
     ,.data_i(core_reset_done_lo)
     ,.data_o(core_reset_done_r)
     );
  
  // BlackParrot Tile --> At coordinates (0, 1) [HOST], (0, 2) [DRAM 1], (0, 3) [DRAM 2]
  `declare_bp_bedrock_mem_if(paddr_width_p, cce_block_width_p, lce_id_width_p, lce_assoc_p, cce);
  bsg_manycore_link_sif_s [2:0][E:E] mc_hor_links_li, mc_hor_links_lo;
  
  wire bp_clk = core_clk;
  wire bp_reset = core_reset;

  bp_unicore_tile
    #(.bp_params_p(bp_params_p))
    blackparrot
     (.clk_i(bp_clk)
     ,.reset_i(bp_reset | ~bp_tag_done_lo)

     ,.bsg_tag_i(bp_tag_lo)

     ,.links_i(mc_hor_links_li)
     ,.links_o(mc_hor_links_lo)
     );

  // I/O Complex --> At coordinates (0, 0)
  bsg_nonsynth_manycore_io_complex
   #(.addr_width_p(mc_addr_width_gp)
     ,.data_width_p(mc_data_width_gp)
     ,.x_cord_width_p(mc_x_cord_width_gp)
     ,.y_cord_width_p(mc_y_cord_width_gp)
     ,.io_x_cord_p(0)
     ,.io_y_cord_p(0)
     )
   io
    (.clk_i(blackparrot_clk)
     ,.reset_i(blackparrot_reset | ~tr_done_lo)

     ,.io_link_sif_i(link_out[0][0])
     ,.io_link_sif_o(link_in[0][0])
     ,.print_stat_v_o()
     ,.print_stat_tag_o()
     ,.loader_done_o()
     );

  // BP <--> Fake network connections
  // mc_hor_link[0] = I/O
  // mc_hor_link[1] = DRAM 1
  // mc_hor_link[2] = DRAM 2
  for (genvar i = 1; i <= 3; i++)
    begin : bp_connect
      assign link_in[i][0] = mc_hor_links_lo[i-1];
      assign mc_hor_links_li[i-1] = link_out[i][0];
    end

  // Tie off all links below BP
  for (genvar i = 4; i <= mc_num_tiles_y_gp+1; i++)
    begin : bp_tieoff
      assign link_in[i][0] = '0;
    end

  // Tie off where the manycore would be
  for (genvar i = 1; i <= mc_num_tiles_y_gp; i++)
    begin : tile_stubs_y
      for (genvar j = 1; j <= mc_num_tiles_x_gp; j++)
        begin : tile_stubs_x
          assign link_in[i][j] = '0;
        end
    end

  // Connect infinite memories where the caches would be
  for (genvar i = N; i <= S; i++)
    begin : mem_row
      for (genvar j = 1; j <= mc_num_tiles_x_gp; j++)
        begin : mem_col
          localparam x_idx_lp = j;
          localparam y_idx_lp = (i == S) ? mc_num_tiles_y_gp+1 : 0;
          wire [mc_x_cord_width_gp-1:0] my_x_li = x_idx_lp;
          wire [mc_y_cord_width_gp-1:0] my_y_li = y_idx_lp;

          bsg_nonsynth_mem_infinite
           #(.data_width_p(mc_data_width_gp)
             ,.addr_width_p(mc_addr_width_gp)
             ,.x_cord_width_p(mc_x_cord_width_gp)
             ,.y_cord_width_p(mc_y_cord_width_gp)
             ,.id_p(i*mc_num_tiles_x_gp+j)
             ,.mem_els_p(2**25)
             )
           mem_inf
            (.clk_i(blackparrot_clk)
             ,.reset_i(blackparrot_reset | ~tr_done_lo)

             ,.link_sif_i(link_out[y_idx_lp][x_idx_lp])
             ,.link_sif_o(link_in[y_idx_lp][x_idx_lp])

             ,.my_x_i(my_x_li)
             ,.my_y_i(my_y_li)
             );
        end
    end

endmodule
