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
`ifndef LVC_I2C_SLAVE_DRIVER_COMMON_SV
`define LVC_I2C_SLAVE_DRIVER_COMMON_SV

class lvc_i2c_slave_driver_common extends lvc_i2c_driver_common;

  `uvm_object_utils_begin(lvc_i2c_slave_driver_common)
  `uvm_object_utils_end
  logic   trans_start_flag = 0;
  logic   trans_stop_flag = 0;
  logic   trans_restart_flag = 0;

  // solution for transaction overriding from sequences or keep as constant
  // current transaction executing got from sequence
  lvc_i2c_slave_transaction trans;
  int addr_nack_count = 0;
  local bit _is_running = 0;
  bit[7:0] mon_data[$];
  int mon_data_index = 0;
  semaphore restart_cmd_lock; //if current send the restart cmd, next transaction need not to send start cmd

  extern function new(string name = "lvc_i2c_slave_driver_common");
  extern task collect_start(); //SLAVE start generation
  extern task collect_stop(); //SLAVE end generation
  extern task collect_byte(); // monitor byte unit
  extern task respond_trans_read_data(lvc_i2c_slave_transaction trans); // respond read byte 
  extern task respond_trans_write_data(lvc_i2c_slave_transaction trans); // respond write byte 
  extern task respond_trans_device_id_data(); // respond device id three byte
  extern task data_ana();  //analysis collected data from sda line.
  extern task drive_ack(); // drive ACK to master
  extern task drive_nack(); // drive ACK to master
  extern task drive_sda(logic val); // drive SDA
  extern function void clear_mon_data();
  extern function void update_trans_data(lvc_i2c_slave_transaction trans); // update trans data from mon_data
  extern function void check_restart_once_finished_trans(lvc_i2c_slave_transaction trans);
  extern virtual task send_xact(lvc_i2c_slave_transaction t);
  extern virtual task collect_response_from_vif(lvc_i2c_slave_transaction t);
endclass

function lvc_i2c_slave_driver_common::new(string name = "lvc_i2c_slave_driver_common");
  super.new(name);
  restart_cmd_lock = new(1);
endfunction

task lvc_i2c_slave_driver_common::send_xact(lvc_i2c_slave_transaction t);
  // NOTE:: @Lusang 2020-09-01
  // Solution for transaction override from outside
  // if got a new trans to override current transaction
  this.trans = t;
  addr_nack_count=trans.nack_addr_count;
  if(!this._is_running) begin
    this._is_running = 1;
    // ONLY trigger once for the forever loop execution
    fork
      forever begin: keep_drive_proc
        extract_time_parameters();
        fork: send_xact_proc
          collect_start();
          collect_stop();
          data_ana();
        join_any
        // FIXED:: @Lusang 2020-07-20
        // Once one of parallel threads exits, it should disable all of them
        disable send_xact_proc;
      end
    join_none
  end
  // ONLY end_flag raised, it is availabel to return from current task
  wait(this.trans_stop_flag == 1);
endtask

