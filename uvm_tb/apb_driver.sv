`define DRIVAPB_IF vifapb.DRIVER.driver_cb

class apb_driver extends uvm_driver #(apb_transaction);
	`uvm_component_utils(apb_driver)

	virtual apb_if		vifapb;
	apb_transaction 	trans_collected_drv; 
  	uart_config 		cfg; // Handle to  a cfg class 
	uvm_analysis_port #(apb_transaction) item_collected_port_drv;

	function new (string name, uvm_component parent);
		super.new(name, parent);
	endfunction : new

	extern virtual function void build_phase(uvm_phase phase);
	extern virtual function void connect_phase(uvm_phase phase);
	extern virtual task run_phase(uvm_phase phase);
	extern virtual task drive(apb_transaction req);  

endclass

  	// --------------------------------------- 
  	// build phase
  	// ---------------------------------------
  	function void apb_driver::build_phase(uvm_phase phase);
  		super.build_phase(phase);  
      	trans_collected_drv = new();
      	item_collected_port_drv = new("item_collected_port_drv", this);
		if(!uvm_config_db#(uart_config)::get(this, "", "cfg", cfg))
			`uvm_fatal("No cfg",{"Configuration must be set for: ",get_full_name(),".cfg"});
  	endfunction: build_phase

	// --------------------------------------- 
  	// Conenct phase
  	// ---------------------------------------
	function void apb_driver::connect_phase(uvm_phase phase);
        super.connect_phase(phase);
	   	if(!uvm_config_db#(virtual apb_if)::get(this, "", "vifapb", vifapb))
  	    	`uvm_fatal("NO_VIF",{"virtual interface must be set for: ",get_full_name(),".vifapb"});
    endfunction : connect_phase  

  	// ---------------------------------------  
  	//  run phase
  	// ---------------------------------------  
  	task apb_driver::run_phase(uvm_phase phase);
  		apb_transaction req;
  	  	forever 
  	  	begin
			@(posedge vifapb.PCLK iff (vifapb.PRESETn))
			`DRIVAPB_IF.PSELx		<= 0;
			`DRIVAPB_IF.PENABLE		<= 0;  
			`DRIVAPB_IF.PWRITE		<= 0;
  	  		`DRIVAPB_IF.PWDATA		<= 0;
  	  		`DRIVAPB_IF.PADDR		<= 0;  
  	    	seq_item_port.get_next_item(req);
  	    	drive(req);
 			`uvm_info("APB_DRIVER_TR", $sformatf("APB Finished Driving Transfer \n%s",req.sprint()), UVM_HIGH)
  	    	seq_item_port.item_done();
  	  	end
  	endtask : run_phase
	
  	//---------------------------------------------------------
  	// drive - transaction level to signal level
  	// drives the value's from seq_item to interface signals
  	//--------------------------------------------------------
	
  	task apb_driver::drive(apb_transaction req);
		`DRIVAPB_IF.PSELx			<= 1;
		@(posedge vifapb.DRIVER.PCLK);
		`DRIVAPB_IF.PENABLE			<= 1;
  	  	`DRIVAPB_IF.PWRITE			<= req.PWRITE;
		if(req.PADDR == cfg.baud_config_addr)
			`DRIVAPB_IF.PWDATA			<= cfg.bRate;
		else if (req.PADDR == cfg.frame_config_addr)
			`DRIVAPB_IF.PWDATA			<= cfg.frame_len;
		else if (req.PADDR == cfg.parity_config_addr)
			`DRIVAPB_IF.PWDATA			<= cfg.parity;
		else if (req.PADDR == cfg.stop_bits_config_addr)
			`DRIVAPB_IF.PWDATA			<= cfg.n_sb;	
		else
			`DRIVAPB_IF.PWDATA			<= req.PWDATA;
  	  	`DRIVAPB_IF.PADDR			<= req.PADDR;
		trans_collected_drv.PWRITE 	 = req.PWRITE;	
		trans_collected_drv.PADDR 	 = req.PADDR;
		trans_collected_drv.PWDATA 	 = req.PWDATA;
		wait(`DRIVAPB_IF.PREADY);		
		`DRIVAPB_IF.PSELx			<= 0;
		`DRIVAPB_IF.PENABLE			<= 0;
		wait(!`DRIVAPB_IF.PREADY);
		item_collected_port_drv.write(trans_collected_drv); // It sends the transaction non-blocking and it
  	endtask
