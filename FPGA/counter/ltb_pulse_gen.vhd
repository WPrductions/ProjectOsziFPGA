------------------------------------------------------------------------------------
--Project : ESY 3BHELO 
--Author  : Gräbner
--Date    : 17/03/2011
--File    : ltb_pulse_gen.vhd
--Design  : Altera DE0 Board
------------------------------------------------------------------------------------
-- Description: Testbench
------------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.ALL;

--====================================================================
entity ltb_pulse_gen is
end ltb_pulse_gen;
--====================================================================

--====================================================================
architecture behavioral of ltb_pulse_gen is
   
  --  Declaration of the component that will be instantiated.
  component pulse_gen
    port (
          RESET_n   :  in std_logic;
          CLK_50MHz :  in std_logic;
          BUTTON_in :  in std_logic;
          PULSE_out : out std_logic    
         );
  end component;
   
  --  Specifies which entity and architecture is bound with the component.
  for UUT: pulse_gen use entity work.pulse_gen(rtl);

  --==================================================================
  constant clk_period_c : time := 20 ns;
  signal reset_n        : std_logic;
  signal clk            : std_logic := '0';

  signal button_in : std_logic;
  signal pulse_out : std_logic;
  --==================================================================
   
begin
  -- Component instantiation -----------------------------------------
  UUT: pulse_gen port map (
                           RESET_n   => reset_n,
                           CLK_50MHz => clk,
                           BUTTON_in => button_in,
                           PULSE_out => pulse_out
                          );
  --------------------------------------------------------------------                
  --------------------------------------------------------------------                
  Test: process
  begin
    button_in <= '0';
                      wait for 20    * clk_period_c;
                      wait for  0.25 * clk_period_c;
    button_in <= '1'; wait for         clk_period_c;
    button_in <= '0'; wait for  2    * clk_period_c;
    button_in <= '1'; wait for  5    * clk_period_c;
    button_in <= '0'; wait for         clk_period_c;
    button_in <= '1'; wait for         clk_period_c;
    button_in <= '0'; wait for         clk_period_c;
    button_in <= '1'; wait for         clk_period_c;
    button_in <= '0'; wait for         clk_period_c;
    wait;
  end process Test;
  --------------------------------------------------------------------                
  reset_n <= '0', '1' after 10 * clk_period_c;
  --------------------------------------------------------------------                
  -- Clock generator -------------------------------------------------
  clk <= not clk after clk_period_c / 2;
  --------------------------------------------------------------------
  --------------------------------------------------------------------
  stop: process
  begin
    wait for 100 * clk_period_c;
       assert FALSE report "End of Simulation" severity failure;
  end process stop;
  --------------------------------------------------------------------
end behavioral;
--====================================================================
