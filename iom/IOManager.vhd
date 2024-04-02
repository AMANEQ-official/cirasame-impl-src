library IEEE, mylib;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
use ieee.math_real.all;

use mylib.defBCT.all;
use mylib.defIOManager.all;

entity IOManager is
  generic(
    kNumInput           : integer:= 128
  );
  port(
    rst	                : in std_logic;
    clk	                : in std_logic;

    -- Module Input --
    discriIn            : in std_logic_vector(kNumInput-1 downto 0);
    triggerSig          : in std_logic;
    heartbeatSig        : in std_logic;
    tcpActive           : in std_logic;

    -- Module output --
    discriMuxOut        : out std_logic;
    daqSigOut           : out std_logic;

    -- Local bus --
    addrLocalBus        : in LocalAddressType;
    dataLocalBusIn      : in LocalBusInType;
    dataLocalBusOut	    : out LocalBusOutType;
    reLocalBus          : in std_logic;
    weLocalBus          : in std_logic;
    readyLocalBus	      : out std_logic
    );
end IOManager;

architecture RTL of IOManager is

  -- System --
  signal sync_reset           : std_logic;

  -- internal signal declaration ----------------------------------------
  constant kWidthDiscriReg  : integer:= integer(ceil(log2(real(kNumInput))));
  constant kWidthDaqReg     : integer:= 2;

  signal daq_sig            : std_logic;

  signal reg_discri	: std_logic_vector(kWidthDiscriReg-1 downto 0);
  signal reg_daq	  : std_logic_vector(kWidthDaqReg-1 downto 0);
  signal reg_onoff  : std_logic_vector(1 downto 0);
  signal state_lbus	: BusProcessType;

-- =============================== body ===============================
begin

  discriMuxOut  <= reg_onoff(0) and discriIn(to_integer(unsigned(reg_discri)));
  daqSigOut     <= reg_onoff(1) and daq_sig;

  daq_sig       <= triggerSig   when(reg_daq = "00") else
                   heartbeatSig when(reg_daq = "01") else
                   tcpActive    when(reg_daq = "10") else '0';

  u_BusProcess : process(clk)
  begin
    if(clk'event and clk = '1') then
      if(sync_reset = '1') then
        reg_discri		<= (others => '0');

        state_lbus	<= Init;
      else
        case state_lbus is
          when Init =>
            dataLocalBusOut       <= x"00";
            readyLocalBus		<= '0';
            reg_discri		<= (others => '0');
            state_lbus		<= Idle;

          when Idle =>
            readyLocalBus	<= '0';
            if(weLocalBus = '1' or reLocalBus = '1') then
              state_lbus	<= Connect;
            end if;

          when Connect =>
            if(weLocalBus = '1') then
              state_lbus	<= Write;
            else
              state_lbus	<= Read;
            end if;

          when Write =>
            case addrLocalBus(kNonMultiByte'range) is
              when kSelDiscri(kNonMultiByte'range) =>
                reg_discri	<= dataLocalBusIn(kWidthDiscriReg-1 downto 0);
              when kSelDaqSig(kNonMultiByte'range) =>
                reg_daq	    <= dataLocalBusIn(kWidthDaqReg-1 downto 0);
              when kIoOnOff(kNonMultiByte'range) =>
                reg_onoff	  <= dataLocalBusIn(1 downto 0);
              when others => null;
            end case;
            state_lbus	<= Done;

          when Read =>
            case addrLocalBus(kNonMultiByte'range) is
              when kSelDiscri(kNonMultiByte'range) =>
                dataLocalBusOut <= '0' & reg_discri;
              when kSelDaqSig(kNonMultiByte'range) =>
                dataLocalBusOut <= "000000" & reg_daq;
              when kIoOnOff(kNonMultiByte'range) =>
                dataLocalBusOut <= "000000" & reg_onoff;
              when others =>
                dataLocalBusOut <= x"ff";
            end case;
            state_lbus	<= Done;

          when Done =>
            readyLocalBus	<= '1';
            if(weLocalBus = '0' and reLocalBus = '0') then
              state_lbus	<= Idle;
            end if;

          -- probably this is error --
          when others =>
            state_lbus	<= Init;
        end case;
      end if;
    end if;
  end process u_BusProcess;

  -- Reset sequence --
  u_reset_gen_sys   : entity mylib.ResetGen
    port map(rst, clk, sync_reset);

end RTL;

