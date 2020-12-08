module testbench #(
  parameter DATA_WIDTH = 32,
  parameter ADDR_WIDTH = 32
)
(
	input  logic 				t_PCLK,
    input  logic 				t_PRESETn,
	output logic            	RX,
    input  logic            	Tx
);

	assign RX     			= vifuart.RX;
  	assign vifuart.Tx 		= Tx;

  	apb_if  #(DATA_WIDTH,ADDR_WIDTH) vifapb  (t_PCLK,t_PRESETn); 
  	uart_if           				 vifuart (t_PCLK,t_PRESETn);

  	apbuart_property assertions (
                                .PCLK(t_PCLK),
                                .PRESETn(t_PRESETn),
                                .PSELx(vifapb.PSELx),
                                .PENABLE(vifapb.PENABLE),
                                .PWRITE(vifapb.PWRITE),
                                .PREADY(vifapb.PREADY),
                                .PSLVERR(vifapb.PSLVERR),
                                .PWDATA(vifapb.PWDATA),
                                .PADDR(vifapb.PADDR),
                                .PRDATA(vifapb.PRDATA)
                              );
  	initial
  	begin
    	uvm_config_db # (virtual apb_if)::set(uvm_root::get(),"*","vifapb",vifapb);
    	uvm_config_db # (virtual uart_if)::set(uvm_root::get(),"*","vifuart",vifuart);
    	uvm_config_db # (virtual clk_rst_interface)::set(uvm_root::get(),"*","vifclk",vifclk);
    	$dumpfile("dump.vcd");
    	$dumpvars;
  	end
  	initial
    	run_test(); // built in func...you can give test name as argument
endmodule