--------------------------------------------------------
-- Project: VGA
-- File:  sync3.vhd
-- Author: Lukas J. Sauer
-- Date: 17.12.20
--------------------------------------------------------
-- synchronisation signal generator Horizontal & Vertical
--------------------------------------------------------

library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.ALL;

entity sync is
	port( 
		RESET_n	:	in std_logic;	--master reset
		CLK 	: 	in std_logic;	--clk in
		RED_in     : in std_logic_vector(3 downto 0);
        GREEN_in   : in std_logic_vector(3 downto 0);
        BLUE_in    : in std_logic_vector(3 downto 0);
        CURRENT_X_out : out natural;
        CURRENT_Y_out : out natural;
														
		VGA_HS_out	: out std_logic;	--horizontal sync signal
		VGA_VS_out	: out std_logic;	--vertical sync signal
		VGA_R_out   : out std_logic_vector(3 downto 0);
		VGA_G_out   : out std_logic_vector(3 downto 0);
		VGA_B_out   : out std_logic_vector(3 downto 0)
		
	);
end sync;

architecture rtl of sync is
type h_sync_states is (sync_h, b_porch_h, f_porch_h, display_area_h);

signal horizontal_state : h_sync_states;
--=====================================================================================================
signal current_X_count : natural;
signal current_Y_count : natural;
signal pt_counter : natural;		--pixeltime counter 1pt = 40ns
signal VGA_RGB_enable : std_logic;
signal line_counter : natural;

begin

CURRENT_X_out <= CURRENT_X_count;
CURRENT_Y_out <= CURRENT_Y_count;
		
VGA_H_sync_gen:
process(CLK)
begin
	if(RESET_n = '0') then
		pt_counter <= 0;
		CURRENT_X_count <= 0;
		VGA_R_out <= "0000";
		VGA_G_out <= "0000";
		VGA_B_out <= "0000";
		VGA_HS_out <= '1';
		horizontal_state <= sync_h;
		line_counter <= 0;
	elsif(CLK'event and CLK = '1') then
		case horizontal_state is
		when sync_h =>
			VGA_HS_out <= '0';
			VGA_R_out <= "0000";
			VGA_G_out <= "0000";
			VGA_B_out <= "0000";
			CURRENT_X_count <= 0;
			if(pt_counter = 93) then
				pt_counter <= 0;
				horizontal_state <= b_porch_h;
			else
				pt_counter <= pt_counter + 1;
			end if;
		when b_porch_h =>
			VGA_HS_out <= '1';
			if(pt_counter = 46) then
				pt_counter <= 0;
				horizontal_state <= display_area_h;
			else
				pt_counter <= pt_counter + 1;
			end if;
		when display_area_h =>
			CURRENT_X_count <= CURRENT_X_count + 1;
			if(VGA_RGB_enable = '1') then
				VGA_R_out <= RED_in;
				VGA_G_out <= GREEN_in;
				VGA_B_out <= BLUE_in;
			else
				VGA_R_out <= "0000";
				VGA_G_out <= "0000";
				VGA_B_out <= "0000";
			end if;
			if(pt_counter = 639) then
				pt_counter <= 0;
				horizontal_state <= f_porch_h;
			else
				pt_counter <= pt_counter + 1;
			end if;
		when f_porch_h =>
			CURRENT_X_count <= 0;
			VGA_R_out <= "0000";
			VGA_G_out <= "0000";
			VGA_B_out <= "0000";
			if(pt_counter = 23) then
				pt_counter <= 0;
				horizontal_state <= sync_h;
				if(line_counter = 525) then
					line_counter <= 0;
				else
					line_counter <= line_counter + 1;
				end if;
			else
				pt_counter <= pt_counter + 1;
			end if;
			
		when others => 
			pt_counter <= 0;
			CURRENT_X_count <= 0;
			VGA_HS_out <= '1';
			VGA_R_out <= "0000";
			VGA_G_out <= "0000";
			VGA_B_out <= "0000";
			horizontal_state <= sync_h;
			line_counter <= 0;
		end case;
	end if;
end process;

VGA_V_sync_gen:
process(CLK)
begin
	if(RESET_n = '0') then
		CURRENT_Y_count <= 0;
		VGA_VS_out <= '1';
		VGA_RGB_enable <= '0';
	elsif(CLK'event and CLK = '1') then
		if(line_counter < 2) then		--v_sync		2 lines
			CURRENT_Y_count <= 0;
			VGA_VS_out <= '0';
			VGA_RGB_enable <= '0';
		elsif(line_counter < 34) then	 --back porch 	32 lines
			VGA_VS_out <= '1';
		elsif(line_counter < 514) then		--Vertical display area	480 lines
			VGA_RGB_enable <= '1';
			CURRENT_Y_count <= line_counter - 34;
		else
			
			VGA_RGB_enable <= '0';
			VGA_VS_out <= '1';
			CURRENT_Y_count <= 0;
		end if;
	end if;
end process;


end rtl;

--pt = pixeltime = (2/50MHz) = 40ns
--Horizonal Dots         640
--Vertical Scan Lines    480
--Horiz. Sync Polarity   NEG
--A (us)                 31.77 	Scanline time		= 794 pt ->> 805 pt (bc Active Video Time)
--B (us)                 3.77  	Sync pulse lenght 	= 94 pt
--C (us)                 1.89 	Back porch			= 47 pt
--D (us)                 25.17	Active video time	= 629 pt ->> 640 pt (in tolerance)
--E (us)                 0.94 	Front porch			= 24 pt
--
--         ______________________          ________
--________|        VIDEO         |________| VIDEO (next line)
--    |-C-|----------D-----------|-E-|
--__   ______________________________   ___________
--  |_|                              |_|
--  |B|
--  |---------------A----------------|
--
--Vertical Timing
--
--Horizonal Dots         640
--Vertical Scan Lines    80
--Vert. Sync Polarity    NEG      
--Vertical Frequency     60Hz
--O (ms)                 16.68     Total frame time
--P (ms)                 0.06      Sync length			= 1500 pt
--Q (ms)                 1.02      Back porch			= 25 500 pt
--R (ms)                 15.25     Active video time	= 381 250 pt
--S (ms)                 0.35      Front porch			= 8750 pt
--
--         ______________________          ________
--________|        VIDEO         |________|  VIDEO (next frame)
--    |-Q-|----------R-----------|-S-|
--__   ______________________________   ___________
--  |_|                              |_|
--  |P|
--  |---------------O----------------|