`ifndef RKV_I2C_CONFIG_SV
`define RKV_I2C_CONFIG_SV

class rkv_i2c_config extends uvm_object;

  lvc_apb_config apb_cfg;
  lvc_i2c_system_configuration i2c_cfg;
  ral_block_rkv_i2c rgm;

  `uvm_object_utils(rkv_i2c_config)

  function new (string name = "rkv_i2c_config");
    super.new(name);
    apb_cfg = lvc_apb_config::type_id::create("apb_cfg");
    i2c_cfg = lvc_i2c_system_configuration::type_id::create("i2c_cfg");
    do_apb_cfg();
    do_i2c_cfg();
  endfunction

  function void do_apb_cfg();
    // TODO
  endfunction


  function void do_i2c_cfg();
    i2c_cfg.num_masters = 1;
    i2c_cfg.num_slaves = 1;
    i2c_cfg.create_sub_cfgs(i2c_cfg.num_masters,i2c_cfg.num_slaves);
  endfunction

endclass

`endif // RKV_I2C_CONFIG_SV
