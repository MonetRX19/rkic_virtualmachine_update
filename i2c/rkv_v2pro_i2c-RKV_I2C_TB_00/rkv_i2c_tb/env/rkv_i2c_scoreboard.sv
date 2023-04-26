
`ifndef RKV_I2C_SCOREBOARD_SV
`define RKV_I2C_SCOREBOARD_SV

class rkv_i2c_scoreboard extends uvm_component;

  // TODO
  // Analysis FIFO declarion below
  `uvm_analysis_imp_decl(_apb)
  `uvm_analysis_imp_decl(_i2c)


  `uvm_component_utils(rkv_i2c_scoreboard)

  uvm_analysis_imp_apb#(lvc_apb_transfer,rkv_i2c_scoreboard) apb_trans_imp;
  uvm_analysis_imp_i2c#(lvc_i2c_slave_transaction,rkv_i2c_scoreboard) i2c_trans_imp;

  function new (string name = "rkv_i2c_scoreboard", uvm_component parent);
    super.new(name, parent);
    
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    apb_trans_imp = new("apb_trans_imp",this);
    i2c_trans_imp = new("i2c_trans_imp",this);
  endfunction

  virtual function void write_apb(lvc_apb_transfer tr);
endfunction

  virtual function void write_i2c(lvc_i2c_slave_transaction tr);
endfunction

endclass

`endif // RKV_I2C_SCOREBOARD_SV
