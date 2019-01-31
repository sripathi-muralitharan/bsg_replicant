/**
 *  axil_to_mcl.v
 *
 */

`include "bsg_axi_bus_pkg.vh"

module axil_to_mcl #(
  mcl_intf_num_p="inv"
  ,fifo_width_p="inv") (
  input                                     clk_i         ,
  input                                     reset_i       ,
  // axil signals
  input                                     s_axil_mcl_awvalid,
  input  [                            31:0] s_axil_mcl_awaddr ,
  output                                    s_axil_mcl_awready,
  input                                     s_axil_mcl_wvalid ,
  input  [                            31:0] s_axil_mcl_wdata  ,
  input  [                             3:0] s_axil_mcl_wstrb  ,
  output                                    s_axil_mcl_wready ,
  output [                             1:0] s_axil_mcl_bresp  ,
  output                                    s_axil_mcl_bvalid ,
  input                                     s_axil_mcl_bready ,
  input  [                            31:0] s_axil_mcl_araddr ,
  input                                     s_axil_mcl_arvalid,
  output                                    s_axil_mcl_arready,
  output [                            31:0] s_axil_mcl_rdata  ,
  output [                             1:0] s_axil_mcl_rresp  ,
  output                                    s_axil_mcl_rvalid ,
  input                                     s_axil_mcl_rready ,
  // from mcl signals
  input  [              mcl_intf_num_p-1:0] mcl_v_i
  ,input  [(mcl_intf_num_p*fifo_width_p)-1:0] mcl_data_i
  ,output [              mcl_intf_num_p-1:0] mcl_yumi_o
  // to mcl slave
  ,output [              mcl_intf_num_p-1:0] mcl_v_o
  ,output [(mcl_intf_num_p*fifo_width_p)-1:0] mcl_data_o
  ,input  [              mcl_intf_num_p-1:0] mcl_ready_i
);

parameter axil_mosi_bus_width_lp = `bsg_axil_mosi_bus_width(1);
parameter axil_miso_bus_width_lp = `bsg_axil_miso_bus_width(1);

`declare_bsg_axil_bus_s(1, bsg_axil_mosi_bus_s, bsg_axil_miso_bus_s);
bsg_axil_mosi_bus_s s0_axil_bus_i_cast;
bsg_axil_miso_bus_s s0_axil_bus_o_cast;

assign s0_axil_bus_i_cast.awvalid = s_axil_mcl_awvalid;
assign s0_axil_bus_i_cast.awaddr  = s_axil_mcl_awaddr;
assign s_axil_mcl_awready             = s0_axil_bus_o_cast.awready;

assign s0_axil_bus_i_cast.wvalid = s_axil_mcl_wvalid;
assign s0_axil_bus_i_cast.wdata  = s_axil_mcl_wdata;
assign s0_axil_bus_i_cast.wstrb  = s_axil_mcl_wstrb;
assign s_axil_mcl_wready             = s0_axil_bus_o_cast.wready;

assign s_axil_mcl_bresp              = s0_axil_bus_o_cast.bresp;
assign s_axil_mcl_bvalid             = s0_axil_bus_o_cast.bvalid;
assign s0_axil_bus_i_cast.bready = s_axil_mcl_bready;

assign s0_axil_bus_i_cast.araddr  = s_axil_mcl_araddr;
assign s0_axil_bus_i_cast.arvalid = s_axil_mcl_arvalid;
assign s_axil_mcl_arready             = s0_axil_bus_o_cast.arready;

assign s_axil_mcl_rdata              = s0_axil_bus_o_cast.rdata;
assign s_axil_mcl_rresp              = s0_axil_bus_o_cast.rresp;
assign s_axil_mcl_rvalid             = s0_axil_bus_o_cast.rvalid;
assign s0_axil_bus_i_cast.rready = s_axil_mcl_rready;


