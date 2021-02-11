library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.ALL;

entity bin2dez is
port( 
	RESET: in std_logic;
	CLK : in std_logic;
	BIN : in  unsigned(9 downto 0);
	BCD2: out unsigned(3 downto 0);
	BCD1: out unsigned(3 downto 0);
	BCD0: out unsigned(3 downto 0)
		  );
end bin2dez;

architecture rtl of bin2dez is
	type state_type is (s_load, s_adjust, s_shift, s_write);
	
	signal state : state_type;
	signal digit0: unsigned (3 downto 0);
	signal digit1: unsigned (3 downto 0);
	signal digit2: unsigned (3 downto 0);
	signal n     : natural;
	signal sreg  : unsigned (9 downto 0);
	
begin
	process(CLK, RESET)
	begin
	if(RESET = '0') then
		state  	<= s_load;
		n 		<= 0;
		digit0  <= (others => '0');
		digit1  <= (others => '0');
		digit2  <= (others => '0');
		sreg	<= (others => '0');
		
	elsif (CLK'event and CLK ='1') then
		case state is 
		when s_load =>
			digit0  <= (others => '0');
			digit1  <= (others => '0');
			digit2  <= (others => '0');
			sreg 	<= BIN;
			n 		<= 9;
			state 	<= s_adjust;
		when s_adjust =>
			if(digit2 > 4) then
				digit2 <= digit2 + 3;
			end if;
			if(digit1 > 4) then
				digit1 <= digit1 + 3;
			end if;
			if(digit0 > 4) then
				digit0 <= digit0 + 3;
			end if;
			state <= s_shift;
		when s_shift =>
			digit2(3 downto 0) <= digit2(2 downto 0) & digit1(3);
			digit1(3 downto 0) <= digit1(2 downto 0) & digit0(3);
			digit0(3 downto 0) <= digit0(2 downto 0) & sreg(9);
			sreg  (9 downto 0) <= sreg  (8 downto 0) & '0';
			
			if (n=0) then
				state <= s_write;
				n <= 9;
			else
				state <= s_adjust;
				n <= n-1;
			end if;
		when s_write => 
			BCD0  <= digit0;
			BCD1  <= digit1;
			BCD2  <= digit2;
			state <= s_load;
		when others => NULL;
		
		end case;
	end if;
	end process;
	
end rtl;