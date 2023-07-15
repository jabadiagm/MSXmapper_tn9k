

library ieee;
use ieee.std_logic_1164.all;
use  IEEE.STD_LOGIC_ARITH.all;
use  IEEE.STD_LOGIC_UNSIGNED.all;

entity t_mapper is
	port(

	   --74lvc245 buffer signals
	    --address bus
		ex_bus_addr    : in std_logic_vector(15 downto 0);

		--data bus
		ex_bus_dout     : inout std_logic_vector(7 downto 0);
		ex_bus_data_reverse_n : out std_logic;
		
		--control bus
		ex_bus_mreq_n     : in std_logic;
		ex_bus_iorq_n     : in std_logic;
		ex_bus_rd_n       : in std_logic;
		ex_bus_wr_n       : in std_logic;
		ex_bus_reset_n    : in std_logic;
		ex_bus_clk_3m6   : in std_logic;
        ex_bus_sltsl_n   : in std_logic;
        ex_bus_rfsh_n    : in std_logic;
		
		--interrupt
		--ex_int_n         : out std_logic;

		--fpga signals
		ex_reset_n    : in  std_logic:='1';
        ex_clk_27m	  : in std_logic:='0';
        ex_btn0	      : in std_logic:='0';
        ex_led          : out  STD_LOGIC_VECTOR (5 downto 0);

        -- Magic ports for PSRAM to be inferred
        O_psram_ck     : out std_logic_vector(1 downto 0); 
        O_psram_ck_n     : out std_logic_vector(1 downto 0);
        IO_psram_rwds     : inout std_logic_vector(1 downto 0);
        IO_psram_dq     : inout std_logic_vector(15 downto 0);
        O_psram_reset_n     : out std_logic_vector(1 downto 0);
        O_psram_cs_n     : out std_logic_vector(1 downto 0)

	);
end t_mapper;

architecture struct of t_mapper is

	signal bus_addr	 : std_logic_vector(15 downto 0);
	signal bus_dout    : std_logic_vector(7 downto 0);
		
	signal bus_mreq_n     : std_logic;
	signal bus_iorq_n     : std_logic;
	signal bus_rd_n       : std_logic;
	signal bus_wr_n       : std_logic;
	signal bus_reset_n    : std_logic;
	signal bus_clk_3m6   : std_logic;
    signal bus_sltsl_n   : std_logic;
    signal bus_rfsh_n    : std_logic;

    --bus isolation
    signal bus_data_reverse : std_logic; 

    --mapper signals
    signal mapper_read  : std_logic;
    signal mapper_write : std_logic;
    signal mapper_reg0  : std_logic_vector(7 downto 0);
    signal mapper_reg1  : std_logic_vector(7 downto 0);
    signal mapper_reg2  : std_logic_vector(7 downto 0);
    signal mapper_reg3  : std_logic_vector(7 downto 0);
    signal mapper_reg_write : std_logic;

    --read/write signals
	signal mreq_wr_n						: std_logic :='1';
	signal mreq_rd_n 					    : std_logic :='1';
	signal iorq_wr_n						: std_logic :='1';
	signal iorq_rd_n 						: std_logic :='1';

    --clocks
    signal clk_72m                  : std_logic;
    signal clk_72m_p                : std_logic;

    --denoise signals
    signal ex_control_bus   : std_logic_vector(7 downto 0);
    signal control_bus      : std_logic_vector(7 downto 0);

    --monostable signals
    signal monostable_out   : std_logic;

    --psram signals
    signal psram_read   : std_logic;
    signal psram_write   : std_logic;
    signal psram_addr   : std_logic_vector(21 downto 0);
    signal psram_din    : std_logic_vector (15 downto 0);
    signal psram_dout   : std_logic_vector (15 downto 0);
    signal psram_busy   : std_logic;

    --psram state machine signals
    type type_status is (idle, addr, read1, read2, read3, read4, write1, write2, write3);
    signal fsm_status   : type_status;
    signal fsm_addr  : std_logic_vector(15 downto 0); --bus address latched
    signal fsm_din  : std_logic_vector (7 downto 0); --bus data latched
    signal fsm_dout : std_logic_vector (7 downto 0); --8 bits output data

    --check psram state machine signals
    type type_status2 is (state1, state2, state3, state4, state5);
    signal check_fsm_status         : type_status2;
    signal check_fsm_counter        : std_logic_vector(7 downto 0);
    signal check_fsm_counter_max    : std_logic_vector(7 downto 0);

	
component Gowin_rPLL
    port (
        clkout: out std_logic;
        clkoutp : out std_logic;
        clkin: in std_logic
    );
end component;

component denoise_low
    port (
		data_in		: IN STD_LOGIC;
		clock		: IN STD_LOGIC;
		data_out	: OUT STD_LOGIC 
    );
end component;

component denoise_low8	
	PORT
	(
		data8_in	: IN STD_LOGIC_VECTOR(7 downto 0);
		clock		: IN STD_LOGIC  := '1';
		data8_out	: OUT STD_LOGIC_VECTOR(7 downto 0) 
	);
