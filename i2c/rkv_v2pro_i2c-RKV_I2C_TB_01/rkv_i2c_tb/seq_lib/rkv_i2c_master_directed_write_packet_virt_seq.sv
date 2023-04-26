`ifndef RKV_I2C_MASTER_DIRECTED_WRITE_PACKET_VIRT_SEQ_SV
`define RKV_I2C_MASTER_DIRECTED_WRITE_PACKET_VIRT_SEQ_SV
class rkv_i2c_master_directed_write_packet_virt_seq extends rkv_i2c_base_virtual_sequence;

  `uvm_object_utils(rkv_i2c_master_directed_write_packet_virt_seq)

  function new (string name = "rkv_i2c_master_directed_write_packet_virt_seq");
    super.new(name);
  endfunction

  virtual task body();
    `uvm_info(get_type_name(), "=====================STARTED=====================", UVM_LOW)
    super.body();
    vif.wait_rstn_release();
    vif.wait_apb(10);

    // TODO
    // Use element sequences to program I2C DUT, I2C Slave VIP
    #10us;

    // Attach element sequences below
    `uvm_info(get_type_name(), "=====================FINISHED=====================", UVM_LOW)
  endtask

endclass
`endif // RKV_I2C_MASTER_DIRECTED_WRITE_PACKET_VIRT_SEQ_SV
