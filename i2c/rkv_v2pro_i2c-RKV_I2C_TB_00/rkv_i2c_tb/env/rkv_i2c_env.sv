
`ifndef RKV_I2C_ENV_SV
`define RKV_I2C_ENV_SV

class rkv_i2c_env extends uvm_component;

  // top configuration
  rkv_i2c_config cfg;

  lvc_apb_master_agent apb_mst;

  lvc_i2c_master_agent i2c_mst;

  lvc_i2c_slave_agent i2c_slv;

  // top scoreboard
  rkv_i2c_scoreboard sbd;

  // top virtual sequencer
  rkv_i2c_virtual_sequencer sqr;

  // top coverage model
  rkv_i2c_cgm cgm;

  // top register model and related components
  ral_block_rkv_i2c rgm;
  lvc_apb_reg_adapter adapter;
  uvm_reg_predictor #(lvc_apb_transfer) predictor;

  `uvm_component_utils(rkv_i2c_env)

  function new (string name = "rkv_i2c_env", uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if(!uvm_config_db#(rkv_i2c_config)::get(this,"","cfg",cfg))begin
      `uvm_fatal("GETCFG","cannot get config object from config DB")
    end
    if(!uvm_config_db#(ral_block_rkv_i2c)::get(this,"","rgm",rgm))begin
      rgm = ral_block_rkv_i2c::type_id::create("rgm");
      rgm.build();
      rgm.lock_model(); 
    end
    cfg.rgm = rgm;
    uvm_config_db#(ral_block_rkv_i2c)::set(this,"*","rgm",rgm);
    uvm_config_db#(virtual lvc_i2c_if)::get(this,"","i2c_vif",cfg.i2c_cfg.slave_cfg[0].i2c_if);
    //uvm_config_db#(virtual lvc_i2c_if)::get(this,"","i2c_vif",i2c_slv.vif);

    uvm_config_db#(lvc_i2c_agent_configuration)::set(this,"i2c_slv*","cfg",cfg.i2c_cfg.slave_cfg[0]);
    uvm_config_db#(rkv_i2c_config)::set(this,"sqr","cfg",cfg);
    uvm_config_db#(rkv_i2c_config)::set(this,"sbd","cfg",cfg);
    uvm_config_db#(rkv_i2c_config)::set(this,"cgm","cfg",cfg);
    apb_mst = lvc_apb_master_agent::type_id::create("apb_mst",this);
    i2c_slv = lvc_i2c_slave_agent::type_id::create("i2c_slv",this);
    sbd = rkv_i2c_scoreboard::type_id::create("sbd",this);
    sqr = rkv_i2c_virtual_sequencer::type_id::create("sqr",this);
    cgm = rkv_i2c_cgm::type_id::create("cgm",this);
    adapter = lvc_apb_reg_adapter::type_id::create("adapter",this);
    predictor = uvm_reg_predictor#(lvc_apb_transfer)::type_id::create("predictor",this);


  endfunction: build_phase


  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    // TODO
    // connect monitor analysis port to scoreboard
    apb_mst.monitor.item_collected_port.connect(sbd.apb_trans_imp);
    i2c_slv.monitor.xact_observed_port.connect(sbd.i2c_trans_imp);
    
      
    // TODO
    // connect monitor analysis port to coverage model

    // virtual sequencer routing with sub-sequencers
    sqr.apb_mst_sqr = apb_mst.sequencer;
    sqr.i2c_slv_sqr = i2c_slv.sequencer;

    // register model integration
    rgm.default_map.set_sequencer(apb_mst.sequencer,adapter);
    predictor.map = rgm.default_map;
    predictor.adapter = adapter;

  endfunction: connect_phase

endclass


`endif
