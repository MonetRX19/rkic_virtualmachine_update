//=======================================================================
// COPYRIGHT (C) 2018-2020 RockerIC, Ltd.
// This software and the associated documentation are confidential and
// proprietary to RockerIC, Ltd. Your use or disclosure of this software
// is subject to the terms and conditions of a consulting agreement
// between you, or your company, and RockerIC, Ltd. In the event of
// publications, the following notice is applicable:
//
// ALL RIGHTS RESERVED
//
// The entire notice above must be reproduced on all authorized copies.
//
// VisitUs  : www.rockeric.com
// Support  : support@rockeric.com
// WeChat   : eva_bill
//-----------------------------------------------------------------------
`ifndef LVC_I2C_SLAVE_AGENT_SVH
`define LVC_I2C_SLAVE_AGENT_SVH

class lvc_i2c_slave_agent extends uvm_agent;

  //////////////////////////////////////////////////////////////////////////////
  //
  //  Public interface (Component users may manipulate these fields/methods)
  //
  //////////////////////////////////////////////////////////////////////////////
  local lvc_i2c_agent_configuration cfg;
  protected lvc_i2c_agent_configuration cfg_snapshot;
  // The following are the verification components that make up
  // this agent
  lvc_i2c_slave_driver driver;
  lvc_i2c_slave_sequencer sequencer;
  lvc_i2c_slave_monitor monitor;
  lvc_i2c_vif vif;

  // USER: Add your fields here

  // This macro performs UVM object creation, type control manipulation, and
  // factory registration
  `uvm_component_utils_begin(lvc_i2c_slave_agent)
    // USER: Register your fields here
    `uvm_field_enum(uvm_active_passive_enum, is_active, UVM_ALL_ON)
    `uvm_field_object(cfg, UVM_ALL_ON)
  `uvm_component_utils_end

  // new - constructor
  extern function new (string name="lvc_i2c_slave_agent", uvm_component parent=null);

  // uvm build phase
  extern function void build_phase(uvm_phase phase);

  // uvm connection phase
  extern function void connect_phase(uvm_phase phase);

  extern virtual task reconfigure_via_task(lvc_configuration cfg);

  extern task run_phase(uvm_phase phase);

  //extern task handle_runtime_rst();

//////////////////////////////////////////////////////////////////////////////
//
//  Implementation (private) interface
//
//////////////////////////////////////////////////////////////////////////////


endclass : lvc_i2c_slave_agent

function lvc_i2c_slave_agent::new(string name="lvc_i2c_slave_agent",uvm_component parent=null);
  super.new(name,parent);
endfunction : new

