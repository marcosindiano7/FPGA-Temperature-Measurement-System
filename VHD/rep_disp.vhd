library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

-- Display 0 muestra la escala seleccionada («C» para Celsius, «°» para Kelvin, «F» para Fahrenheit)
-- El display 1 permanece siempre apagado como separador
-- El display 2 enseña las unidades
-- El display 3 presenta las decenas o, si la magnitud es < 10 y la temperatura es negativa, el signo «-»
-- El display 4 muestra las centenas o bien el mismo signo «-» cuando no hay centenas y el valor es negativo
-- El display 5 también está siempre apagado
-- El display 6 indica el periodo de muestreo activo (2, 4, 6 u 8 s)
-- El display 7 ilumina un «0» durante exactamente un segundo cada vez que llega una nueva lectura del sensor

entity rep_disp is   							-- Representa los datos en los displays y cambia la frecuencia de lectura del sensor de datos
  port (
    clk          : in	  std_logic;					-- 50 MHz de placa
    nRst         : in	  std_logic;
    temp_BCD     : in	  std_logic_vector(11 downto 0);		-- Con centenas, decenas y unidades
    signo        : in  	  std_logic;					-- '1' negativo
    escala       : in  	  std_logic_vector(1 downto 0);			-- '00' C, '10' = F, '01' = K
    disp         : buffer std_logic_vector(6 downto 0);
    mux          : buffer std_logic_vector(7 downto 0);			-- Display Select ('0' activo)
    nueva_medida : in     std_logic;					-- 
    periodo 	 : in     std_logic_vector(3 downto 0)			--
  );
end entity;

architecture rtl of rep_disp is
  constant un_seg 	: natural:= 50000000; --No escalado  50000000
  constant  un_seg_esc	: natural:= 500; --No escalado  50000000
  signal uns_seg_cnt	: std_logic_vector(27 downto 0); 
  signal uns_seg_en	: std_logic; 
  constant mux_c 	: natural:= 125000;				--No escalado => 125000;
  signal cont_mux	: std_logic_vector(16 downto 0);
  signal en_mux		: std_logic;
  signal mux_n		: std_logic_vector(7 downto 0);
  signal BCD		: std_logic_vector(3 downto 0);

begin
  --Control de la multiplexación
  --Multiplexamos el display a 400Hz
  --Contador para la frecuencia de multiplexado
  process(clk, nRst)
  begin
    if nRst = '0' then
      cont_mux <= (others => '0');
    elsif clk'event and clk = '1' then
      if cont_mux = mux_c then
        cont_mux <= (others => '0');
      else
	cont_mux<=cont_mux + 1;
      end if;
    end if;
  end process;
  en_mux <= '1' when cont_mux = mux_c else '0';
  process(clk, nRst)
    begin
    if nRst = '0' then
      mux_n <= (0 => '1', others => '0');
    elsif clk'event and clk = '1' then
      if en_mux = '1' then      
        mux_n <= mux_n(6 downto 0)&mux_n(7);
      end if;
     end if;
  end process;
  mux <= not mux_n; 
  -- Contador de la nueva medida
  process(clk, nRst)
  begin
    if nRst = '0' then
      uns_seg_cnt<=(others=> '0');
    elsif clk'event and clk = '1' then
      if nueva_medida = '1' then
        uns_seg_cnt <= (others=> '0');
      	elsif  uns_seg_en = '1'then
        uns_seg_cnt <= uns_seg_cnt + 1;
      end if;
    end if;
  end process;
  uns_seg_en<= '1' when uns_seg_cnt < un_seg else '0'; 			-- Le ponesmod la variable correspondiente cuando se multiplexa el display

	 BCD <= "1010"    		when escala    = 0 		and 	mux_n = 1  else
        	"1011"    		when escala    = 2 		and 	mux_n = 1  else
		"1100"    		when escala    = 1 		and 	mux_n = 1  else
       		"1111"    		when                   			mux_n = 2  else
        	 temp_BCD(3 downto 0)	when					mux_n = 4  else			 -- UDS
        	 temp_BCD(7 downto 4)  	when temp_BCD >="000000010000" 	and 	mux_n = 8  else			 -- DEC
		"1111"	  		when temp_BCD < "000000010000"  and 	mux_n = 8  else
        	"1110"   		when temp_BCD < "000000010000" 	and   	signo = '1' and  mux_n = 8  else -- CENT
        	 temp_BCD(11 downto 8) 	when temp_BCD >="000100000000" 	and 	signo = '0' and  mux_n = 16 else
        	 "1111"   		when temp_BCD < "000100000000" 	and   	signo = '0' and  mux_n = 16 else
        	 "1110"   		when temp_BCD < "000100000000" 	and   	signo = '1' and  mux_n = 16 else
		 "1111" 		when 					mux_n = 32  else
		 periodo       		when 					mux_n = 64 else
		 "0000"                	when uns_seg_en = '1' 		and 	mux_n = 128 else	
		 "1111"                	when uns_seg_en = '0' 		and 	mux_n = 128 else	
        	 "1111";
  -- Decodificador BCD
  process(BCD)
  begin
    case BCD is            						-- abcdefg
      when "0000" => disp <= "1111110"; -- 0 
      when "0001" => disp <= "0110000"; -- 1
      when "0010" => disp <= "1101101"; -- 2 
      when "0011" => disp <= "1111001"; -- 3
      when "0100" => disp <= "0110011"; -- 4
      when "0101" => disp <= "1011011"; -- 5
      when "0110" => disp <= "1011111"; -- 6
      when "0111" => disp <= "1110000"; -- 7
      when "1000" => disp <= "1111111"; -- 8
      when "1001" => disp <= "1110011"; -- 9
      when "1010" => disp <= "1001110"; -- Grados (C)
      when "1011" => disp <= "1000111"; -- Farenheit (F)
      when "1100" => disp <= "1100011"; -- Kelvin (º)
--      when "1101" => disp <= "1111111"; -- Hum 
      when "1110" => disp <= "0000001"; -- sgn - 
      when "1111" => disp <= "0000000"; -- Apagado (N/A)
      when others => disp <= "XXXXXXX";
  
    end case;
  end process;
end rtl;