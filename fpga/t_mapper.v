

module t_mapper (

	   //74lvc245 buffer signals
	    //address bus
		input [15:0] ex_bus_addr,

		//data bus
		inout [7:0] ex_bus_dout,
		output ex_bus_data_reverse_n,
		
		//control bus
		input ex_bus_mreq_n,
		input ex_bus_iorq_n,
		input ex_bus_rd_n,
		input ex_bus_wr_n,
		input ex_bus_reset_n,
		input ex_bus_clk_3m6,
        input ex_bus_sltsl_n,
        input ex_bus_rfsh_n,
		
		//interrupt
		//out ex_int_n,

		//fpga signals
		input ex_reset_n,
        input ex_clk_27m,
        input ex_btn0,
        output [5:0] ex_led,

        // Magic ports for PSRAM to be inferred
        output [1:0] O_psram_ck,
        output [1:0] O_psram_ck_n,
        inout [1:0] IO_psram_rwds,
        inout [15:0] IO_psram_dq,
        output [1:0] O_psram_reset_n,
        output [1:0] O_psram_cs_n
	);


	wire [15:0] bus_addr;
	wire [7:0] bus_dout;
		
	wire bus_mreq_n;
	wire bus_iorq_n;
	wire bus_rd_n;
	wire bus_wr_n;
	wire bus_reset_n;
	wire bus_clk_3m6;
    wire bus_sltsl_n;
    wire bus_rfsh_n;

    //bus isolation
    reg bus_data_reverse;

    //mapper signals
    wire mapper_read;
    wire mapper_write;
    reg [7:0] mapper_reg0;
    reg [7:0] mapper_reg1;
    reg [7:0] mapper_reg2;
    reg [7:0] mapper_reg3;
    wire mapper_reg_write;

    //read/write signals
	wire mreq_wr_n;
	wire mreq_rd_n;
	wire iorq_wr_n;
	wire iorq_rd_n;

    //clocks
    wire clk_72m;
    wire clk_72m_p;

    //denoise signals
    wire [7:0] ex_control_bus;
    wire [7:0] control_bus;

    //monostable signals
    wire monostable_out;

    //psram signals
    reg psram_read;
    reg psram_write;
    reg [21:0] psram_addr;
    reg [15:0] psram_din;
    wire [15:0] psram_dout;
    wire psram_busy;

    localparam [3:0] IDLE = 4'd0;
    localparam [3:0] ADDR = 4'd1;
    localparam [3:0] READ1 = 4'd2;
    localparam [3:0] READ2 = 4'd3;
    localparam [3:0] READ3 = 4'd4;
    localparam [3:0] READ4 = 4'd5;
    localparam [3:0] WRITE1 = 4'd6;
    localparam [3:0] WRITE2 = 4'd7;
    localparam [3:0] WRITE3 = 4'd8;

    //psram state machine signals
    //type type_status is (idle, addr, read1, read2, read3, read4, write1, write2, write3);
    reg [3:0] fsm_status;
    reg [15:0] fsm_addr; //bus address latched
    reg [7:0] fsm_din; //bus data latched
    reg [7:0] fsm_dout; //8 bits output data

    //check psram state machine signals
    localparam [2:0] STATE1 = 4'd0;
    localparam [2:0] STATE2 = 4'd1;
    localparam [2:0] STATE3 = 4'd2;
    localparam [2:0] STATE4 = 4'd3;
    localparam [2:0] STATE5 = 4'd4;

    //type type_status2 is (state1, state2, state3, state4, state5);
    reg [2:0] check_fsm_status;
    reg [7:0] check_fsm_counter;
    reg [7:0] check_fsm_counter_max;


// ____________________________________________________________________________________
// clock signals

Gowin_rPLL clock1(
    .clkout (clk_72m),
    .clkoutp (clk_72m_p),
    .clkin (ex_clk_27m)
    );


// ____________________________________________________________________________________
// MEMORY READ/WRITE LOGIC GOES HERE
assign iorq_wr_n = bus_wr_n | bus_iorq_n;
assign mreq_wr_n = bus_wr_n | bus_mreq_n;
assign iorq_rd_n = bus_rd_n | bus_iorq_n;
assign mreq_rd_n = bus_rd_n | bus_mreq_n;


