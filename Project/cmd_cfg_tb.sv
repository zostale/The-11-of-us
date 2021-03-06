/*
* Testbench for cmd_cfg unit.
* Eric Heinz, Shyamal Anadkat, Sanjay Rajmohan 
* Ultimately will be project's top level testbench 
* Tests that all the basic commands work. 
*/
module cmd_cfg_tb ();

//// internal wires/stimuli ////
logic clk, rst_n, cnv_cmplt, cal_done, snd_cmd_stim;
logic [7:0] resp, batt, cmd_to_cfg, cmd_stim;
logic cmd_rdy, clr_cmd_rdy, snd_resp, resp_sent;
logic [15:0] d_ptch, d_roll, d_yaw, data_to_cfg, data_stim;
logic [8:0] thrst;
logic [7:0] resp_commMaster;
logic motors_off, strt_cnv, inertial_cal;
logic RX_TX, TX_RX;
reg [7:0] commands [7:0];
reg [15:0] data [7:0];

//// command encodings ////
localparam REQ_BATT 	= 8'h01;
localparam SET_PTCH 	= 8'h02;
localparam SET_ROLL	= 8'h03;
localparam SET_YAW  	= 8'h04;
localparam SET_THRST 	= 8'h05;
localparam CALIBRATE 	= 8'h06;
localparam EMER_LAND 	= 8'h07;
localparam MTRS_OFF 	= 8'h08;

// response params
localparam ACK = 8'ha5;

//// CommMaster iDUT instance. We apply stim to inputs to CommMaster ////
CommMaster masteriDUT(   
	.resp(resp_commMaster), 
	.resp_rdy(resp_rdy), 
	.frm_snt(frm_snt), 
	.TX(TX_RX), .RX(RX_TX), 
	.cmd(cmd_stim), 
	.snd_cmd(snd_cmd_stim), 
	.data(data_stim), 
	.clk(clk), .rst_n(rst_n));

//// UART Wrapper instantiation ////
UART_wrapper UART_wrapper_iDUT(
	//resp is input to wrapper
	.clk(clk), .rst_n(rst_n), 
	.RX(TX_RX), .TX(RX_TX), 
	.cmd(cmd_to_cfg), 
	.data(data_to_cfg), 
	.cmd_rdy(cmd_rdy), 
	.snd_resp(snd_resp), 
	.resp_sent(resp_sent), 
	.resp(resp), 
	.clr_cmd_rdy(clr_cmd_rdy));

//// cmd_cfg unit instantiation ////
// override timing width param with 9
cmd_cfg #(9) cmd_cfgiDUT (
	.d_ptch(d_ptch), .d_roll(d_roll),  .d_yaw(d_yaw), 
	.thrst (thrst),
	.resp(resp), 
	.send_resp(snd_resp), 
	.clr_cmd_rdy(clr_cmd_rdy), 
	.strt_cal(strt_cal), 
	.inertial_cal(inertial_cal),
	.motors_off(motors_off), 
	.strt_cnv(strt_cnv), 
	.data(data_to_cfg), 
	.cmd(cmd_to_cfg), 
	.batt(batt), 
	.cal_done(cal_done), 
	.cnv_cmplt(cnv_cmplt), 
	.cmd_rdy(cmd_rdy), .clk(clk), .rst_n(rst_n));

// initialize commands and values to test cmd_cfg
initial begin
	clk = 0;
	rst_n = 0;
	cal_done = 0;
	//cnv_cmplt = 0;
	batt = 8'h21;
	cnv_cmplt = 0;
	snd_cmd_stim = 0;
	cmd_stim = 0;
	data_stim = 0;
	// battery cmd
	commands[0] = REQ_BATT;
	// set pitch w/ value 6
	commands[1] = SET_PTCH;
	// set roll w/ value 4
	commands[2] = SET_ROLL;
	// set yaw w/ value 2
	commands[3] = SET_YAW;
	// set thrst with value 8
	commands[4] = SET_THRST;
	// cal copter
	commands[5] = CALIBRATE;
	// Emer land
	commands[6] = EMER_LAND;
	// motors off
	commands[7] = MTRS_OFF;
	
	// battery cmd
	data[0] = 16'h0000;
	// set pitch w/ value 6
	data[1] = 16'h0006;
	// set roll w/ value 4
	data[2] = 16'h0004;
	// set yaw w/ value 2
	data[3] = 16'h0002;
	// set thrst with value 8
	data[4] = 16'h0008;
	// cal copter
	data[5] = 16'h0000;
	// Emer land
	data[6] = 16'h0000;
	// motors off
	data[7] = 16'h0000;
end

always
	#10 clk = ~clk;

