-- registradores + UART simples p/ ESP32

--Observação: este bloco espera que você já tenha um UART RX/TX que entregue bytes (rx_stb/rx_data) e aceite bytes para envio (tx_stb/tx_data). Como alternativa, ligue isso a um IP UART existente (Altera/Intel) ou substitua por SPI.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.fuzzy_pkg.all;

entity uart_regs_simple is
  port(
    clk      : in  std_logic;
    rst_n    : in  std_logic;
    -- UART RX/TX (conectar a um UART já pronto; aqui supomos interface "char prontos")
    rx_stb   : in  std_logic;   -- pulso indicando byte válido em rx_data
    rx_data  : in  unsigned(7 downto 0);
    tx_stb   : out std_logic;   -- pulso para enviar tx_data
    tx_data  : out unsigned(7 downto 0);

    -- registros expostos internamente
    soil_pct : out u8; temp_c : out u8; luz_pct : out u8; water_pct : out u8;
    wd_kick  : out std_logic;
    pump_on  : in  std_logic; pump_ms : in u16; fault_code: in std_logic_vector(3 downto 0); status_reg: in std_logic_vector(3 downto 0)
  );
end entity;

architecture rtl of uart_regs_simple is
  -- endereços
  constant ADR_SOIL  : unsigned(7 downto 0) := x"00";
  constant ADR_TEMP  : unsigned(7 downto 0) := x"01";
  constant ADR_LIGHT : unsigned(7 downto 0) := x"02";
  constant ADR_WATER : unsigned(7 downto 0) := x"03";
  constant ADR_CTRL  : unsigned(7 downto 0) := x"04";

  constant ADR_PUMP  : unsigned(7 downto 0) := x"10";
  constant ADR_MS_L  : unsigned(7 downto 0) := x"11";
  constant ADR_MS_H  : unsigned(7 downto 0) := x"12";
  constant ADR_FAULT : unsigned(7 downto 0) := x"13";
  constant ADR_STAT  : unsigned(7 downto 0) := x"14";

  signal soil_r, temp_r, light_r, water_r : u8 := (others=>'0');
  signal wd_pulse : std_logic := '0';

  type state_t is (IDLE, GOT_HDR, GOT_ADDR);
  signal st : state_t := IDLE;
  signal op_write : std_logic;  -- 1=write, 0=read
  signal addr_buf : unsigned(7 downto 0) := (others=>'0');

begin
  soil_pct  <= soil_r;
  temp_c    <= temp_r;
  luz_pct   <= light_r;
  water_pct <= water_r;
  wd_kick   <= wd_pulse;

  -- Protocolo: WRITE: 0xA5 <addr> <value>
  --            READ : 0x5A <addr>        -> resposta: <value>
  process(clk, rst_n)
  begin
    if rst_n='0' then
      st <= IDLE; op_write<='0'; addr_buf<=(others=>'0'); wd_pulse<='0'; tx_stb<='0'; tx_data<=(others=>'0');
      soil_r<=(others=>'0'); temp_r<=(others=>'0'); light_r<=(others=>'0'); water_r<=(others=>'0');
    elsif rising_edge(clk) then
      tx_stb <= '0'; wd_pulse <= '0';
      if rx_stb='1' then
        case st is
          when IDLE =>
            if rx_data = x"A5" then op_write<='1'; st<=GOT_HDR;
            elsif rx_data = x"5A" then op_write<='0'; st<=GOT_HDR;
            end if;
          when GOT_HDR =>
            addr_buf <= rx_data; st <= GOT_ADDR;
          when GOT_ADDR =>
            if op_write='1' then
              -- write caminho
              if    addr_buf=ADR_SOIL  then soil_r  <= u8(rx_data);
              elsif addr_buf=ADR_TEMP  then temp_r  <= u8(rx_data);
              elsif addr_buf=ADR_LIGHT then light_r <= u8(rx_data);
              elsif addr_buf=ADR_WATER then water_r <= u8(rx_data);
              elsif addr_buf=ADR_CTRL  then wd_pulse<= rx_data(1); -- bit1=wd_kick
              end if;
              st <= IDLE;
            else
              -- read caminho
              if    addr_buf=ADR_PUMP  then tx_data <= (others=>'0'); tx_data(0) <= pump_on;
              elsif addr_buf=ADR_MS_L  then tx_data <= pump_ms(7 downto 0);
              elsif addr_buf=ADR_MS_H  then tx_data <= pump_ms(15 downto 8);
              elsif addr_buf=ADR_FAULT then tx_data <= unsigned('0' & fault_code); -- 4 bits
              elsif addr_buf=ADR_STAT  then tx_data <= unsigned('0' & status_reg); -- 4 bits
              else                        tx_data <= (others=>'0');
              end if;
              tx_stb <= '1';
              st <= IDLE;
            end if;
        end case;
      end if;
    end if;
  end process;
end architecture;


