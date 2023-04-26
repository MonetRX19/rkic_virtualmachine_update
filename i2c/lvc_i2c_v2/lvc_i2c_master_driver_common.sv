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
`ifndef LVC_I2C_MASTER_DRIVER_COMMON_SV
`define LVC_I2C_MASTER_DRIVER_COMMON_SV

class lvc_i2c_master_driver_common extends lvc_i2c_driver_common;

  `uvm_object_utils_begin(lvc_i2c_master_driver_common)
  `uvm_object_utils_end
  semaphore restart_cmd_lock; //if current send the restart cmd, next transaction need not to send start cmd

  bit addr_10bit_again = 0; // transaction 10bits address required again
  bit same_addr_10bit = 0; // same 10bits address required
  bit [9:0] last_trans_addr = 0; // address recorded from last transaction
  bit trans_start_flag = 0; // start flag
  bit trans_stop_flag = 0; // stop flag
  bit trans_restart_flag = 0; // repeated start flag
  bit[2:0]  num_of_retry=0;
  int retry_num=0;

  extern function new(string name = "lvc_i2c_master_driver_common");
  extern virtual task send_xact(lvc_i2c_master_transaction trans);
  extern task drive_data(lvc_i2c_master_transaction trans);
  extern virtual task collect_response_from_vif(lvc_i2c_master_transaction trans);
  extern task drive_start(int setup_start_time = this.setup_start_time,
                          int hold_start_time = this.hold_start_time
                          );
  extern task drive_stop();
  extern task drive_7bit_addr(bit[6:0] addr, bit rw);
  extern task drive_10bit_addr(bit [9:0] addr, bit rw);
  extern task drive_write_byte(bit[7:0] send_byte
                     ,logic ack_bit = 1'bz
                     ,int hold_data_time = this.hold_data_time
                     ,int scl_low_time = this.scl_low_time
                     ,int scl_high_time = this.scl_high_time
                     );
  extern task drive_wait_slave_stretch_release();
  extern task drive_read_byte(output bit[7:0] recv_data, input bit ack_bit = 0);
  extern task drive_start_byte();
  extern task drive_highspeed_setup(bit[7:0] send_byte, fm_plus_mode = 0);
  extern task drive_restart();
  extern task drive_same_10bit_addr(bit [9:0] addr, bit rw);
  extern task drive_check_slave_nack_and_respond(input lvc_i2c_master_transaction trans
                                                ,output loop_branch_enum loop_branch
                                                ,input bit addr_byte_phase = 1
                                                );
  extern task drive_trans_finish(input lvc_i2c_master_transaction trans
                                ,output loop_branch_enum loop_branch
                                );
  extern task drive_addr_bits(input lvc_i2c_master_transaction trans);
  extern task drive_write_or_read_setup(input lvc_i2c_master_transaction trans);
  extern task update_num_of_retry_trans(input lvc_i2c_master_transaction trans);

  `define LVC_DRIVE_ADDR_BITS(TRANS, LPBR) \
    drive_addr_bits(TRANS); \
    drive_check_slave_nack_and_respond(TRANS, LPBR); \
    `LVC_GOTO_LOOP_BRANCH(LPBR); 

  `define LVC_DRIVE_WRITE_BYTE(BYTE, TRANS, LPBR) \
    drive_write_byte(BYTE); \
    drive_check_slave_nack_and_respond(TRANS, LPBR, 0); \
    `LVC_GOTO_LOOP_BRANCH(LPBR);

  `define LVC_DRIVE_WRITE_BYTES(TRANS, LPBR) \
    for(int i=0; i<TRANS.data.size();i++) begin \
      drive_write_byte(TRANS.data[i]); \
      drive_check_slave_nack_and_respond(TRANS, LPBR, 0); \
      `LVC_GOTO_LOOP_BRANCH(LPBR); \
    end \
    drive_trans_finish(TRANS, LPBR); \
    `LVC_GOTO_LOOP_BRANCH(LPBR);

  `define LVC_DRIVE_READ_BYTES(TRANS, LPBR, RCVD, SIZE) \
    for(int i=0; i<SIZE-1;i++) begin \
      drive_read_byte(RCVD); \
      TRANS.data[i] = RCVD; \
    end \
    drive_read_byte(RCVD, 1); \
    trans.data[SIZE-1] = RCVD; \
    drive_trans_finish(TRANS, LPBR); \
    `LVC_GOTO_LOOP_BRANCH(LPBR);

  `define LVC_DRIVE_WRITE_ADDR_AND_BYTES(TRANS, LPBR) \
    `LVC_DRIVE_ADDR_BITS(TRANS, LPBR); \
    `LVC_DRIVE_WRITE_BYTES(TRANS, LPBR);
  
  `define LVC_DRIVE_READ_ADDR_AND_BYTES(TRANS, LPBR, RCVD) \
    `LVC_DRIVE_ADDR_BITS(TRANS, LPBR); \
    `LVC_DRIVE_READ_BYTES(TRANS, LPBR, RCVD, TRANS.data.size());


    //->i2c_if.event_master_general_call_addr_sent;
    //->i2c_if.event_master_general_call_sec_byte_sent;
  `define LVC_DRIVE_GENERAL_CALL_BYTE(TRANS, LPBR, FRSTB, SCNDB) \
    drive_write_byte(FRSTB); \
    drive_check_slave_nack_and_respond(TRANS, LPBR); \
    `LVC_GOTO_LOOP_BRANCH(LPBR); \
    drive_write_byte(SCNDB); \
    drive_check_slave_nack_and_respond(TRANS, LPBR); \
    `LVC_GOTO_LOOP_BRANCH(LPBR);

