--------------------------------------------------------
-- Project: FPGA-Oszi
-- File: DE10_LITE.vhd
-- Author: Lukas J. Sauer
-- Date: 28.01.21
--------------------------------------------------------
-- 
--------------------------------------------------------
library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.ALL;

use work.DE10_Lite_const_pkg.ALL;

--=======================================================================================================
entity DE10_Lite is
  port (
        MAX10_CLK1_50 :  in std_logic;
        ---------------------------------------------------------------
        KEY           :  in std_logic_vector(    keys_c - 1 downto 0);
        SW            :  in std_logic_vector(switches_c - 1 downto 0);
        LEDR          : out std_logic_vector(    leds_c - 1 downto 0);
		GPIO    	: inout std_logic_vector(0 to 35);
        ---------------------------------------------------------------
        VGA_R         : out std_logic_vector(3 downto 0);
        VGA_G         : out std_logic_vector(3 downto 0);
        VGA_B         : out std_logic_vector(3 downto 0);
        VGA_HS        : out std_logic;
        VGA_VS        : out std_logic;
        ---------------------------------------------------------------
        HEX0          : out std_logic_vector(7 downto 0);
        HEX1          : out std_logic_vector(7 downto 0);
        HEX2          : out std_logic_vector(7 downto 0);
        HEX3          : out std_logic_vector(7 downto 0);
        HEX4          : out std_logic_vector(7 downto 0);
        HEX5          : out std_logic_vector(7 downto 0)
        ---------------------------------------------------------------
       );
end DE10_Lite;
--=======================================================================================================

architecture rtl of DE10_Lite is
  alias CLK: std_logic is MAX10_CLK1_50;
  -- Parameters for Debounce
  constant clock_period_c    : time :=  20 ns;
  constant sample_period_c   : time := 500 us;
  constant mintime_pressed_c : time :=  10 ms;
  
  --debounced Buttons:
  signal key_db : std_logic_vector(keys_c - 1 downto 0);
  
  --VGA-Interface:
  signal current_x : natural;
  signal current_y : natural;

  signal red   : std_logic_vector(rgb_dac_c - 1 downto 0);
  signal green : std_logic_vector(rgb_dac_c - 1 downto 0);
  signal blue  : std_logic_vector(rgb_dac_c - 1 downto 0);

	signal VGA_HS_sig : std_logic;
	signal VGA_VS_sig : std_logic;
--divided clock:
  signal clk_25MHz : std_logic := '0';

  -- Debounced Control Buttons
  signal reset_n   : std_logic;

--ADC
 signal CONNECTED_TO_CH0 : std_logic_vector(11 downto 0);
--component ADC:
	component Ch1ADC is
		port (
			CLOCK : in  std_logic                     := 'X'; -- clk
			RESET : in  std_logic                     := 'X'; -- reset
			CH0   : out std_logic_vector(11 downto 0);        -- CH0
			CH1   : out std_logic_vector(11 downto 0);        -- CH1
			CH2   : out std_logic_vector(11 downto 0);        -- CH2
			CH3   : out std_logic_vector(11 downto 0);        -- CH3
			CH4   : out std_logic_vector(11 downto 0);        -- CH4
			CH5   : out std_logic_vector(11 downto 0);        -- CH5
			CH6   : out std_logic_vector(11 downto 0);        -- CH6
			CH7   : out std_logic_vector(11 downto 0)         -- CH7
		);
	end component Ch1ADC;
	
-- component grafic generator:
	component grafic_gen is
		port(
			-- Control
			CLK          : in std_logic;
			RESET_n      : in std_logic;
			-- From VGA Control
			VGA_HS_in    : in std_logic;
			CURRENT_X_in : in natural;
			CURRENT_Y_in : in natural;
			-- To VGA Control
			RED_out      : out std_logic_vector(3 downto 0);
			GREEN_out    : out std_logic_vector(3 downto 0);
			BLUE_out     : out std_logic_vector(3 downto 0);
			-- ADC value
			ADC_in 		 : in std_logic_vector(11 downto 0)
		);
	end component grafic_gen;
	
--component double dabble bin2dez:
	component bin2dez is
		port( 
			RESET: in std_logic;
			CLK : in std_logic;
			BIN : in  unsigned(9 downto 0);
			BCD2: out unsigned(3 downto 0);
			BCD1: out unsigned(3 downto 0);
			BCD0: out unsigned(3 downto 0)
		  );
	end component bin2dez;