function void lvc_i2c_slave_agent::build_phase(uvm_phase phase);
  int active_int;
  bit active_bit;

  super.build_phase(phase);
  `uvm_info("build_phase","lvc_i2c_slave_agent: starting...",UVM_LOW)

  if(cfg==null && !uvm_config_db#(lvc_i2c_agent_configuration)::get(this,"","cfg",cfg)) begin
    `uvm_fatal("build_phase","'cfg' is null. An lvc_i2c_agent_configuration object or derivitive object must be set using the UVM configuration infrastructure.")
  end
  else begin
    if(!($cast(this.cfg,cfg.clone()) && $cast(cfg_snapshot,cfg.clone()))) begin
      `uvm_fatal("build_phase","unable to cast the received configuration.")
    end
    else begin
      if(uvm_config_db#(lvc_i2c_vif)::get(this,"","vif",vif)) begin
        if(cfg.i2c_if != null) begin
          `uvm_warning("build_phase","thie virtual interface is valid in the received config object and top-down config. Replace the vif with received vif from config db.")
        end
        else begin
          `uvm_warning("build_phase","applying the virtual interface received throng the config db to the confuration.")
        end
        cfg.set_i2c_if(vif);
        cfg_snapshot.set_i2c_if(vif);
      end
      else begin
        if(cfg.i2c_if == null) begin
          `uvm_fatal("build_phase","a virtual interface was not received either through the config db")
        end
      end
    end
  end

  if (uvm_config_db#(bit)::get(this,"","is_active",active_bit)) begin
    is_active = uvm_active_passive_enum'(active_bit);
    cfg.is_active = active_bit;
  end
  else if(uvm_config_db#(int)::get(this,"","is_active",active_int)) begin
    is_active = uvm_active_passive_enum'(active_int);
    cfg.is_active = active_int;
  end
  else if(uvm_config_db#(uvm_active_passive_enum)::get(this,"","is_active",is_active)) begin
    cfg.is_active = int'(is_active);
  end

  this.cfg.inst = $sformatf("%s.monitor",this.get_full_name());
  uvm_config_db#(lvc_i2c_agent_configuration)::set(this,"monitor","cfg",cfg);

  if(cfg.is_active) begin
    this.cfg.inst=$sformatf("%s.driver",this.get_full_name());
    uvm_config_db#(lvc_i2c_agent_configuration)::set(this,"driver","cfg",cfg);
    this.cfg.inst=$sformatf("%s.sequencer",this.get_full_name());
    uvm_config_db#(lvc_i2c_agent_configuration)::set(this,"sequencer","cfg",cfg);
  end

  `uvm_info("build_phase","agent configuration",UVM_LOW)
  this.cfg.inst= this.get_full_name();
  uvm_config_db#(lvc_i2c_agent_configuration)::set(this,"monitor","cfg",cfg);
  if(cfg.is_active) begin
    uvm_config_db#(lvc_i2c_agent_configuration)::set(this,"driver","cfg",cfg);
    uvm_config_db#(lvc_i2c_agent_configuration)::set(this,"sequencer","cfg",cfg);
  end

  if(cfg.is_active) begin
    `uvm_info("build_phase","creating active agent",UVM_LOW)
    driver=lvc_i2c_slave_driver::type_id::create("driver",this);
    sequencer = lvc_i2c_slave_sequencer::type_id::create("sequencer",this);
    monitor = lvc_i2c_slave_monitor::type_id::create("monitor",this);
  end
  else begin
    `uvm_info("build_phase","creating passive agent",UVM_LOW)
    monitor = lvc_i2c_slave_monitor::type_id::create("monitor",this);
  end

  //TODO others

  `uvm_info("build_phase","lvc_i2c_slave_agent: finishing...",UVM_LOW)
endfunction : build_phase

function void lvc_i2c_slave_agent::connect_phase(uvm_phase phase);
  super.connect_phase(phase);
  `uvm_info("connect_phase","lvc_i2c_slave_agent: starting...",UVM_LOW)
  if(cfg.is_active) begin
    driver.seq_item_port.connect(sequencer.seq_item_export);
  end
  `uvm_info("connect_phase","lvc_i2c_slave_agent: finishing...",UVM_LOW)
endfunction : connect_phase

task lvc_i2c_slave_agent::reconfigure_via_task(lvc_configuration cfg);
  lvc_i2c_agent_configuration agent_cfg;

  if($cast(agent_cfg,cfg)) begin
    this.cfg.copy(agent_cfg);
    this.cfg_snapshot.copy(agent_cfg);
  end

  if($cast(agent_cfg,cfg)) begin
    `uvm_info("reconfigure_via_task", $sformatf("configuration at %s:\n%s",get_full_name(),agent_cfg.sprint()),UVM_LOW)
  end

  monitor.reconfigure_via_task(cfg);
  if(agent_cfg.is_active) begin
    driver.reconfigure_via_task(cfg);
    sequencer.reconfigure(cfg);
  end
endtask : reconfigure_via_task

task lvc_i2c_slave_agent::run_phase(uvm_phase phase);
  `uvm_info("run_phase","lvc_i2c_slave_agent run phase: starting...",UVM_LOW)
  super.run_phase(phase);
  `uvm_info("run_phase","lvc_i2c_slave_agent run phase: finishing...",UVM_LOW)
endtask : run_phase

`endif // LVC_I2C_SLAVE_AGENT_SVH