//check all protocol and collect write/read data to transaction
task lvc_i2c_slave_driver_common::data_ana();  
  bit      ack_nak;
  int      deviceid=0;

  forever begin
    wait(trans_start_flag|trans_restart_flag);
    if(trans_restart_flag) trans_restart_flag=0;
    trans_start_flag =0;
    collect_byte();
    casex(mon_data[mon_data_index]) //check first byte
      8'b0000_001x,8'b0000_010x,8'b0000_011x: begin
        `uvm_error("slave driver common","slave driver receive reserved address")
        drive_nack();
        @(negedge i2c_if.SCL);
      end
      8'b0000_0000:  //general call address
      begin
        trans.cmd = I2C_GEN_CALL;
        drive_ack();
        drive_sda(1'bz);
        //collect second byte
        mon_data_index++;
        collect_byte();
        drive_ack();
        drive_sda(1'bz);
        respond_trans_write_data(trans);
        check_restart_once_finished_trans(trans);
      end
      8'b0000_0001:   //start byte
      begin
        mon_data_index=0;
        trans_start_flag=0;
      end
      8'b0000_1xxx:  //hs-mode slave code
      begin
        drive_nack();
        @(negedge i2c_if.SCL);
        mon_data_index=0; 
        continue;
      end
      8'b1111_1xxx:   //device ID
      begin
        deviceid=1;
        //send ack and continue receive or transmit data
        drive_ack();
        @(negedge i2c_if.SCL);
        trans.cmd = I2C_DEVICE_ID;
        if(mon_data[mon_data_index][0]==0)  begin  //devide ID first byte, write slave address followed
          // continue receive slave address, the address is 7 bits or 10 bits
          // release SDA to master
          wait_data_hold_time();
          i2c_if.sda_slave = 1'bz;
          mon_data_index=0;
          trans_start_flag = 1;
        end
        else if(mon_data[mon_data_index][0]==1)  begin  //device ID byte followed re-start, read 3 bytes ID
          respond_trans_device_id_data();
        end
      end
      8'b1111_0xxx:   //10-bit slave addressing
      begin
        if(mon_data[mon_data_index][2:1] == cfg.slave_address[9:8])   begin     //10bit address high two bits match
          //send ack and continue receive or transmit data
          drive_sda(trans.nack_addr);
          //10bit address first byte,write cmd, coutinue receive the second byte, low 8 bits address
          if(mon_data[mon_data_index][0]==0)  begin  
            drive_sda(1'bz);
            //receive the second byte and check if it's available
            collect_byte();
            //slave low 8 bits address match,continue receive data
            if(mon_data[mon_data_index] == cfg.slave_address[7:0])  begin   
              drive_sda(trans.nack_addr);
              drive_sda(1'bz);
              respond_trans_write_data(trans);
              check_restart_once_finished_trans(trans);
            end 
            else begin
              drive_nack();
              drive_sda(1'bz);
              break;
            end  
          end   
          else if(mon_data[mon_data_index][0]==1) begin     //10bit address read
            respond_trans_read_data(trans);
          end   
        end   
        else begin  //higt two bits not match
          drive_nack();
          drive_sda(1'bz);
        end
      end
      default:  //7bit slave address read or write, should seperate read and write
      begin
        if(mon_data[mon_data_index][7:1] == cfg.slave_address[6:0]) begin
          if(addr_nack_count>0) begin
            drive_sda(trans.nack_addr);
            @(negedge i2c_if.SCL);
            addr_nack_count--;
          end
          else begin  
            //send ack to master
            drive_ack();
            if(mon_data[mon_data_index][0]==0)  begin //write
              drive_sda(1'bz);
              respond_trans_write_data(trans);
              check_restart_once_finished_trans(trans);
            end   //end write
            else  if(mon_data[mon_data_index][0]==1)  begin //read
              if(deviceid==1) begin
                //send ack and continue receive or transmit data
                drive_sda(1'bz);
                @(negedge i2c_if.SCL);
              end
              else 
                respond_trans_read_data(trans);
            end   
          end 
        end  
        else begin
          //send nack to master
          drive_nack();
          @(negedge i2c_if.SCL);
          break;
        end
      end    
    endcase
  end
endtask : data_ana

task lvc_i2c_slave_driver_common::collect_response_from_vif(lvc_i2c_slave_transaction t);
// TODO detailed bus response collection here!!!
endtask

task lvc_i2c_slave_driver_common::collect_start();
  forever begin
    @(negedge i2c_if.SDA);
    begin
      if(i2c_if.SCL==1) begin
        if(restart_cmd_lock.try_get())  begin
          trans_start_flag = 1;
          @(posedge i2c_if.SCL);
          trans_stop_flag = 0;
        end
        else begin
          trans_restart_flag = 1;
          trans_stop_flag = 0;
        end
      end
    end
  end
endtask : collect_start

task lvc_i2c_slave_driver_common::collect_stop();
  forever begin
    @(posedge i2c_if.SDA);
    if(i2c_if.SCL==1) begin
      update_trans_data(trans);
      restart_cmd_lock.put();
      trans_stop_flag = 1;
      return;
    end
  end
endtask : collect_stop

task lvc_i2c_slave_driver_common::drive_ack(); 
  drive_sda(0);
endtask: drive_ack

task lvc_i2c_slave_driver_common::drive_nack(); 
  drive_sda(1);
endtask: drive_nack

task lvc_i2c_slave_driver_common::drive_sda(logic val); 
  @(negedge i2c_if.SCL);
  wait_data_hold_time();
  // NOTE:: @Lusang 2020-09-04
  // Use blocking assignment to take effect in case slave drive SDA as
  // 'z' at the same time slot
  if(val === 1'bz)
    i2c_if.sda_slave = val;
  else  // val inside {1'b0, 1'b1}
    i2c_if.sda_slave <= val;
endtask: drive_sda

function void lvc_i2c_slave_driver_common::clear_mon_data();
  mon_data_index = 0;
  mon_data = {};
endfunction

function void lvc_i2c_slave_driver_common::update_trans_data(lvc_i2c_slave_transaction trans); 
  trans.data=mon_data;  
  clear_mon_data();
endfunction

task lvc_i2c_slave_driver_common::collect_byte(); // monitor byte unit
  for(int i=7;i>=0;i--) begin
    @(posedge i2c_if.SCL);
    mon_data[mon_data_index][i] = i2c_if.SDA;
  end
endtask: collect_byte

task lvc_i2c_slave_driver_common::respond_trans_read_data(lvc_i2c_slave_transaction trans); // drive read byte 
  int drv_bit_index=8;
  mon_data_index=0;
  while((!trans_stop_flag) & (!trans_restart_flag)) begin
    //send data to master
    drive_sda(trans.data[mon_data_index][drv_bit_index-1]);
    @(posedge i2c_if.SCL);
    drv_bit_index--;
    if(drv_bit_index==0) begin
      drv_bit_index=8;
      mon_data_index++;
      drive_sda(1'bz);
      @(posedge i2c_if.SCL);
      if(i2c_if.SDA === 1) break;
    end
  end 
endtask: respond_trans_read_data

task lvc_i2c_slave_driver_common::respond_trans_write_data(lvc_i2c_slave_transaction trans); // respond write byte 
  bit[9:0] mon_byte;
  int drv_bit_index=8; 
  clear_mon_data();
  while((!trans_stop_flag) & (!trans_restart_flag)) begin
    @(posedge i2c_if.SCL);
    mon_byte[drv_bit_index] = i2c_if.SDA;
    @(negedge i2c_if.SCL);
    drv_bit_index--;
    if(drv_bit_index==0) begin
      wait_data_hold_time();
      i2c_if.sda_slave <= (trans.nack_data==mon_data_index+1) ? 1'b1 : 1'b0;    //send ack to master driver
      mon_data[mon_data_index] = mon_byte[8:1];
      drv_bit_index=8;
      mon_data_index++;
      drive_sda(1'bz);
    end
  end 
endtask: respond_trans_write_data

task lvc_i2c_slave_driver_common::respond_trans_device_id_data(); // respond device id three byte
  mon_data_index=8;
  while((!trans_stop_flag) & (!trans_restart_flag)) begin
    // keep SDA under control
    for(int i=23; i>=0; i--) begin
      wait_data_hold_time();
      i2c_if.sda_slave = cfg.device_id[i];
      @(negedge i2c_if.SCL);
      mon_data_index--;
      if(mon_data_index==0) begin
        mon_data_index=8;
        wait_data_hold_time();
        i2c_if.sda_slave = 1'bz; // release bus to mst,
        @(negedge i2c_if.SCL);
      end
    end
  end
endtask: respond_trans_device_id_data

function void lvc_i2c_slave_driver_common::check_restart_once_finished_trans(lvc_i2c_slave_transaction trans);
  if(trans_restart_flag & mon_data_index!=0) begin
    update_trans_data(trans);
    $display("slv_driver trans data is %p",trans.data);
  end
endfunction: check_restart_once_finished_trans

`endif // LVC_I2C_slave_DRIVER_COMMON_SV