`declare_bsg_axil_bus_s(mcl_intf_num_p, bsg_axil_mosi_busN_s, bsg_axil_miso_busN_s);
bsg_axil_mosi_busN_s axil_mosi_busN;
bsg_axil_miso_busN_s axil_miso_busN;


//-------------------------------------------------
// TODO: find a way to avoid this list
// crossbar, support 1 to [1:16] now
localparam BASE_ADDRESS_LIST = {
  64'h00000000_00000F00, 64'h00000000_00000E00, 64'h00000000_00000D00 ,64'h00000000_00000C00,
  64'h00000000_00000B00, 64'h00000000_00000A00, 64'h00000000_00000900 ,64'h00000000_00000fifo_width_p0,
  64'h00000000_00000700, 64'h00000000_00000600, 64'h00000000_00000500, 64'h00000000_00000400, 
  64'h00000000_00000300, 64'h00000000_00000200, 64'h00000000_00000100, 64'h00000000_00000000};
localparam C_NUM_MASTER_SLOTS = mcl_intf_num_p;
localparam C_M_AXI_BASE_ADDR  = BASE_ADDRESS_LIST[64*C_NUM_MASTER_SLOTS-1:0];
localparam C_M_AXI_ADDR_WIDTH         = {C_NUM_MASTER_SLOTS{32'h0000_0008}};
localparam C_M_AXI_WRITE_CONNECTIVITY = {C_NUM_MASTER_SLOTS{32'h0000_0001}};
localparam C_M_AXI_READ_CONNECTIVITY  = {C_NUM_MASTER_SLOTS{32'h0000_0001}};
localparam C_M_AXI_WRITE_ISSUING      = {C_NUM_MASTER_SLOTS{32'h0000_0001}};
localparam C_M_AXI_READ_ISSUING       = {C_NUM_MASTER_SLOTS{32'h0000_0001}};
localparam C_M_AXI_SECURE             = {C_NUM_MASTER_SLOTS{32'h0000_0000}};

axi_crossbar_v2_1_18_axi_crossbar #(
  .C_FAMILY                   ("virtexuplus"             ),
  .C_NUM_SLAVE_SLOTS          (1                         ),
  .C_NUM_MASTER_SLOTS         (C_NUM_MASTER_SLOTS        ),
  .C_AXI_ID_WIDTH             (1                         ),
  .C_AXI_ADDR_WIDTH           (32                        ),
  .C_AXI_DATA_WIDTH           (32                        ),
  .C_AXI_PROTOCOL             (2                         ),
  .C_NUM_ADDR_RANGES          (1                         ),
  .C_M_AXI_BASE_ADDR          (C_M_AXI_BASE_ADDR         ),
  .C_M_AXI_ADDR_WIDTH         (C_M_AXI_ADDR_WIDTH        ),
  .C_S_AXI_BASE_ID            (32'H00000000              ),
  .C_S_AXI_THREAD_ID_WIDTH    (32'H00000000              ),
  .C_AXI_SUPPORTS_USER_SIGNALS(0                         ),
  .C_AXI_AWUSER_WIDTH         (1                         ),
  .C_AXI_ARUSER_WIDTH         (1                         ),
  .C_AXI_WUSER_WIDTH          (1                         ),
  .C_AXI_RUSER_WIDTH          (1                         ),
  .C_AXI_BUSER_WIDTH          (1                         ),
  .C_M_AXI_WRITE_CONNECTIVITY (C_M_AXI_WRITE_CONNECTIVITY),
  .C_M_AXI_READ_CONNECTIVITY  (C_M_AXI_READ_CONNECTIVITY ),
  .C_R_REGISTER               (1                         ),
  .C_S_AXI_SINGLE_THREAD      (32'H00000001              ),
  .C_S_AXI_WRITE_ACCEPTANCE   (32'H00000001              ),
  .C_S_AXI_READ_ACCEPTANCE    (32'H00000001              ),
  .C_M_AXI_WRITE_ISSUING      (C_M_AXI_WRITE_ISSUING     ),
  .C_M_AXI_READ_ISSUING       (C_M_AXI_READ_ISSUING      ),
  .C_S_AXI_ARB_PRIORITY       (32'H00000000              ),
  .C_M_AXI_SECURE             (C_M_AXI_SECURE            ),
  .C_CONNECTIVITY_MODE        (0                         )
) axil_crossbar_mux (
  .aclk          (clk_i                     ),
  .aresetn       (~reset_i                  ),
  .s_axi_awid    (1'H0                      ),
  .s_axi_awaddr  (s0_axil_bus_i_cast.awaddr ),
  .s_axi_awlen   (8'H00                     ),
  .s_axi_awsize  (3'H0                      ),
  .s_axi_awburst (2'H0                      ),
  .s_axi_awlock  (1'H0                      ),
  .s_axi_awcache (4'H0                      ),
  .s_axi_awprot  (3'H0                      ),
  .s_axi_awqos   (4'H0                      ),
  .s_axi_awuser  (1'H0                      ),
  .s_axi_awvalid (s0_axil_bus_i_cast.awvalid),
  .s_axi_awready (s0_axil_bus_o_cast.awready),
  .s_axi_wid     (1'H0                      ),
  .s_axi_wdata   (s0_axil_bus_i_cast.wdata  ),
  .s_axi_wstrb   (s0_axil_bus_i_cast.wstrb  ),
  .s_axi_wlast   (1'H1                      ),
  .s_axi_wuser   (1'H0                      ),
  .s_axi_wvalid  (s0_axil_bus_i_cast.wvalid ),
  .s_axi_wready  (s0_axil_bus_o_cast.wready ),
  .s_axi_bid     (                          ),
  .s_axi_bresp   (s0_axil_bus_o_cast.bresp  ),
  .s_axi_buser   (                          ),
  .s_axi_bvalid  (s0_axil_bus_o_cast.bvalid ),
  .s_axi_bready  (s0_axil_bus_i_cast.bready ),
  .s_axi_arid    (1'H0                      ),
  .s_axi_araddr  (s0_axil_bus_i_cast.araddr ),
  .s_axi_arlen   (8'H00                     ),
  .s_axi_arsize  (3'H0                      ),
  .s_axi_arburst (2'H0                      ),
  .s_axi_arlock  (1'H0                      ),
  .s_axi_arcache (4'H0                      ),
  .s_axi_arprot  (3'H0                      ),
  .s_axi_arqos   (4'H0                      ),
  .s_axi_aruser  (1'H0                      ),
  .s_axi_arvalid (s0_axil_bus_i_cast.arvalid),
  .s_axi_arready (s0_axil_bus_o_cast.arready),
  .s_axi_rid     (                          ),
  .s_axi_rdata   (s0_axil_bus_o_cast.rdata  ),
  .s_axi_rresp   (s0_axil_bus_o_cast.rresp  ),
  .s_axi_rlast   (                          ),
  .s_axi_ruser   (                          ),
  .s_axi_rvalid  (s0_axil_bus_o_cast.rvalid ),
  .s_axi_rready  (s0_axil_bus_i_cast.rready ),
  .m_axi_awid    (                          ),
  .m_axi_awaddr  (axil_mosi_busN.awaddr     ),
  .m_axi_awlen   (                          ),
  .m_axi_awsize  (                          ),
  .m_axi_awburst (                          ),
  .m_axi_awlock  (                          ),
  .m_axi_awcache (                          ),
  .m_axi_awprot  (                          ),
  .m_axi_awregion(                          ),
  .m_axi_awqos   (                          ),
  .m_axi_awuser  (                          ),
  .m_axi_awvalid (axil_mosi_busN.awvalid    ),
  .m_axi_awready (axil_miso_busN.awready    ),
  .m_axi_wid     (                          ),
  .m_axi_wdata   (axil_mosi_busN.wdata      ),
  .m_axi_wstrb   (axil_mosi_busN.wstrb      ),
  .m_axi_wlast   (                          ),
  .m_axi_wuser   (                          ),
  .m_axi_wvalid  (axil_mosi_busN.wvalid     ),
  .m_axi_wready  (axil_miso_busN.wready     ),
  .m_axi_bid     ({C_NUM_MASTER_SLOTS{1'b0}}),
  .m_axi_bresp   (axil_miso_busN.bresp      ),
  .m_axi_buser   ({C_NUM_MASTER_SLOTS{1'b0}}),
  .m_axi_bvalid  (axil_miso_busN.bvalid     ),
  .m_axi_bready  (axil_mosi_busN.bready     ),
  .m_axi_arid    (                          ),
  .m_axi_araddr  (axil_mosi_busN.araddr     ),
  .m_axi_arlen   (                          ),
  .m_axi_arsize  (                          ),
  .m_axi_arburst (                          ),
  .m_axi_arlock  (                          ),
  .m_axi_arcache (                          ),
  .m_axi_arprot  (                          ),
  .m_axi_arregion(                          ),
  .m_axi_arqos   (                          ),
  .m_axi_aruser  (                          ),
  .m_axi_arvalid (axil_mosi_busN.arvalid    ),
  .m_axi_arready (axil_miso_busN.arready    ),
  .m_axi_rid     ({C_NUM_MASTER_SLOTS{1'b0}}),
  .m_axi_rdata   (axil_miso_busN.rdata      ),
  .m_axi_rresp   (axil_miso_busN.rresp      ),
  .m_axi_rlast   ({C_NUM_MASTER_SLOTS{1'b1}}),
  .m_axi_ruser   ({C_NUM_MASTER_SLOTS{1'b0}}),
  .m_axi_rvalid  (axil_miso_busN.rvalid     ),
  .m_axi_rready  (axil_mosi_busN.rready     )
);


logic [mcl_intf_num_p-1:0][axil_mosi_bus_width_lp-1:0] axil_demux_mosi_bus;
logic [mcl_intf_num_p-1:0][axil_miso_bus_width_lp-1:0] axil_demux_miso_bus;


genvar i;
// TODO: find a better way to read field out of the structure
for (i=0; i<mcl_intf_num_p; i=i+1)
begin
  always_comb
  begin
    axil_demux_mosi_bus[i] = {
        axil_mosi_busN.awaddr[32*i+:32]
        ,axil_mosi_busN.awvalid[i]
        ,axil_mosi_busN.wdata[32*i+:32]
        ,axil_mosi_busN.wstrb[4*i+:4]
        ,axil_mosi_busN.wvalid[i]
        ,axil_mosi_busN.bready[i]
        ,axil_mosi_busN.araddr[32*i+:32]
        ,axil_mosi_busN.arvalid[i]
        ,axil_mosi_busN.rready[i]
    };

    {
        axil_miso_busN.awready[i]
        ,axil_miso_busN.wready[i]
        ,axil_miso_busN.bresp[2*i+:2]
        ,axil_miso_busN.bvalid[i]
        ,axil_miso_busN.arready[i]
        ,axil_miso_busN.rdata[32*i+:32]
        ,axil_miso_busN.rresp[2*i+:2]
        ,axil_miso_busN.rvalid[i]
    } = axil_demux_miso_bus[i];
    end
    end

for (i=0; i<mcl_intf_num_p; i=i+1)
begin
  s_axil_mcl_adapter #(.mcl_width_p(fifo_width_p)) s_axil_to_mcl (
    .clk_i          (clk_i                 ),
    .reset_i        (reset_i               ),
    .s_axil_mcl_bus_i(axil_demux_mosi_bus[i]),
    .s_axil_mcl_bus_o(axil_demux_miso_bus[i]),
    .mcl_v_i        (mcl_v_i[i]            ),
    .mcl_data_i     (mcl_data_i[fifo_width_p*i+:fifo_width_p]  ),
    .mcl_r_o        (mcl_yumi_o[i]         ),
    .mcl_v_o        (mcl_v_o[i]            ),
    .mcl_data_o     (mcl_data_o[fifo_width_p*i+:fifo_width_p]  ),
    .mcl_r_i        (mcl_ready_i[i]        )
  );
end

endmodule