endclass

function lvc_i2c_master_driver_common::new(string name = "lvc_i2c_master_driver_common");
  super.new(name);
  restart_cmd_lock = new(1);
endfunction

task lvc_i2c_master_driver_common::send_xact(lvc_i2c_master_transaction trans);
  lvc_i2c_master_transaction trans_temp;
  extract_time_parameters();
  drive_data(trans);
endtask

task lvc_i2c_master_driver_common::drive_data(lvc_i2c_master_transaction trans);
  bit       rw;   //0--write, 1--read
  bit[7:0]  recv_data;
  bit[7:0]  gen_call_first_byte = 8'b0000_0000;
  bit[7:0]  gen_call_second_byte = trans.sec_byte_gen_call;
  bit[7:0]  device_id_w = 8'b1111_1000;
  bit[7:0]  device_id_r = 8'b1111_1001;

  loop_branch_enum loop_branch;

  update_num_of_retry_trans(trans);
  case(trans.cmd)
    I2C_WRITE:
      for(retry_num=0; retry_num<=num_of_retry; ) begin
        nack_received_flag = 0;
        drive_write_or_read_setup(trans);
        `LVC_DRIVE_WRITE_ADDR_AND_BYTES(trans, loop_branch);
      end 
    I2C_READ:
      for(retry_num=0; retry_num<=num_of_retry; ) begin
        drive_write_or_read_setup(trans);
        `LVC_DRIVE_READ_ADDR_AND_BYTES(trans, loop_branch, recv_data);
      end
    I2C_GEN_CALL:
      for(retry_num=0; retry_num<=num_of_retry;) begin
        drive_start();
        if(trans.send_start_byte==1) drive_start_byte();
        `LVC_DRIVE_GENERAL_CALL_BYTE(trans, loop_branch, gen_call_first_byte, gen_call_second_byte); 
        `LVC_DRIVE_WRITE_BYTES(trans, loop_branch);
      end
    I2C_DEVICE_ID:
      for(retry_num=0; retry_num<=num_of_retry; ) begin
        drive_start();
        `LVC_DRIVE_WRITE_BYTE(device_id_w, trans, loop_branch);
        drive_addr_bits(trans);
        if(trans.m_device_id_gen_stop==0) begin
          drive_restart();
          `LVC_DRIVE_WRITE_BYTE(device_id_r, trans, loop_branch);
          if(trans.device_id_rollback_iteration ==0 
            && trans.nack_at_device_id_byte == 0
            )  begin   //no rollback
            `LVC_DRIVE_READ_BYTES(trans, loop_branch, recv_data, 3);
          end  
          else begin    //rollback
            `LVC_DRIVE_READ_BYTES(trans, loop_branch, recv_data, trans.nack_at_device_id_byte)
          end
        end
        else begin
          drive_trans_finish(trans, loop_branch);
          `LVC_GOTO_LOOP_BRANCH(loop_branch);
        end
      end
    default: begin
      `uvm_error("i2c_master_driver_common","i2c command error!!!");
    end
  endcase
endtask : drive_data

task lvc_i2c_master_driver_common::collect_response_from_vif(lvc_i2c_master_transaction trans);
// TODO detailed bus response collection here!!!
endtask