// ____________________________________________________________________________________
// BUS ISOLATION GOES HERE
//ex_bus_dout <= fsm_dout when bus_data_reverse = '1' else (others => 'Z');
assign ex_bus_dout = bus_data_reverse?fsm_dout:{8{1'bZ}};
assign ex_bus_data_reverse_n = ~ bus_data_reverse;



//bus denoise
assign ex_control_bus = {ex_bus_mreq_n, ex_bus_iorq_n, ex_bus_rd_n, ex_bus_wr_n, ex_bus_reset_n, ex_bus_clk_3m6, ex_bus_sltsl_n, ex_bus_rfsh_n};
assign bus_mreq_n = control_bus[7];
assign bus_iorq_n = control_bus[6];
assign bus_rd_n = control_bus[5];
assign bus_wr_n = control_bus[4];
assign bus_reset_n = control_bus[3];
assign bus_clk_3m6 = control_bus[2];
assign bus_sltsl_n = control_bus[1];
assign bus_rfsh_n = control_bus[0];

denoise_low8 denoise8_1(
		.data8_in(ex_control_bus),
		.clock (clk_72m),
		.data8_out(control_bus)
    );

denoise_8 denoise8_2(
		.data8_in(ex_bus_addr[7:0]),
		.clock(clk_72m),
		.data8_out(bus_addr[7:0])
    );

denoise_8 denoise8_3(
		.data8_in(ex_bus_addr[15:8]),
		.clock	(clk_72m),
		.data8_out	( bus_addr[15:8])
    );

denoise_8 denoise8_4(
		.data8_in (ex_bus_dout),
		.clock	(clk_72m),
		.data8_out	(bus_dout)
    );

monostable mono1 (
		.pulse_in (mapper_read | mapper_write),
		.clock (ex_clk_27m),
		.pulse_out_n ( monostable_out)
	);

PsramController  #(
        .FREQ (72000000), //Actual clk frequency, to time 150us initialization delay
        .LATENCY(3)         //tACC (Initial Latency) in W955D8MBYA datasheet:
                             //3 (max 83Mhz), 4 (max 104Mhz), 5 (max 133Mhz) or 6 (max 166Mhz)
    ) pram1 (
        .clk    (clk_72m),
        .clk_p  (clk_72m_p), // phase-shifted clock for driving O_psram_ck
        .resetn (bus_reset_n),
        .read   (psram_read), // Set to 1 to read from RAM
        .write  (psram_write), // Set to 1 to write to RAM
        .addr   (psram_addr), // Byte address to read / write
        .din    (psram_din), // Data word to write
        .byte_write (1'b1), // When writing, only write one byte instead of the whole word. 
                                    // addr[0]==1 means we write the upper half of din. lower half otherwise.
        .dout   (psram_dout), //: out std_logic_vector (15 downto 0); -- Last read data. Read is always word-based.
        .busy   (psram_busy), //: out std_logic; -- 1 while an operation is in progress

        // HyperRAM physical interface. Gowin interface is for 2 dies. 
        // We currently only use the first die (4MB).
        .O_psram_ck (O_psram_ck),
        .IO_psram_rwds (IO_psram_rwds),
        .IO_psram_dq (IO_psram_dq),
        .O_psram_cs_n (O_psram_cs_n)
    );

//mapper
//mapper_read <= '1' when (mreq_rd_n='0') and (bus_sltsl_n = '0') and (bus_rfsh_n = '1') and bus_reset_n = '1' else '0';
assign mapper_read = ( (mreq_rd_n==1'b0) && (bus_sltsl_n == 1'b0) && (bus_rfsh_n == 1'b1) && (bus_reset_n == 1'b1) )?1'b1:1'b0;
//mapper_write <= '1' when (mreq_wr_n='0') and (bus_sltsl_n = '0') and (bus_rfsh_n = '1') and bus_reset_n = '1' else '0';
assign mapper_write = ( (mreq_wr_n==1'b0) && (bus_sltsl_n == 1'b0) && (bus_rfsh_n == 1'b1) && (bus_reset_n == 1'b1) )?1'b1:1'b0;
//mapper_reg_write <= '1' when iorq_wr_n = '0' and bus_addr (7 downto 2) = "111111" else '0';
assign mapper_reg_write = ( (iorq_wr_n == 1'b0) && (bus_addr [7:2] == 6'b111111) )?1'b1:1'b0;

always @(bus_reset_n or mapper_reg_write) begin
    if (bus_reset_n == 1'b0) begin
        mapper_reg0	<= 8'b00000011;
        mapper_reg1	<= 8'b00000010;
        mapper_reg2	<= 8'b00000001;
        mapper_reg3	<= 8'b00000000;
    end
    else if (mapper_reg_write == 1'b1) begin
        case (bus_addr[1:0])
            2'b00: mapper_reg0 <= bus_dout;
            2'b01: mapper_reg1 <= bus_dout;
            2'b10: mapper_reg2 <= bus_dout;
            2'b11: mapper_reg3 <= bus_dout;
        endcase
    end
end


//fsm
always @(posedge clk_72m or negedge bus_reset_n) begin
    if (bus_reset_n == 1'b0) begin
        fsm_status <=  IDLE;
        psram_read <= 1'b0;
        psram_write <= 1'b0;
        bus_data_reverse <= 1'b0;
    end
    else begin
        case (fsm_status)
            IDLE: begin
                fsm_addr <= bus_addr;
                fsm_din <= bus_dout;
                if (mapper_write == 1'b1)
                    fsm_status <= WRITE1;
                else if (mapper_read == 1'b1) 
                    fsm_status <= READ1;

            end
            WRITE1: begin
                //psram_addr <= "000000" & fsm_addr;
                case (fsm_addr[15:14])
                    2'b00 :
                        psram_addr <= { mapper_reg0, fsm_addr[13:0] };
                    2'b01 :
                        psram_addr <= { mapper_reg1, fsm_addr[13:0] };
                    2'b10 :
                        psram_addr <= { mapper_reg2, fsm_addr[13:0] };
                    2'b11 :
                        psram_addr <= { mapper_reg3, fsm_addr[13:0] };
                endcase
                psram_din <= { fsm_din, fsm_din};
                psram_write <= 1'b1;
                fsm_status <= WRITE2;
            end
            WRITE2: begin
                psram_write <= 1'b0;
                fsm_status <= WRITE3;
            end
            WRITE3 : begin
                if ( (psram_busy == 1'b0) && (mapper_write == 1'b0) )
                    fsm_status <= IDLE;

            end
            READ1 : begin
                //psram_addr <= "000000" & fsm_addr;
                case (fsm_addr[15:14])
                    2'b00 :
                        psram_addr <= { mapper_reg0, fsm_addr[13:0] };
                    2'b01 :
                        psram_addr <= { mapper_reg1, fsm_addr[13:0] };
                    2'b10 :
                        psram_addr <= { mapper_reg2, fsm_addr[13:0] };
                    2'b11 :
                        psram_addr <= { mapper_reg3, fsm_addr[13:0] };
                endcase
                psram_read <= 1'b1;
                fsm_status <= READ2;
            end
            READ2: begin
                psram_read <= 1'b0;
                fsm_status <= READ3;
            end
            READ3: begin
                if (psram_busy == 1'b0) begin
                    if (psram_addr[0] == 1'b0)
                        fsm_dout <= psram_dout[7:0];
                    else
                        fsm_dout <= psram_dout[15:8];

                    bus_data_reverse <= 1'b1;
                    fsm_status <= READ4;
                end
            end
            READ4: begin
                if (mapper_read == 1'b0) begin
                    bus_data_reverse <= 1'b0;
                    fsm_status <= IDLE;
                end
            end
            default:
                fsm_status <= IDLE;
        endcase
    end
end
/*

check_fsm : process (clk_72m, bus_reset_n)
begin
    if bus_reset_n = '0' then
        check_fsm_counter       <= (others => '0');
        check_fsm_counter_max   <= (others => '0');
        check_fsm_status        <= state1;
    else
        if rising_edge(clk_72m) then
            case check_fsm_status is
                when state1 =>
                    check_fsm_counter <= (others => '0');
                    if mapper_write = '1' or mapper_read = '1' then
                        check_fsm_status <= state2;
                    end if;
                when state2 =>
                    if psram_busy = '0' then
                        check_fsm_status <= state3;
                    end if;
                when state3 =>
                    if psram_busy = '1' then
                        check_fsm_status <= state4;
                    end if;
                when state4 =>
                    check_fsm_counter <= check_fsm_counter + 1;
                    if psram_busy = '0' then
                        check_fsm_status <= state5;
                    end if;
                when state5 =>
                    if check_fsm_counter > check_fsm_counter_max then
                        check_fsm_counter_max <= check_fsm_counter;
                    end if;
                    check_fsm_status <= state1;
                when others =>
                    null;
            end case;
        end if;
    end if;
end process check_fsm;
*/

//assign ex_led = { ex_bus_data_reverse_n, 5'b1111, 1'b1 }; //monostable_out };
assign ex_led = { ex_bus_data_reverse_n , 4'b1111, monostable_out };


endmodule