-- für anteige 7-seg:
signal BCD0_dez		   : unsigned(3 downto 0);
  signal BCD1_dez		   : unsigned(3 downto 0);
  signal BCD2_dez		   : unsigned(3 downto 0);
  --=====================================================================================================
begin

  
  --=====================================================================================================
  I_DEBOUNCE_KEY1: entity work.debounce(rtl) generic map (
                                                          clock_period    => clock_period_c,
                                                          sample_period   => sample_period_c,
                                                          mintime_pressed => mintime_pressed_c
                                                         )
                                             port map (
                                                       CLK        => CLK,
                                                       BUTTON_in  => KEY(1),
                                                       BUTTON_out => key_db(1)
                                                      );
  --=====================================================================================================
  I_DEBOUNCE_KEY0: entity work.debounce(rtl) generic map (
                                                          clock_period    => clock_period_c,
                                                          sample_period   => sample_period_c,
                                                          mintime_pressed => mintime_pressed_c
                                                         )
                                             port map (
                                                       CLK        => CLK,
                                                       BUTTON_in  => KEY(0),
                                                       BUTTON_out => key_db(0)
                                                      );
  --=====================================================================================================
  clock_divider: process(CLK)
  begin
    if (CLK'event and CLK = '1') then
        clk_25MHz <= not clk_25MHz;
    end if;
  end process;
  --=====================================================================================================
  I_VGA_CONTROL: entity work.sync(rtl) port map (
                                                        -- Control
                                                        CLK           => clk_25MHz,
                                                        RESET_n       => reset_n,
                                                        -- Host Side
                                                        RED_in        => red,
                                                        GREEN_in      => green,
                                                        BLUE_in       => blue,
                                                        CURRENT_X_out => current_x,
                                                        CURRENT_Y_out => current_y,
                                                        -- VGA Side
                                                        VGA_R_out     => VGA_R,
                                                        VGA_G_out     => VGA_G,
                                                        VGA_B_out     => VGA_B,
                                                        VGA_HS_out    => VGA_HS_sig,
                                                        VGA_VS_out    => VGA_VS_sig
                                                       );

	
	HEX0(6 downto 0) <= not (disp_array_c(TO_INTEGER(BCD0_dez)));
	HEX1(6 downto 0) <= not (disp_array_c(TO_INTEGER(BCD1_dez)));
	HEX2(6 downto 0) <= not (disp_array_c(TO_INTEGER(BCD2_dez)));
  
	HEX0(7) <= '1';
	HEX1(7) <= '1';
	HEX2(7) <= '1';
	HEX3(7 downto 0) <= (others => '1');
	HEX4(7 downto 0) <= (others => '1');
	HEX5(7 downto 0) <= (others => '1');
  
	VGA_HS <= VGA_HS_sig;
	VGA_VS <= VGA_VS_sig;
	
	reset_n <= not key_db(0);
	LEDR(0) <= not reset_n; 
  --=====================================================================================================
	ADC: component Ch1ADC
		port map (
			CLOCK => CLK, --      clk.clk
			RESET => (not reset_n), --    reset.reset
			CH0   => CONNECTED_TO_CH0   -- readings.CH0
			--CH1   => CONNECTED_TO_CH1,   --         .CH1
			--CH2   => CONNECTED_TO_CH2,   --         .CH2
			--CH3   => CONNECTED_TO_CH3,   --         .CH3
			--CH4   => CONNECTED_TO_CH4,   --         .CH4
			--CH5   => CONNECTED_TO_CH5,   --         .CH5
			--CH6   => CONNECTED_TO_CH6,   --         .CH6
			--CH7   => CONNECTED_TO_CH7    --         .CH7
		);

  grafic_generator: component grafic_gen
		port map(
			-- Control
			CLK          => CLK,
			RESET_n      => reset_n,
			-- From VGA Control
			VGA_HS_in    => VGA_HS_sig,
			CURRENT_X_in => current_x,
			CURRENT_Y_in => current_y,
			-- To VGA Control
			RED_out      => red,
			GREEN_out    => green,
			BLUE_out     => blue,
			-- ADC value
			ADC_in 		 => CONNECTED_TO_CH0
		);
  
  Anzeige: component bin2dez 
		port map(
			RESET =>  reset_n,
			CLK => CLK,
			BIN(9 downto 0) => unsigned(CONNECTED_TO_CH0(11 downto 2)),
			BCD2 => BCD2_dez,
			BCD1 => BCD1_dez,
			BCD0 => BCD0_dez
		);

end rtl;
--@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
