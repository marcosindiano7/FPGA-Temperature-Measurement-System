library ieee;
use ieee.std_logic_1164.all;

-- Se lee la temperatura del sensor LM71 por SPI a intervalos seleccionables de 2, 4, 6 u 8 s (cambiados con KEY0)
-- Tras cada lectura ilumina un ?0? en el display 7 durante 1 s 
-- Muestra la temperatura entera (?40 °C ? 150 °C) en los displays 2-4
-- Escala en el display 0 (?C?, ?°?, ?F?, cambio con KEY1)
-- El periodo activo en el display 6 (2/4/6/8)
-- Mantiene apagados los displays 1 y 5 como separadores
-- Los valores negativos se indican colocando ??? en la posición de mayor peso libre
-- Todo se multiplexa a ~400 Hz a partir del reloj de 50 MHz, con lógica síncrona y filtros antirrebote en ambos pulsadores
entity interfaz_spi is
  port(
    clk	       : in  std_logic;   			-- 50MHz (placa)
    nRst       : in	std_logic;			-- Reset
    KEY_0      : in	std_logic;			-- Botón 0
    KEY_1      : in	std_logic;			-- Botón 0
    SDAT       : in     std_logic;			-- Entrada de la línea de datos
    CS         : buffer std_logic;			-- ChipSelect LM71
    CL         : buffer std_logic;			-- Reloj SPI (hacia sensor)
    sel_disp   : buffer std_logic_vector(7 downto 0);	-- Selector de display (Se pone a 0 cuando queremos encender un display)
    segmentos  : buffer std_logic_vector(6 downto 0)	-- Cada uno de los segmentos del display de 7 segmentos
  );
end entity;
architecture structural of interfaz_spi is
  signal scl_i     : std_logic;  			-- Reloj interno 5MHz
  signal rising_i  : std_logic;  			-- Pulso
  signal ena_i     : std_logic;  			-- ena
  signal temp_int  : std_logic_vector(8 downto 0); 	-- Temperatura
  signal ena_temp  : std_logic;
  signal SC_ena    : std_logic;
  signal SC_down   : std_logic;
  signal SC_meas   : std_logic;
  signal signo_1   : std_logic;
  signal dato_bin  : std_logic_vector(7 downto 0);
  signal periodo   : std_logic_vector(3 downto 0);
  signal signo     : std_logic;
  signal salida_BCD: std_logic_vector(11 downto 0);
  signal escala    : std_logic_vector(1 downto 0);


begin

-- Hito 1 ------------------------------------------------------------------------
  u_div : entity work.gen_sc(rtl)  			-- Divisor 50MHz -> 5MHz
    port map(
      clk     => clk,
      nRst    => nRst,
      SC      => scl_i,
      SC_up   => rising_i,
      SC_ena  => SC_ena,
      SC_down => SC_down,
      SC_meas => SC_meas);
  u_ctrl : entity work.control_spi(rtl)	  		-- Control SPI (FSM + contadores)
    port map(
      clk          => clk,
      nRst         => nRst,
      SCL          => scl_i,
      CS           => CS,
      nueva_medida => ena_temp,
      ena_in_reg   => ena_i,
      SC_ena	   =>SC_ena,
      scl_up 	   => rising_i,
      SC_down	   =>SC_down,
      pulsador_d   => KEY_1,
      periodo	   => periodo);
  u_reg : entity work.reg_in_out_spi(rtl)  		-- Registro de entrada (9 bits)
    port map(
      clk  	   => clk,
      nRst         => nRst,
      sio_in       => SDAT,
      ena_shift    => ena_i,
      temp_bin     => temp_int,
      SC_meas	   => SC_meas);
  CL <= scl_i;  					-- Pin SC (reloj SPI hacoa sensor)
  u_med : entity work.control_medidas(rtl) 		-- Ajuste de signo y magnitud (complemento a 2)
    port map(
      clk          => clk,
      nRst         => nRst,
      nueva_medida => ena_temp,
      dato_in      => temp_int,
      dato_out     => dato_bin,
      signo        => signo_1);

-- Hito 2 ------------------------------------------------------------------------
  u_conv : entity work.conv_escala_BCD(rtl)		-- Cambio de escala (C, K y F)
    port map(
      clk          => clk,
      nRst         => nRst,
      dato_in      => dato_bin,
      signo        => signo_1, 
      pulsador     => KEY_0,
      salida_BCD   => salida_BCD,
      signo_out    => signo,		 
      escala       => escala);

-- Hito 3 ------------------------------------------------------------------------
  u_disp : entity work.rep_disp(rtl)			-- Representación de los displays
    port map (
      clk          => clk,
      nRst         => nRst,
      temp_BCD     => salida_BCD,
      signo        => signo,
      escala       => escala,
      disp         => segmentos,
      mux          => sel_disp,
      periodo      => periodo,
      nueva_medida => ena_temp);

end structural;