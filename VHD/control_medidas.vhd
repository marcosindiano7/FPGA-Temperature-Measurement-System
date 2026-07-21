library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity control_medidas is					-- Signo y magnitud a 8 bits
port(clk:              in     std_logic;
     nRst:             in     std_logic;
     nueva_medida:     in     std_logic;                     	-- Habilitacion de lectura de bit
     dato_in:          in     std_logic_vector(8 downto 0);
     dato_out:         buffer std_logic_vector(7 downto 0);
     signo:            buffer std_logic                     	-- '1' si negativa
    );
end entity;

architecture rtl of control_medidas is
begin
  process(clk, nRst)		  				-- Almacena los datos cada vez que llega nueva medida
  begin
    if nRst = '0' then
      dato_out <= x"00";
      signo <= '1';
    elsif clk'event and clk = '1' then                     
      if nueva_medida = '1' then
	signo <= dato_in(8);
	if dato_in(8) = '0' then
          dato_out <= dato_in(7 downto 0);
	elsif dato_in(8) = '1' then
	  dato_out <= not (dato_in(7 downto 0)) + 1;		-- Complemento a dos para magnitud
        end if;
      end if;
    end if;
  end process;
end rtl;