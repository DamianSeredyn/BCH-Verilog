module __testsuite;
  import svunit_pkg::svunit_testsuite;

  string name = "__ts";
  svunit_testsuite svunit_ts;
  
  
  //===================================
  // These are the unit tests that we
  // want included in this testsuite
  //===================================
  modul_studenta_unit_test modul_studenta_ut();


  //===================================
  // Build
  //===================================
  function void build();
    modul_studenta_ut.build();
    modul_studenta_ut.__register_tests();
    svunit_ts = new(name);
    svunit_ts.add_testcase(modul_studenta_ut.svunit_ut);
  endfunction


  //===================================
  // Run
  //===================================
  task run();
    svunit_ts.run();
    modul_studenta_ut.run();
    svunit_ts.report();
  endtask

endmodule
