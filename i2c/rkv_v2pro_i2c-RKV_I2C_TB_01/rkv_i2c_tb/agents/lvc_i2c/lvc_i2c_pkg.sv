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


`ifndef LVC_I2C_PKG_SV
`define LVC_I2C_PKG_SV

package lvc_i2c_pkg;

import uvm_pkg::*;
`include "uvm_macros.svh"

`include "lvc_i2c_defines.svh"
`include "lvc_i2c_types.sv"
`include "lvc_configuration.sv"
`include "lvc_i2c_configuration.sv"
`include "lvc_i2c_agent_configuration.sv"
`include "lvc_i2c_transaction.sv"
`include "lvc_i2c_bfm_common.sv"
`include "lvc_i2c_sequencer.sv"

`include "lvc_i2c_master_transaction.sv"
`include "lvc_i2c_master_sequencer.sv"
`include "lvc_i2c_master_monitor_common.sv"
`include "lvc_i2c_master_monitor.sv"
`include "lvc_i2c_master_driver_callback.sv"
`include "lvc_i2c_master_driver_common.sv"
`include "lvc_i2c_master_driver.sv"
`include "lvc_i2c_master_agent.sv"

`include "lvc_i2c_slave_transaction.sv"
`include "lvc_i2c_slave_sequencer.sv"
`include "lvc_i2c_slave_monitor_common.sv"
`include "lvc_i2c_slave_monitor.sv"
`include "lvc_i2c_slave_driver_common.sv"
`include "lvc_i2c_slave_driver.sv"
`include "lvc_i2c_slave_agent.sv"

`include "lvc_i2c_system_configuration.sv"
`include "lvc_i2c_system_sequencer.sv"
`include "lvc_i2c_system_env.sv"


endpackage : lvc_i2c_pkg

   
`endif //  `ifndef LVC_I2C_PKG_SV
