transcript on

add wave -position insertpoint  \
sim:/testrunner/__ts/modul_studenta_ut/dut/rst \
sim:/testrunner/__ts/modul_studenta_ut/dut/clk \
sim:/testrunner/__ts/modul_studenta_ut/dut/s_axil_awready \
sim:/testrunner/__ts/modul_studenta_ut/dut/s_axil_awvalid \
sim:/testrunner/__ts/modul_studenta_ut/dut/s_axil_awaddr \
sim:/testrunner/__ts/modul_studenta_ut/dut/s_axil_awprot \
sim:/testrunner/__ts/modul_studenta_ut/dut/s_axil_wready \
sim:/testrunner/__ts/modul_studenta_ut/dut/s_axil_wvalid \
sim:/testrunner/__ts/modul_studenta_ut/dut/s_axil_wdata \
sim:/testrunner/__ts/modul_studenta_ut/dut/s_axil_wstrb \
sim:/testrunner/__ts/modul_studenta_ut/dut/s_axil_bready \
sim:/testrunner/__ts/modul_studenta_ut/dut/s_axil_bvalid \
sim:/testrunner/__ts/modul_studenta_ut/dut/s_axil_bresp \
sim:/testrunner/__ts/modul_studenta_ut/dut/s_axil_arready \
sim:/testrunner/__ts/modul_studenta_ut/dut/s_axil_arvalid \
sim:/testrunner/__ts/modul_studenta_ut/dut/s_axil_araddr \
sim:/testrunner/__ts/modul_studenta_ut/dut/s_axil_arprot \
sim:/testrunner/__ts/modul_studenta_ut/dut/s_axil_rready \
sim:/testrunner/__ts/modul_studenta_ut/dut/s_axil_rvalid \
sim:/testrunner/__ts/modul_studenta_ut/dut/s_axil_rdata \
sim:/testrunner/__ts/modul_studenta_ut/dut/s_axil_rresp \
sim:/testrunner/__ts/modul_studenta_ut/dut/LED \
sim:/testrunner/__ts/modul_studenta_ut/dut/hwif_out

view structure
view signals

TreeUpdate [SetDefaultTree]
quietly wave cursor active 1
configure wave -namecolwidth 150
configure wave -valuecolwidth 80
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ps
update

log -r /*