end component;

component denoise
    port (
		data_in		: IN STD_LOGIC;
		clock		: IN STD_LOGIC;
		data_out	: OUT STD_LOGIC 
    );
end component;

component denoise_8	
	PORT
	(
		data8_in	: IN STD_LOGIC_VECTOR(7 downto 0);
		clock		: IN STD_LOGIC  := '1';
		data8_out	: OUT STD_LOGIC_VECTOR(7 downto 0) 
	);
end component;

component monostable
	PORT
	(
		pulse_in	: IN STD_LOGIC;
		clock		: IN STD_LOGIC;
		pulse_out_n	: OUT STD_LOGIC 
	);
END component;

component PsramController
    generic (
        FREQ : natural;   --Actual clk frequency, to time 150us initialization delay
        LATENCY : natural --tACC (Initial Latency) in W955D8MBYA datasheet:
                          --3 (max 83Mhz), 4 (max 104Mhz), 5 (max 133Mhz) or 6 (max 166Mhz)
    );

    port (
        clk         : in std_logic;
        clk_p       : in std_logic; -- phase-shifted clock for driving O_psram_ck
        resetn      : in std_logic;
        read        : in std_logic; -- Set to 1 to read from RAM
        write       : in std_logic; -- Set to 1 to write to RAM
        addr        : in std_logic_vector(21 downto 0); -- Byte address to read / write
        din         : in std_logic_vector(15 downto 0); -- Data word to write
        byte_write  : in std_logic; -- When writing, only write one byte instead of the whole word. 
                                    -- addr[0]==1 means we write the upper half of din. lower half otherwise.
        dout        : out std_logic_vector (15 downto 0); -- Last read data. Read is always word-based.
        busy        : out std_logic; -- 1 while an operation is in progress

        -- HyperRAM physical interface. Gowin interface is for 2 dies. 
        -- We currently only use the first die (4MB).
        O_psram_ck     : out std_logic_vector(1 downto 0);
        IO_psram_rwds  : inout std_logic_vector(1 downto 0);
        IO_psram_dq    : inout std_logic_vector(15 downto 0);
        O_psram_cs_n   : out std_logic_vector(1 downto 0)

    );

end component;
	
begin

-- ____________________________________________________________________________________
-- clock signals

clock1: Gowin_rPLL
    port map (
        clkout => clk_72m,
        clkoutp => clk_72m_p,
        clkin => ex_clk_27m
    );


-- ____________________________________________________________________________________
-- MEMORY READ/WRITE LOGIC GOES HERE
iorq_wr_n <= bus_wr_n or bus_iorq_n;
mreq_wr_n <= bus_wr_n or bus_mreq_n;
iorq_rd_n <= bus_rd_n or bus_iorq_n;
mreq_rd_n <= bus_rd_n or bus_mreq_n;


-- ____________________________________________________________________________________
-- BUS ISOLATION GOES HERE
ex_bus_dout <= fsm_dout when bus_data_reverse = '1' else (others => 'Z');
ex_bus_data_reverse_n <= not bus_data_reverse;



--bus denoise
ex_control_bus <= ex_bus_mreq_n & ex_bus_iorq_n & ex_bus_rd_n & ex_bus_wr_n & ex_bus_reset_n & ex_bus_clk_3m6 & ex_bus_sltsl_n & ex_bus_rfsh_n;
bus_mreq_n <= control_bus(7);
bus_iorq_n <= control_bus(6);
bus_rd_n <= control_bus(5);
bus_wr_n <= control_bus(4);
bus_reset_n <= control_bus(3);
bus_clk_3m6 <= control_bus(2);
bus_sltsl_n <= control_bus(1);
bus_rfsh_n <= control_bus(0);

denoise8_1: denoise_low8
    port map (
		data8_in    => ex_control_bus,
		clock		=> clk_72m,
		data8_out	=> control_bus
    );

denoise8_2: denoise_8
    port map (
		data8_in    => ex_bus_addr(7 downto 0),
		clock		=> clk_72m,
		data8_out	=> bus_addr(7 downto 0)
    );

denoise8_3: denoise_8
    port map (
		data8_in    => ex_bus_addr(15 downto 8),
		clock		=> clk_72m,
		data8_out	=> bus_addr(15 downto 8)
    );

denoise8_4: denoise_8
    port map (
		data8_in    => ex_bus_dout,
		clock		=> clk_72m,
		data8_out	=> bus_dout
    );

mono1 : monostable
	PORT map 
	(
		pulse_in    => bus_data_reverse,
		clock       => ex_clk_27m,
		pulse_out_n	=> monostable_out
	);

