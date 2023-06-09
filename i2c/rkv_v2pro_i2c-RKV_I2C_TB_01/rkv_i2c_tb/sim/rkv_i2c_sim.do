#======================================#
# TCL script for a mini regression     #
#======================================#
onbreak resume
onerror resume

# set environment variables
setenv DUT_SRC ../../rkv_dw_apb_i2c
setenv TB_SRC .

set INCDIR "+incdir+../../rkv_dw_apb_i2c/src \
					  +incdir+../agents/lvc_apb3 \
					  +incdir+../agents/lvc_i2c \
					  +incdir+../cfg \
					  +incdir+../cov \
					  +incdir+../reg \
					  +incdir+../env \
					  +incdir+../seq_lib \
					  +incdir+../seq_lib/elem_seqs \
					  +incdir+../seq_lib/user_elem_seqs \
					  +incdir+../seq_lib/user_virt_seqs \
					  +incdir+../tests/user_tests \
					  +incdir+../tests "

set VCOMP "vlog -timescale=1ns/1ps -l comp.log $INCDIR"


# clean the environment and remove trash files
set delfiles [glob work *.log *.ucdb sim.list]

file delete -force {*}$delfiles

# compile the design and dut with a filelist
vlib work
eval $VCOMP -f  rkv_i2c.flist
eval $VCOMP -sv ../agents/lvc_apb3/lvc_apb_if.sv 
eval $VCOMP -sv ../agents/lvc_apb3/lvc_apb_pkg.sv 
eval $VCOMP -sv ../agents/lvc_i2c/lvc_i2c_if.sv 
eval $VCOMP -sv ../agents/lvc_i2c/lvc_i2c_pkg.sv 
eval $VCOMP -sv ../env/rkv_i2c_pkg.sv 
eval $VCOMP -sv ../tb/rkv_i2c_if.sv 
eval $VCOMP -sv ../tb/rkv_i2c_tb.sv 

# call a UVM test
set TEST rkv_i2c_quick_reg_access_test
set VERB UVM_HIGH
set SEED 0
#set SEED [expr int(rand() * 100)]
vsim work.rkv_i2c_tb -sv_seed $SEED +UVM_TESTNAME=$TEST +UVM_VERBOSITY=$VERB -l sim.log

