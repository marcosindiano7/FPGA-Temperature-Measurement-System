library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity gen_SC is
port(clk	:  in      std_logic;	-- 50MHz de placa
     nRst	:  in	   std_logic;
     SC		:  buffer  std_logic;  	-- Reloj generado a 5MHz
     SC_up	:  buffer  std_logic;	-- Pulso flanco subida (cnt = 12)
     SC_down	:  buffer  std_logic;	-- Pulso flanco bajada (cnt = 20)
     SC_meas	:  buffer  std_logic;	-- Pulso mitad de bit  (cnt = 16)
     SC_ena	:  in      std_logic	-- Habilita el divisor
    );
end entity;

architecture rtl of gen_SC is
constant T_SC:	natural := 20 ;		-- Cuenta total
constant h_SC: 	natural := 10 ;		-- Contamos la mitad del periodo

signal cnt_SC	:	std_logic_vector(4 downto 0);
signal SC_R	:	std_logic;	-- Reloj no registrado
begin

process(clk, nRst)  			-- Contador ascendente del SC
  begin
  if nRst = '0' then
    cnt_SC <= ( 0 => '1', others => '0');
  elsif clk'event and clk = '1' then
    if SC_ena = '1' then		
      if  cnt_SC < T_SC then
	cnt_SC<= cnt_SC + '1';
      else 
	cnt_SC <= (0 => '1', others => '0');
      end if;
    else
      cnt_SC <= (0 => '1', others => '0');
    end if;				
  end if;
end process;
					-- Salida del sc (decodificacion de pulsos auxiliares)
SC_R	<= '1' when cnt_SC > h_SC else '0';
SC_up 	<= '1' when cnt_SC = 12   else '0';
SC_down <= '1' when cnt_SC = 20   else '0';
SC_meas <= '1' when cnt_SC = 16   else  '0';

process(clk, nRst)			-- Registro de la salida del SC
  begin
    if nRst = '0' then
      SC<='0';
    elsif clk'event and clk = '1' then
      SC<=SC_R;
    end if;
end process;
end architecture;