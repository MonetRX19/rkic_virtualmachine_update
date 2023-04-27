/////////////////////////////////////////////////////////////////////////////////////
// Copyright 2020 seabeam@yahoo.com - Licensed under the Apache License, Version 2.0
// For more information, see LICENCE in the main folder
/////////////////////////////////////////////////////////////////////////////////////
`ifndef GUARD_YUU_AHB_MASTER_ITEM_SV
`define GUARD_YUU_AHB_MASTER_ITEM_SV

// Class: yuu_ahb_master_item
// AHB master transaction.
class yuu_ahb_master_item extends yuu_ahb_item;
  // Variable: cfg
  // AHB master agent configuration object.
  yuu_ahb_master_config cfg;

  // Variable: idle_delay
  // Idle cycles between transactions.
  rand int unsigned idle_delay;

  // Variable: busy_delay
  // Busy hold cycles inside burst transfer.
  rand int unsigned busy_delay[];

  // Constraint: c_idle
  // idle_delay range constraint.
  constraint c_idle {
    soft idle_delay inside {[0:`YUU_AHB_MAX_DELAY]};
    if (!cfg.idle_enable) {
      idle_delay == 0;
    }
  }

  // Constraint: c_busy
  // busy_delay range constraint.
  constraint c_busy {
    busy_delay.size() == len+1;
    foreach (busy_delay[i]) {
      soft busy_delay[i] inside {[0:`YUU_AHB_MAX_DELAY]};
      if (!cfg.busy_enable || len == 0) {
        busy_delay[i] == 0;
      }
    }
  }

  `uvm_object_utils_begin(yuu_ahb_master_item)
    `uvm_field_int      (idle_delay, UVM_PRINT | UVM_COPY)
    `uvm_field_array_int(busy_delay, UVM_PRINT | UVM_COPY)
  `uvm_object_utils_end

  extern function      new(string name="yuu_ahb_master_item");
  extern function void pre_randomize();
  extern function void command_process();
  extern function void data_process();
endclass

// Function: new
// Constructor of object.
function yuu_ahb_master_item::new(string name="yuu_ahb_master_item");
  super.new(name);
endfunction

// Function: pre_randomize
// SV built-in function.
function void yuu_ahb_master_item::pre_randomize();
  if (!uvm_config_db #(yuu_ahb_master_config)::get(null, get_full_name(), "cfg", cfg) && cfg == null)
    `uvm_fatal("pre_randomize", "Cannot get AHB configuration in transaction")

  if (!cfg.use_protection_transfers) begin
    prot0.rand_mode(0);
    prot1.rand_mode(0);
    prot2.rand_mode(0);
    prot3_emt.rand_mode(0);
    prot4_emt.rand_mode(0);
    prot5_emt.rand_mode(0);
    prot6_emt.rand_mode(0);
  end
  if (!cfg.use_extended_memory_types) begin
    prot3_emt.rand_mode(0);
    prot4_emt.rand_mode(0);
    prot5_emt.rand_mode(0);
    prot6_emt.rand_mode(0);
  end
  if (!cfg.use_locked_transfers) begin
    lock.rand_mode(0);
  end
  if (!cfg.use_secure_transfers) begin
    nonsec.rand_mode(0);
  end
  if (!cfg.use_exclusive_transfers) begin
    excl.rand_mode(0);
  end
endfunction

// Function: command_process
// Process AHB command information.
function void yuu_ahb_master_item::command_process();
  super.command_process();

  // Trans
  trans = new[len+1];
  foreach (trans[i])
    trans[i] = SEQ;
  trans[0] = NONSEQ;
  if (!cfg.use_busy_end || (cfg.use_busy_end && burst != INCR)) begin
    busy_delay[len] = 0;
  end
  busy_delay[0] = 0;
endfunction

// Function: data_process
// Process AHB data information.
function void yuu_ahb_master_item::data_process();
  super.data_process();

  foreach (response[i])
    response[i] = OKAY;
endfunction

`endif