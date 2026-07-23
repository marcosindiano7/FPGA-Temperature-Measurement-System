-- Test que genera, en 191 accesos a la interfaz SPI, la secuencia de datos de temperatura:
-- de 0 a +150 seguida de -40 a -1
 
-- Reloj 50 MHz
-- Es necesario completar la sentencia de emplazamiento del dut

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity test_interfaz_spi is
end entity;

architecture test of test_interfaz_spi is
  signal clk:       std_logic;
  signal nRst:      std_logic;
  signal CS:        std_logic;
  signal CL:        std_logic;
  signal SDAT:      std_logic;
  signal sel_disp:  std_logic_vector(7 downto 0);
  signal segmentos: std_logic_vector(6 downto 0);
  signal key0, key1:      std_logic;


  signal temp: std_logic_vector(15 downto 0);   

  constant T_clk: time := 20 ns;     --para el reloj de 50Mhz 

begin 

dut: entity work.interfaz_spi(structural)  -- Completar nombre
     port map(       
	clk	  => clk,
	nRst  	  => nRst,
	CL   	  => CL,
	CS   	  => CS,
	SDAT	  => SDAT,
	KEY_1 	  => key1,
	KEY_0 	  => key0,
	sel_disp  => sel_disp,
	segmentos =>segmentos  
              );

process     -- Reloj
begin
  wait for T_clk/2;
    clk <= '0';

  wait for T_clk/2;
    clk <= '1';

end process;

process     -- key0
begin
  wait until clk'event and clk = '1';
    key0 <= '0';

  wait for 9999*T_clk;
  wait until clk'event and clk = '1';
    key0 <= '1';                        

end process;

process     -- key1 

begin
  wait until clk'event and clk = '1';
    key1 <= '0';

  wait for 999999*T_clk;
  wait until clk'event and clk = '1';
    key1 <= '1';                        

end process;


process    -- Reset 
begin
  wait until clk'event and clk = '1';
  nRst <= '1';
  wait until clk'event and clk = '1';
  nRst <= '0';
  wait until clk'event and clk = '1';
  wait until clk'event and clk = '1';
  nRst <= '1';
  wait;

end process;

process  -- Genera la secuencia de temperaturas del test
  variable t_i: std_logic_vector(15 downto 0);

begin
  wait until nRst'event and nRst = '0';
    temp <= X"0003";
    t_i := X"0003";

  wait until nRst'event and nRst = '1';

  for i in 1 to 191 loop
     wait until CS'event and CS = '0';
     wait until CS'event and CS = '1';
     if t_i(15 downto 7) /= 150 then
       t_i(15 downto 7) := t_i(15 downto 7) + 1;

     else
       t_i := X"EC03";


     end if;
     temp <= t_i;

  end loop;

  wait for 100*T_clk;

  report "Simulation completed successfully" severity note;
  std.env.stop;
  wait;

end process;

process   -- Maneja SDAT
  variable dato: std_logic_vector(15 downto 0) := X"0003";

begin
  wait until CS'event and CS = '0';
    dato := temp;
    SDAT <= dato(15) after 10*T_clk;   
    dato := dato(14 downto 0)&'Z';

  loop
    if CS =  '0' then
      wait until (CL'event and CL = '0') or (CS'event and CS = '1');
      if CS = '0' then
        SDAT <= dato(15) after 10*T_clk;   
        dato := dato(14 downto 0)&'Z';

      else
        SDAT <= 'Z';
        exit;

      end if;
    end if;
  end loop;

end process;
end test;