task lvc_i2c_master_driver_common::drive_start(int setup_start_time = this.setup_start_time,
                                               int hold_start_time = this.hold_start_time
                                              );
  if(restart_cmd_lock.try_get()) begin
    i2c_if.scl_master = 1;
    i2c_if.sda_master <= 1;
    sda_wait_time_set(setup_start_time, 0);
    scl_wait_time_set(hold_start_time, 0);
    trans_start_flag = 1;
    trans_stop_flag = 0;
  end
  else
    `uvm_info("start", "Because The Last Transaction Have Generate Restart CMD, This Transation Need Not Generate Start CMD", UVM_DEBUG);
endtask : drive_start

task lvc_i2c_master_driver_common::drive_restart();
  //bus free time, hs mode no this parameter.
  fork
    scl_wait_time_set(scl_low_time, 1);
    sda_wait_time_set(scl_low_time + setup_stop_time, 1);
  join
  sda_wait_time_set(bus_free_time, 0);
  scl_wait_time_set(hold_start_time, 0);
  trans_restart_flag = 1;
//->i2c_if.event_master_repeated_start_generated;
endtask : drive_restart

task lvc_i2c_master_driver_common::drive_highspeed_setup(bit[7:0] send_byte, fm_plus_mode = 0);
  int scl_low_time = fm_plus_mode == 0 ? cfg.scl_low_time_fs : cfg.scl_low_time_fm_plus;
  int scl_high_time = fm_plus_mode == 0 ? cfg.scl_high_time_fs : cfg.scl_high_time_fm_plus;
  int hold_data_time = fm_plus_mode == 0 ? cfg.min_hd_dat_time_fs : cfg.min_hd_dat_time_fm_plus;
  int setup_start_time =  fm_plus_mode == 0 ? cfg.min_su_sta_time_fs : cfg.min_su_sta_time_fm_plus;
  int hold_start_time =  fm_plus_mode == 0 ? cfg.min_hd_sta_time_fs : cfg.min_hd_sta_time_fm_plus;
  // Highspeed start 
  drive_start(setup_start_time, hold_start_time);
  // Highspeed byte code
  drive_write_byte(send_byte, 
                   ,.hold_data_time(hold_data_time) 
                   ,.scl_low_time(scl_low_time)
                   ,.scl_high_time(scl_high_time));
endtask

task lvc_i2c_master_driver_common::drive_stop();
  fork
    sda_wait_time_set(hold_data_time, 0);
    scl_wait_time_set(scl_low_time, 1);
  join
  sda_wait_time_set(setup_stop_time, 1);
  wait_time(bus_free_time);
  trans_stop_flag = 1;
  trans_start_flag = 0;
  trans_restart_flag = 0;
  //->i2c_if.event_master_stop_generated;
  restart_cmd_lock.put();
endtask : drive_stop

task lvc_i2c_master_driver_common::drive_7bit_addr(bit[6:0] addr, bit rw);
  drive_write_byte({addr, rw});
endtask : drive_7bit_addr

task lvc_i2c_master_driver_common::drive_10bit_addr(bit [9:0] addr, bit rw);
  bit[6:0] first_7bit = {5'b11110, addr[9:8]};
  drive_write_byte({first_7bit, 1'b0});
  if(nack_received_flag) return;
  drive_write_byte(addr[7:0]);
  if(nack_received_flag) return;
  if(rw == 1)  begin  
    drive_restart();
    drive_write_byte({first_7bit, 1'b1});
    if(nack_received_flag) return;
  end
endtask : drive_10bit_addr

task lvc_i2c_master_driver_common::drive_write_byte(bit[7:0] send_byte
                                                   ,logic ack_bit = 1'bz
                                                   ,int hold_data_time = this.hold_data_time
                                                   ,int scl_low_time = this.scl_low_time
                                                   ,int scl_high_time = this.scl_high_time
                                                   );
  logic [8:0] send_bits = {send_byte, ack_bit};
  for(int i=8;i>=0;i--) begin
    fork
      sda_wait_time_set(hold_data_time, send_bits[i]);
      scl_wait_time_set(scl_low_time, 1);
    join
    if(i==0) check_slave_ack();
    scl_wait_time_set(scl_high_time, 0);
  end
endtask : drive_write_byte

task lvc_i2c_master_driver_common::drive_wait_slave_stretch_release();
  // adaption for clock stretch
  if(i2c_if.SCL === 1'b0) begin
    wait(i2c_if.SCL === 1);
    i2c_if.scl_master <= 0;
    scl_wait_time_set(hold_data_time + data_offset_time, 1);
  end
endtask

task lvc_i2c_master_driver_common::drive_read_byte(output bit[7:0] recv_data, input bit ack_bit = 0);
  for(int i=7;i>=0;i--) begin
    scl_wait_time_set(scl_low_time, 1); #1ps;// add 1ps to activate SCL = 1
    drive_wait_slave_stretch_release();
    recv_data[i] = i2c_if.SDA;
    scl_wait_time_set(scl_high_time, 0); 
  end
  fork
    sda_wait_time_set(hold_data_time, ack_bit);
    scl_wait_time_set(scl_low_time, 1);
  join
  scl_wait_time_set(scl_high_time, 0); 
  sda_wait_time_set(hold_data_time, 1'bz);
endtask : drive_read_byte

task lvc_i2c_master_driver_common::drive_start_byte();
  bit[7:0]  start_byte = 9'b00000001;
  drive_write_byte(start_byte, 1'b1);
  drive_restart();
endtask : drive_start_byte

task lvc_i2c_master_driver_common::drive_same_10bit_addr(bit [9:0] addr, bit rw);
  bit[6:0] first_7bit = {5'b11110, addr[9:8]};
  // If WRITE, offer slave address 1st 7bits and 2nd BYTE
  if(rw == 0) begin 
    drive_write_byte({first_7bit, 1'b0});
    if(nack_received_flag) return;
    drive_write_byte(addr);
    if(nack_received_flag) return;
  end
  else begin
    drive_write_byte({first_7bit, 1'b1});
    if(nack_received_flag) return;
  end
endtask : drive_same_10bit_addr

task lvc_i2c_master_driver_common::drive_check_slave_nack_and_respond(
                                      input lvc_i2c_master_transaction trans
                                     ,output loop_branch_enum loop_branch
                                     ,input bit addr_byte_phase = 1
                                     );
  loop_branch = LOOP_NO_JUMP;
  if(nack_received_flag==1) begin
    if(num_of_retry==0 | !trans.retry_if_nack) begin
      drive_stop();
      loop_branch = LOOP_RETURN;
    end
    else if(retry_num==num_of_retry) begin
      if(addr_byte_phase) loop_branch = LOOP_CONTINUE;
      else loop_branch = LOOP_BREAK;
    end
    else begin
      //0--gen sotp, 1--gen re-start 
      if(trans.sr_or_p_gen==0) drive_stop();
      else drive_restart();
      if(addr_byte_phase) loop_branch = LOOP_CONTINUE;
      else loop_branch = LOOP_BREAK;
    end
    retry_num++;
  end 
endtask: drive_check_slave_nack_and_respond

task lvc_i2c_master_driver_common::drive_trans_finish(input lvc_i2c_master_transaction trans
                                                     ,output loop_branch_enum loop_branch
                                                     );
  loop_branch = LOOP_NO_JUMP;
  if(trans.cmd inside {I2C_WRITE, I2C_GEN_CALL}) begin
    if(nack_received_flag == 0 | retry_num == num_of_retry+1) begin
      if(trans.sr_or_p_gen == 0) //0--gen sotp, 1--gen re-start
        drive_stop();
      else
        drive_restart();
      loop_branch = LOOP_BREAK;
    end 
  end
  //else if(trans.cmd inside '{I2C_READ}) begin
  else begin
    if(trans.sr_or_p_gen==0  | retry_num==num_of_retry+1  | retry_num==0) begin 
      retry_num++;
      drive_stop();
    end
    else
      drive_restart();
    if(trans.cmd inside {I2C_DEVICE_ID}) 
      loop_branch = LOOP_BREAK;
  end
endtask: drive_trans_finish

task lvc_i2c_master_driver_common::drive_addr_bits(input lvc_i2c_master_transaction trans);
  last_trans_addr = trans.addr;
  if(trans.addr_10bit ==1) begin
    if(cfg.bus_speed != HIGHSPEED_MODE
       && trans.cmd inside {I2C_WRITE, I2C_READ}
      ) 
      addr_10bit_again = 1;
    if(trans.cmd == I2C_READ
       && addr_10bit_again == 1 
       && trans.addr == last_trans_addr 
       && trans_restart_flag == 1
       && trans.send_start_byte == 0
      )
      drive_same_10bit_addr(trans.addr, 1);
    else
      drive_10bit_addr(trans.addr, 0);
  end
  else 
    drive_7bit_addr(trans.addr[6:0], 0);
endtask: drive_addr_bits

task lvc_i2c_master_driver_common::update_num_of_retry_trans(input lvc_i2c_master_transaction trans);
  if(trans.retry_if_nack) 
    num_of_retry = trans.num_of_retry;
  else 
    num_of_retry=0;
endtask: update_num_of_retry_trans

task lvc_i2c_master_driver_common::drive_write_or_read_setup(input lvc_i2c_master_transaction trans);
  bit[7:0]  hs_code = {5'b00001,cfg.master_code};
  // NOTE:: @Lusang 2020-09-02
  // F/S mode switch to HighSpeed mode only need once
  // in case repeated start with bytes following
  if(cfg.bus_speed == HIGHSPEED_MODE && trans_restart_flag == 0) begin
    drive_highspeed_setup(hs_code, cfg.start_hs_in_fm_plus);
    drive_restart();
  end 
  else begin
    drive_start();
    if(trans.send_start_byte == 1) drive_start_byte();
  end 
endtask: drive_write_or_read_setup

`endif // LVC_I2C_MASTER_DRIVER_COMMON_SV
