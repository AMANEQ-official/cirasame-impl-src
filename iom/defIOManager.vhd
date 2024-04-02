library ieee, mylib;
use ieee.std_logic_1164.all;
use mylib.defBCT.all;

package defIOManager is
  -- Local Address  -------------------------------------------------------
  constant kSelDiscri              : LocalAddressType := x"000"; -- W/R, [6:0], select discriminator output
  constant kSelDaqSig              : LocalAddressType := x"010"; -- W/R, [2:0], select daq signal out
  constant kIoOnOff                : LocalAddressType := x"020"; -- W/R, [1:0], NIM_OUT on/off

end package defIOManager;

