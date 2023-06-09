`ifndef RKV_I2C_BASE_TEST_SV
`define RKV_I2C_BASE_TEST_SV

virtual class rkv_i2c_base_test extends uvm_test;

  rkv_i2c_config cfg;
  ral_block_rkv_i2c rgm;

  rkv_i2c_env env;

  function new(string name = "rkv_i2c_base_test", uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    rgm = ral_block_rkv_i2c::type_id::create("rgm");
    rgm.build();
    rgm.lock_model();
    uvm_config_db#(ral_block_rkv_i2c)::set(this,"env","rgm",rgm);
    cfg = rkv_i2c_config::type_id::create("cfg");
    cfg.rgm = rgm;
    uvm_config_db#(rkv_i2c_config)::set(this,"env","cfg", cfg);
    env = rkv_i2c_env::type_id::create("env", this);
  endfunction

  function void end_of_elaboration_phase(uvm_phase phase);
    super.end_of_elaboration_phase(phase);
    uvm_root::get().set_report_verbosity_level_hier(UVM_HIGH);
    uvm_root::get().set_report_max_quit_count(10);
    uvm_root::get().set_timeout(10ms);
  endfunction

  task run_phase(uvm_phase phase);
    // NOTE:: raise objection to prevent simulation stopping
    phase.raise_objection(this);
    this.run_top_virtual_sequence();
    // NOTE:: drop objection to request simulation stopping
    phase.drop_objection(this);
  endtask

  virtual task run_top_virtual_sequence();
    // User to implement this task in the child tests
  endtask
endclass: rkv_i2c_base_test

`endif // RKV_I2C_BASE_TEST_SV
