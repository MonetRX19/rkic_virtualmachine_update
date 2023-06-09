`ifndef RKV_I2C_QUICK_REG_ACCESS_VIRT_SEQ_SV
`define RKV_I2C_QUICK_REG_ACCESS_VIRT_SEQ_SV
class rkv_i2c_quick_reg_access_virt_seq extends rkv_i2c_base_virtual_sequence;

  `uvm_object_utils(rkv_i2c_quick_reg_access_virt_seq)

  function new (string name = "rkv_i2c_quick_reg_access_virt_seq");
    super.new(name);
  endfunction

  virtual task body();
    uvm_status_e status;
    bit [31:0] read_val;
    `uvm_info(get_type_name(), "=====================STARTED=====================", UVM_LOW)
    super.body();
    `uvm_info("REG OPERATION","REG IC_CON WRITE start",UVM_LOW)
    rgm.IC_CON.IC_SLAVE_DISABLE.set(1);
    rgm.update(status);
    `uvm_info("REG OPERATION","REG IC_CON WRITE done",UVM_LOW)
    rgm.IC_CON.read(status,read_val);
    diff_value(1,read_val[6],"compare w/r value");
    #1ms;
    // Attach element sequences below
    `uvm_info(get_type_name(), "=====================FINISHED=====================", UVM_LOW)
  endtask

endclass
`endif // RKV_I2C_QUICK_REG_ACCESS_VIRT_SEQ_SV
