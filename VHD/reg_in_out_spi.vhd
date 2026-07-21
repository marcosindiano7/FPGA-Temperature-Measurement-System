library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

-- Lee los 9 bits del LM71 y los deja en paralelo
entity reg_in_out_spi is
  generic(NBITS : integer := 9);  -- 1 signo + 8 magnitud
  port(
    clk       : in  std_logic;                              		-- 5MHz (reloj SPI)
    nRst      : in  std_logic;
    sio_in    : in  std_logic;                              		-- SDAT LM71
    ena_shift : in  std_logic;                              		-- Enable desplazamiento
    temp_bin  : buffer std_logic_vector(NBITS-1 downto 0);  		-- Salida
    SC_meas   : in std_logic				    		-- Pulso en mida del bit (gen_SC)
  );
end entity;

architecture rtl of reg_in_out_spi is
  signal shift : std_logic_vector(NBITS-1 downto 0); 	          	-- Buffer desplazamiento
  signal idx   : std_logic_vector(4 downto 0) := (others => '0'); 	-- Contador de bit recibido

begin
  process (clk, nRst)							-- Registro de desplazamiento MSB-First (más significativo primero)
  begin
    if nRst = '0' then
      shift <= (others => '0');
      idx   <= (others => '0');
    elsif clk'event and clk = '1' then
      if ena_shift = '1' and SC_meas = '1' then
        shift <= shift(NBITS-2 downto 0) & sio_in;			-- Desplazo posicion en registro y aniado LSB
        if idx = NBITS-1 then						-- Contamos cuantos bits llevamos, si completamos reiniciamos, sino sumamos
          idx <= (others => '0'); 
        else
          idx <= idx + 1;
        end if;
      end if;
    end if;
  end process;
  temp_bin <= shift;                       				-- Sacamos temperatura
end rtl;