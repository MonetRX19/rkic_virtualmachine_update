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
`ifndef LVC_I2C_SLAVE_MONITOR_COMMON_SV
`define LVC_I2C_SLAVE_MONITOR_COMMON_SV

class lvc_i2c_slave_monitor_common extends lvc_i2c_monitor_common;
  `uvm_object_utils_begin(lvc_i2c_slave_monitor_common)
  `uvm_object_utils_end

  function new(string name = "lvc_i2_slave_monitor_common");
    super.new(name);
  endfunction

endclass: lvc_i2c_slave_monitor_common

`endif // LVC_I2C_SLAVE_MONITOR_COMMON_SV