pram1 : PsramController
    generic map (
        FREQ    => 78000000, --Actual clk frequency, to time 150us initialization delay
        LATENCY => 3         --tACC (Initial Latency) in W955D8MBYA datasheet:
                             --3 (max 83Mhz), 4 (max 104Mhz), 5 (max 133Mhz) or 6 (max 166Mhz)
    )

    port map(

        clk             => clk_72m,
        clk_p           => clk_72m_p, -- phase-shifted clock for driving O_psram_ck
        resetn          => bus_reset_n,
        read            => psram_read, -- Set to 1 to read from RAM
        write           => psram_write, -- Set to 1 to write to RAM
        addr            => psram_addr, -- Byte address to read / write
        din             => psram_din, -- Data word to write
        byte_write      => '1', -- When writing, only write one byte instead of the whole word. 
                                    -- addr[0]==1 means we write the upper half of din. lower half otherwise.
        dout            => psram_dout, --: out std_logic_vector (15 downto 0); -- Last read data. Read is always word-based.
        busy            => psram_busy, --: out std_logic; -- 1 while an operation is in progress

        -- HyperRAM physical interface. Gowin interface is for 2 dies. 
        -- We currently only use the first die (4MB).
        O_psram_ck      => O_psram_ck,
        IO_psram_rwds   => IO_psram_rwds,
        IO_psram_dq     =>  IO_psram_dq,
        O_psram_cs_n    => O_psram_cs_n

    );

--mapper
mapper_read <= '1' when (mreq_rd_n='0') and (bus_sltsl_n = '0') and (bus_rfsh_n = '1') and bus_reset_n = '1' else '0';
mapper_write <= '1' when (mreq_wr_n='0') and (bus_sltsl_n = '0') and (bus_rfsh_n = '1') and bus_reset_n = '1' else '0';
mapper_reg_write <= '1' when iorq_wr_n = '0' and bus_addr (7 downto 2) = "111111" else '0';

process(bus_reset_n, mapper_reg_write)
begin
    if bus_reset_n = '0' then
        mapper_reg0	<= "00000011";
        mapper_reg1	<= "00000010";
        mapper_reg2	<= "00000001";
        mapper_reg3	<= "00000000";
    elsif mapper_reg_write = '1' then
        case bus_addr(1 downto 0) is
            when "00"   => mapper_reg0 <= bus_dout;
            when "01"   => mapper_reg1 <= bus_dout;
            when "10"   => mapper_reg2 <= bus_dout;
            when others => mapper_reg3 <= bus_dout;
        end case;
    end if;
end process;

fsm: process (clk_72m, bus_reset_n)
begin
    if bus_reset_n = '0' then
        fsm_status <=  idle;
        psram_read <= '0';
        psram_write <= '0';
    else
        if rising_edge(clk_72m) then
            case fsm_status is
                when idle =>
                    fsm_addr <= bus_addr;
                    fsm_din <= bus_dout;
                    if mapper_write = '1' then
                        fsm_status <= write1;
                    elsif mapper_read = '1' then
                        fsm_status <= read1;
                    end if;
                when write1 =>
                    --psram_addr <= "000000" & fsm_addr;
                    case fsm_addr(15 downto 14) is
                        when "00" =>
                            psram_addr <= mapper_reg0 & fsm_addr(13 downto 0);
                        when "01" =>
                            psram_addr <= mapper_reg1 & fsm_addr(13 downto 0);
                        when "10" =>
                            psram_addr <= mapper_reg2 & fsm_addr(13 downto 0);
                        when "11" =>
                            psram_addr <= mapper_reg3 & fsm_addr(13 downto 0);
                        when others =>
                            null;
                    end case;
                    psram_din <= fsm_din & fsm_din;
                    psram_write <= '1';
                    fsm_status <= write2;
                when write2 =>
                    psram_write <= '0';
                    fsm_status <= write3;
                when write3 =>
                    if psram_busy = '0' and mapper_write = '0' then
                        fsm_status <= idle;
                    end if;
                when read1 =>
                    --psram_addr <= "000000" & fsm_addr;
                    case fsm_addr(15 downto 14) is
                        when "00" =>
                            psram_addr <= mapper_reg0 & fsm_addr(13 downto 0);
                        when "01" =>
                            psram_addr <= mapper_reg1 & fsm_addr(13 downto 0);
                        when "10" =>
                            psram_addr <= mapper_reg2 & fsm_addr(13 downto 0);
                        when "11" =>
                            psram_addr <= mapper_reg3 & fsm_addr(13 downto 0);
                        when others =>
                            null;
                    end case;
                    psram_read <= '1';
                    fsm_status <= read2;
                when read2 =>
                    psram_read <= '0';
                    fsm_status <= read3;
                when read3 =>
                    if psram_busy = '0' then
                        if psram_addr(0) = '0' then
                            fsm_dout <= psram_dout(7 downto 0);
                        else
                            fsm_dout <= psram_dout(15 downto 8);
                        end if;
                        bus_data_reverse <= '1';
                        fsm_status <= read4;
                    end if;
                when read4 =>
                    if mapper_read = '0' then
                        bus_data_reverse <= '0';
                        fsm_status <= idle;
                    end if;
                when others =>
                    null;
            end case;
        end if;
    end if;
end process fsm;

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


ex_led <= ex_bus_data_reverse_n & "1111" & monostable_out when ex_btn0 = '1' else check_fsm_counter_max (5 downto 0);


end;
