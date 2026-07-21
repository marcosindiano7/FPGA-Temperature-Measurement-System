library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity conv_escala_BCD is							-- Conversión a escala seleccionada y BCD (3 digitos)
port(
	clk:		in	std_logic;
	nRst:		in	std_logic;
	dato_in:	in	std_logic_vector(7 downto 0);			-- Magnitud abs
	signo:		in	std_logic;
	pulsador:	in	std_logic;					-- KEY1
	salida_BCD:	buffer	std_logic_vector(11 downto 0);			-- Temperatura max 3 digitos, 3 x 4 bits
	signo_out:	buffer	std_logic;
	escala:		buffer	std_logic_vector(1 downto 0)			-- Escala de la medida (Fahrenheit '01', Celsius '00', Kelvin '10')
);
end entity;

architecture rtl of conv_escala_BCD is
  type estado_t is (FAHRENHEIT, KELVIN, CELSIUS);  				-- FSM cambio de escala
  signal estado	        : estado_t := CELSIUS;
  signal Temp_escala    : std_logic_vector(8 downto 0); 			-- Es la temperatura ya transformada a una escala (salida)
  signal grados_f       : std_logic_vector(14 downto 0);
  signal pulsador_s     : std_logic_vector(2 downto 0);				-- Filtro antirebote 3FF
  signal pulsador_aux   : std_logic;
										-- Variables para binario - BCD
  signal t_DU	        : std_logic_vector(6 downto 0);
  signal t_sum_bin_1    : std_logic_vector(4 downto 0);
  signal t_carry_BCD    : std_logic_vector(1 downto 0);
  signal t_centenas_BCD : std_logic_vector(3 downto 0);
  signal t_decenas_BCD  : std_logic_vector(3 downto 0);
  signal t_unidades_BCD : std_logic_vector(3 downto 0);
begin
  process(clk,nRst) 								-- Automata que modela el cambio de escala 
  begin
    if nRst = '0' then
      escala      <= "00";  							-- Empieza en Celsius 
      grados_f    <= (others => '0');
      Temp_escala <= (others => '0');
    elsif clk'event and clk = '1' then
      case estado is
        when CELSIUS =>
	  escala       <= "00"; 						-- Cambio de escala
	  Temp_escala  <= '0' & dato_in; 					-- Copia directa
	  if pulsador_aux = '0' then 						-- Flanco alto filtrado
	    estado <= KELVIN; 
	  end if;
	when KELVIN =>
	  escala         <= "01";						-- Cambio de escala
	    if signo = '1' then
             Temp_escala    <= 273 - ('0' & dato_in);
	    else 
	     Temp_escala    <= ('0' & dato_in) + 273;
	    end if;
	  if pulsador_aux = '0' then
	    estado <= FAHRENHEIT; 
	  end if;
	when FAHRENHEIT =>
	  escala      <= "10";							-- Cambio de escala
	  grados_f    <= ((("0000000") & dato_in) + (dato_in & '0') + (dato_in & ("0000")) + (dato_in & ("00000")) + (dato_in & ("000000")));
	    
	  if signo = '1' then                                                   -- Division /16
	   if grados_f(14 downto 6) < 32 then 
             Temp_escala <= 32 - (grados_f(14 downto 6));
	   else
	     Temp_escala <= (grados_f(14 downto 6)) - 32;
	   end if;
	  else 
	    Temp_escala <= (grados_f(14 downto 6)) +32; 
	  end if;
 
					
	  if pulsador_aux = '0' then
	    estado <= CELSIUS;			
	  end if;
      end case;
    end if;
  end process;
	
  signo_out <= signo when estado = CELSIUS else 				-- EL signo vale lo que vale excepto en kelvin que no hay valores de temperatura negativos
	       '1' when estado = FAHRENHEIT and dato_in > 17 and signo = '1' else '0';

  t_centenas_BCD <= "0100" when Temp_escala >= 400 else  			-- Conversion de temp_bin a BCD, basado en restas sucesivas + correccion
                    "0011" when Temp_escala >= 300 else
                    "0010" when Temp_escala >= 200 else
                    "0001" when Temp_escala >= 100 else
                    "0000";
  t_DU 		 <= Temp_escala(6 downto 0) - 16  when t_centenas_BCD = "0100" else
	            Temp_escala(6 downto 0) - 44  when t_centenas_BCD = "0011" else
	            Temp_escala(6 downto 0) - 72  when t_centenas_BCD = "0010" else
	            Temp_escala(6 downto 0) - 100 when t_centenas_BCD = "0001" else
	            Temp_escala(6 downto 0);

  t_sum_bin_1 	 <= ('0' & t_DU(3) & t_DU(6) & t_DU(1 downto 0)) + ("00" & t_DU(4) & t_DU(4) & '0') + ("00" & t_DU(2) & t_DU(5) & '0');

  t_carry_BCD 	 <= "00" when t_sum_bin_1 < 10 else
              	    "01" when t_sum_bin_1 < 20 else
              	    "10";

  t_unidades_BCD <= t_sum_bin_1(3 downto 0)      when t_carry_BCD = 0 else
                    t_sum_bin_1(3 downto 0) + 6  when t_carry_BCD = 1 else
                    t_sum_bin_1(3 downto 0) + 12;

  t_decenas_BCD  <= ('0' & t_DU(6) & t_DU(6) & t_DU(4)) + ("00" & t_DU(5) & t_DU(5)) + t_carry_BCD;

  salida_BCD 	 <= t_centenas_BCD & t_decenas_BCD & t_unidades_BCD;

  process(clk,nRst) 								--Filtro antirebote de 3 FF
    begin
    if nRst = '0' then
      pulsador_s <= (others => '1');
    elsif clk'event and clk = '1' then
      pulsador_s <= pulsador_s(1 downto 0) & pulsador;
    end if;
  end process;

  pulsador_aux <= '0' when pulsador_s(1) = '0' and pulsador_s(2) = '1' else '1';
end rtl;