--control_spi de 5 MHz 

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity control_spi is					   -- Control que lanza una lectura cada 4 segundos
  port(
    clk          : in     std_logic;	            	   -- 50 MHz de placa
    nRst         : in     std_logic;	
    SCL          : in     std_logic;	            	   -- Reloj SPI externo
    CS           : buffer std_logic;	            	   -- Chip Select del LM71
    nueva_medida : buffer std_logic;	            	   -- Pulso fin de lectura
    ena_in_reg   : buffer std_logic;	            	   -- Habilita reg_in_out_spi
    SC_ena	 : buffer std_logic;			   -- Habilita gen_SC
    SC_down	 : in     std_logic;			   -- Pulso flanco bajada SC
    scl_up       : in     std_logic;			   -- Pulso flanco subida SC
    pulsador_d   : in     std_logic;
    periodo      : buffer std_logic_vector(3 downto 0)
  );
end entity;

architecture rtl of control_spi is
							   -- Estados (luego leer(espera, empieza, tranfiere, para))
  type estado_t is (IDLE, START, TRANSFER, STOP);
  signal estado         : estado_t := IDLE;
--  constant dos_seg 	: natural:= 100000000;
--  constant dos_seg_esc 	: natural:= 10000;
--  constant cuatro_seg 	: natural:= 200000000;
--  constant cuatro_seg_esc 	: natural:= 20000;
--  constant seis_seg 	: natural:= 300000000;
--  constant seis_seg_esc 	: natural:= 30000;
--  constant ocho_seg 	: natural:= 400000000;
--  constant ocho_seg_esc 	: std_logic_vector(29 downto 0):= 40000;

  type estado_t2 is (cnt2seg, cnt4seg, cnt6seg, cnt8seg);  -- FSM cambio de escala
  signal estado_cnt     : estado_t2 := cnt2seg;

  -- Contadores
  signal cnt_spi        : std_logic_vector (3 downto 0);   -- 9 bits para lectura
  signal cnt_s          : std_logic_vector(28 downto 0);   -- 4 s × 50 MHz
  signal cs_int         : std_logic := '1';		   -- CS interno
  signal cnt_2_4_6_8    : std_logic_vector(29 downto 0);
  signal pulsador_d_s   : std_logic_vector(2 downto 0);
  signal pulsador_d_aux : std_logic;

begin
  process(clk, nRst)
  begin
    if nRst = '0' then					   -- Al reset iniciamos en CONFIG
      estado       <= IDLE;
      cs_int       <= '1';
      cnt_spi      <= (others => '0');
      cnt_s        <= (others => '0');
      nueva_medida <= '0';
      SC_ena	   <= '0';
      ena_in_reg   <= '0';
    elsif clk'event and clk = '1' then
      case estado is
        when IDLE =>					   -- 1) IDLE: esperamos 4 s antes de leer
          nueva_medida <= '0';
	  if pulsador_d_aux = '0' then 
            cnt_s <= (others => '0');
          elsif cnt_s = cnt_2_4_6_8 then 
               cnt_s  <= (others => '0');
               cs_int <= '0';    			   -- Bajamos CS para arrancar lectura
	       SC_ena <= '1';				   -- Encendemos el reloj
               estado <= START;
          else
            cnt_s <= cnt_s + 1;
          end if;
        when START =>					   -- 2) START: Esperamos primer flanco de bajada SCL
          if SCL = '0' then
            cnt_spi <= (others => '0');
            estado  <= TRANSFER; 
   	    ena_in_reg  <= '1';
          end if;
        when TRANSFER =>        			   -- 3) TRANSFER: leemos 9 bits por flanco de subida
          if scl_up = '1' then
            if cnt_spi = "1000" then
              estado <= STOP;
            else
              cnt_spi <= cnt_spi + 1;
            end if;
          end if;
        when STOP =>        				   -- 4) STOP: Esperamos flanco de bajada, finalizamos lectura y volvemos a IDLE
            if SC_down = '1' then
	         SC_ena	      <='0';			   -- Apagamos el reloj
          	 cs_int       <= '1';
          	 nueva_medida <= '1';
		 ena_in_reg   <= '0';
         	 estado       <= IDLE;
        end if;
      end case;
    end if;
  end process;
  CS        <= cs_int;



  process(clk, nRst)
  begin
    if nRst = '0' then					   -- Al reset iniciamos en CONFIG
      estado_cnt     <= cnt2seg;
      cnt_2_4_6_8  <= "000101111101011110000100000000"; -- 00101111101011110000100000000 Escalado: 000000000001011111010111100001
      periodo <= "0010";

    elsif clk'event and clk = '1' then
      case estado_cnt is
        when cnt2seg =>	
	  cnt_2_4_6_8  <= "000101111101011110000100000000"; -- 00101111101011110000100000000 Escalado: 000000000001011111010111100001
	  periodo <= "0010";
	  if pulsador_d_aux ='0' then 
            estado_cnt <= cnt4seg;
	  end if;
	
	when cnt4seg =>
	  cnt_2_4_6_8  <= "001011111010111100001000000000";  -- 01011111010111100001000000000 Escalado:000000000010111110101111000010
	  periodo <= "0100";
	  if pulsador_d_aux ='0' then 
            estado_cnt <= cnt6seg;
	  end if;
	when cnt6seg =>
	  cnt_2_4_6_8  <= "010001111000011010001100000000";  --10001111000011010001100000000 Escalado: 000000000100011110000110100011
	  periodo <= "0110";
	  if pulsador_d_aux ='0' then 
            estado_cnt <= cnt8seg;
	  end if;
	when cnt8seg =>
	  cnt_2_4_6_8  <= "010111110101111000010000000000";  --10111110101111000010000000000 Escalado: 000000000101111101011110000100
	  periodo <= "1000";
	  if pulsador_d_aux ='0' then 
            estado_cnt <= cnt2seg;
	  end if;
	end case;
    end if;
  end process;
 

   process(clk,nRst) 
    begin
    if nRst = '0' then
      pulsador_d_s <= (others => '1');
    elsif clk'event and clk = '1' then
      pulsador_d_s <= pulsador_d_s(1 downto 0) & pulsador_d;
    end if;
  end process;

  pulsador_d_aux <= '0' when pulsador_d_s(1) = '0' and pulsador_d_s(2) = '1' else '1';

end architecture;