// begin tests
always begin
	@(posedge clk);
	@(negedge clk);
	rst_n = 1'b1;
	@(posedge clk);
	////////////////////////////////////
	//         BATTERY CMD TEST       //
	////////////////////////////////////
	cmd_stim = commands[0];
	data_stim = data[0];
	snd_cmd_stim = 1;
	@(posedge clk);
	snd_cmd_stim = 0;       // assert snd_cmd_stim for 1 cycle
	@(posedge cmd_rdy);
	repeat(2)@(posedge clk);
	cnv_cmplt = 1'b1;       // model ADC
	if (resp != batt) begin
		$display("Resp should be battery level");
		$stop();
	end
	@(posedge resp_rdy);
	////////////////////////////////////
	//         D_PTCH  CMD TEST       //
	////////////////////////////////////
	cmd_stim = commands[1];
	data_stim = data[1];
	snd_cmd_stim = 1;
	@(posedge clk);
	snd_cmd_stim = 0;       // assert snd_cmd_stim for 1 cycle
	@(posedge cmd_rdy);
	repeat(2)@(posedge clk);
    // see if value is set to expected value
	if (d_ptch != data[1]) begin
		$display("d_ptch set incorrectly");
		$stop();
	end
    // the response should be an ack
	if (resp != ACK) begin
		$display("Resp should be an ack");
		$stop();
	end
	@(posedge resp_rdy);    // wait for CommMaster to be ready
	////////////////////////////////////
	//         D_ROLL  CMD TEST       //
	////////////////////////////////////
	cmd_stim = commands[2];
	data_stim = data[2];
	snd_cmd_stim = 1;
	@(posedge clk);
	snd_cmd_stim = 0;       // assert snd_cmd_stim for 1 cycle
	@(posedge cmd_rdy);
	repeat(2)@(posedge clk);
    // see if value is set to expected value
	if (d_roll != data[2]) begin
		$display("d_roll set incorrectly");
		$stop();
	end
    // the response should be an ack
	if (resp != ACK) begin
		$display("Resp should be an ack");
		$stop();
	end
	@(posedge resp_rdy);    // wait for CommMaster to be ready
	////////////////////////////////////
	//         D_YAW   CMD TEST       //
	////////////////////////////////////
	cmd_stim = commands[3];
	data_stim = data[3];
	snd_cmd_stim = 1;
	@(posedge clk);
	snd_cmd_stim = 0;       // assert snd_cmd_stim for 1 cycle
	@(posedge cmd_rdy);
	repeat(2)@(posedge clk);
    // see if value is set to expected value
	if (d_yaw != data[3]) begin
		$display("d_yaw set incorrectly");
		$stop();
	end
    // the response should be an ack
	if (resp != ACK) begin
		$display("Resp should be an ack");
		$stop();
	end
	@(posedge resp_rdy);    // wait for CommMaster to be ready
	////////////////////////////////////
	//         THRST   CMD TEST       //
	////////////////////////////////////
	cmd_stim = commands[4];
	data_stim = data[4];
	snd_cmd_stim = 1;
	@(posedge clk);
	snd_cmd_stim = 0;       // assert snd_cmd_stim for 1 cycle
	@(posedge cmd_rdy);
	repeat(2)@(posedge clk);
    // see if value is set to expected value
	if (thrst != data[4]) begin
		$display("thrst set incorrectly");
		$stop();
	end
    // the response should be an ack
	if (resp != ACK) begin
		$display("Resp should be an ack");
		$stop();
	end
	@(posedge resp_rdy);    // wait for CommMaster to be ready
	////////////////////////////////////
	//       CALIBRATE CMD TEST       //
	////////////////////////////////////
	cmd_stim = commands[5];
	data_stim = data[5];
	snd_cmd_stim = 1;
	@(posedge clk);
	snd_cmd_stim = 0;       // assert snd_cmd_stim for 1 cycle
	// test if start_cal is held high for one cycle
	@(posedge strt_cal);
	@(posedge clk);
	@(negedge clk);
    // strt_cal should be a pulse
	if (strt_cal) begin
		$display("start_cal should only be high for one clk cycle");
		$stop();
	end
	@(posedge clk);
    // intertial_cal should be asserted when calibrating
	if (!inertial_cal) begin
		$display("calibrate incorrect");
		$stop();
	end
    // the response should be an ack
	if (resp != ACK) begin
		$display("Resp should be an ack");
		$stop();
	end
	cal_done = 1'b1;
	@(posedge resp_rdy);    // wait for CommMaster to be ready
	////////////////////////////////////
	//       EMERGENCY CMD TEST       //
	////////////////////////////////////
	cmd_stim = commands[6];
	data_stim = data[6];
	snd_cmd_stim = 1;
	@(posedge clk);
	snd_cmd_stim = 0;       // assert snd_cmd_stim for 1 cycle
	@(posedge cmd_rdy);
	repeat(2)@(posedge clk);
    // flight values should all be zero
	if (d_yaw != 0 || d_roll != 0 || d_ptch != 0 || thrst != 0) begin
		$display("Emergency command incorrect");
		$stop();
	end
    // the response should be an ack
	if (resp != ACK) begin
		$display("Resp should be an ack");
		$stop();
	end
	@(posedge resp_rdy);    // wait for CommMaster to be ready
	////////////////////////////////////
	//      MOTORS OFF CMD TEST       //
	////////////////////////////////////
	data_stim = data[7];
	cmd_stim = 8'h06;
	snd_cmd_stim = 1;
	@(posedge clk);
	snd_cmd_stim = 0;       // assert snd_cmd_stim for 1 cycle
	@(posedge cmd_rdy);
	repeat(2)@(posedge clk);
    // motors_off should be asserted
	if (motors_off) begin
		$display("Motors should be off");
		$stop();
	end
	snd_cmd_stim = 1'b0;
	cal_done = 1'b1;
	@(posedge resp_rdy);

	$display("Tests passed");
	$stop();
end
endmodule
