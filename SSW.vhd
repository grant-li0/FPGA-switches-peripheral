-- SSW.VHD
-- Smart Switches peripheral for SCOMP
--
-- This peripheral replaces the default Switches peripheral.
-- It uses I/O addresses 0x060 through 0x066.
--
-- Important idea:
-- SCOMP does not directly "do" the switch calculations.
-- The peripheral hardware does the calculations internally,
-- then SCOMP reads the result using IN instructions.
--
-- Address map:
-- 0x060 : sswPos     -> current switch value
-- 0x061 : sswNeg     -> two's complement negative of switch value
-- 0x062 : sswUp      -> number of switches currently up
-- 0x063 : sswDown    -> number of switches currently down
-- 0x064 : sswMSB     -> highest-numbered raised switch
-- 0x065 : sswLSB     -> lowest-numbered raised switch
-- 0x066 : sswChange  -> OUT saves baseline, IN returns current XOR baseline
--
-- This version assumes the DE10 board has 10 switches.
-- Therefore, only EXT_WIRES(9 DOWNTO 0) are used as switch inputs.

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY SSW IS
  PORT(
    IO_ADDR   : IN    STD_LOGIC_VECTOR(10 DOWNTO 0);
    IO_READ   : IN    STD_LOGIC;
    IO_WRITE  : IN    STD_LOGIC;
    EXT_WIRES : IN    STD_LOGIC_VECTOR(15 DOWNTO 0);
    IO_DATA   : INOUT STD_LOGIC_VECTOR(15 DOWNTO 0);
    CLOCK     : IN    STD_LOGIC;
    RESETN    : IN    STD_LOGIC
  );
END SSW;

ARCHITECTURE a OF SSW IS

  -- Address family decode:
  -- 0x060 is binary 00001100000.
  -- For addresses 0x060 through 0x067, IO_ADDR(10 DOWNTO 3) = "00001100".
  CONSTANT SSW_BASE : STD_LOGIC_VECTOR(7 DOWNTO 0) := "00001100";

  SIGNAL IN_RANGE  : STD_LOGIC;
  SIGNAL DEVICE    : STD_LOGIC_VECTOR(2 DOWNTO 0);
  SIGNAL READ_DATA : STD_LOGIC_VECTOR(15 DOWNTO 0);

  -- Only the lower 10 bits are actual switch values on the DE10 board.
  SIGNAL switches10 : STD_LOGIC_VECTOR(9 DOWNTO 0);

  -- Used by sswChange.
  -- OUT 0x066 saves the current switches here as a baseline.
  -- IN 0x066 compares current switches to this saved baseline.
  SIGNAL saved_switches : STD_LOGIC_VECTOR(9 DOWNTO 0);

  -- Output signals for each device in SSW
  SIGNAL dev0_data, dev1_data, dev2_data, dev3_data,
         dev4_data, dev5_data, dev6_data
         : STD_LOGIC_VECTOR(15 DOWNTO 0);

BEGIN

  --------------------------------------------------------------------
  -- Address decoding
  --------------------------------------------------------------------
  IN_RANGE <= '1' WHEN IO_ADDR(10 DOWNTO 3) = SSW_BASE ELSE '0';

  -- Low 3 bits select the function:
  -- 000 = 0x060, 001 = 0x061, etc.
  DEVICE <= IO_ADDR(2 DOWNTO 0);

  -- Use only the DE10 switch bits.
  switches10 <= EXT_WIRES(9 DOWNTO 0);

  --------------------------------------------------------------------
  -- 0x060: sswPos
  -- Returns current switch values.
  -- Upper 6 bits are forced to 0 because there are only 10 switches.
  --------------------------------------------------------------------
  dev0_data <= "000000" & switches10;

  --------------------------------------------------------------------
  -- 0x061: sswNeg
  -- Returns the 16-bit two's complement negative of the switch value.
  --
  -- We use numeric_std conversions here instead of doing NOT(value)+1
  -- directly on std_logic_vector. This is safer because std_logic_vector
  -- is not meant to be used as a number unless converted. As a logic
  -- vector, it is treated as just a bunch of wires grouped together.
  --------------------------------------------------------------------
  dev1_data <= STD_LOGIC_VECTOR(
                 TO_SIGNED(-TO_INTEGER(UNSIGNED(switches10)), 16)
               );

  --------------------------------------------------------------------
  -- 0x062: sswUp
  -- Counts how many switches are currently up.
  --------------------------------------------------------------------
  PROCESS (switches10)
    VARIABLE total : INTEGER RANGE 0 TO 10;
  BEGIN
    total := 0;

    FOR i IN 0 TO 9 LOOP
      IF switches10(i) = '1' THEN
        total := total + 1;
      END IF;
    END LOOP;

    dev2_data <= STD_LOGIC_VECTOR(TO_UNSIGNED(total, 16));
  END PROCESS;

  --------------------------------------------------------------------
  -- 0x063: sswDown
  -- Counts how many switches are currently down.
  --------------------------------------------------------------------
  PROCESS (switches10)
    VARIABLE total : INTEGER RANGE 0 TO 10;
  BEGIN
    total := 0;

    FOR i IN 0 TO 9 LOOP
      IF switches10(i) = '0' THEN
        total := total + 1;
      END IF;
    END LOOP;

    dev3_data <= STD_LOGIC_VECTOR(TO_UNSIGNED(total, 16));
  END PROCESS;

  --------------------------------------------------------------------
  -- 0x064: sswMSB
  -- Returns the highest-numbered switch that is currently up.
  --
  -- Example:
  -- If SW2, SW5, and SW8 are up, this returns 8.
  --
  -- If no switch is up, this returns 15 / 0xF.
  -- 0xF is useful because valid DE10 switch numbers are only 0 through 9.
  --------------------------------------------------------------------
  PROCESS (switches10)
    VARIABLE idx   : INTEGER RANGE 0 TO 15;
    VARIABLE found : BOOLEAN;
  BEGIN
    idx := 15;
    found := FALSE;

    FOR i IN 9 DOWNTO 0 LOOP
      IF (switches10(i) = '1') AND (NOT found) THEN
        idx := i;
        found := TRUE;
      END IF;
    END LOOP;

    dev4_data <= STD_LOGIC_VECTOR(TO_UNSIGNED(idx, 16));
  END PROCESS;

  --------------------------------------------------------------------
  -- 0x065: sswLSB
  -- Returns the lowest-numbered switch that is currently up.
  --
  -- Example:
  -- If SW2, SW5, and SW8 are up, this returns 2.
  --
  -- If no switch is up, this returns 15 / 0xF.
  --------------------------------------------------------------------
  PROCESS (switches10)
    VARIABLE idx   : INTEGER RANGE 0 TO 15;
    VARIABLE found : BOOLEAN;
  BEGIN
    idx := 15;
    found := FALSE;

    FOR i IN 0 TO 9 LOOP
      IF (switches10(i) = '1') AND (NOT found) THEN
        idx := i;
        found := TRUE;
      END IF;
    END LOOP;

    dev5_data <= STD_LOGIC_VECTOR(TO_UNSIGNED(idx, 16));
  END PROCESS;

  --------------------------------------------------------------------
  -- 0x066: sswChange
  --
  -- OUT 0x066:
  --   Saves the current switches as the baseline.
  --
  -- IN 0x066:
  --   Returns current switches XOR saved baseline.
  --
  -- Why XOR?
  -- XOR gives 1 when two bits are different.
  -- So if a switch changed compared to the saved baseline,
  -- that switch's bit becomes 1 in the result.
  --
  -- Example:
  -- saved baseline = 0000000000
  -- current value  = 0000000001
  -- XOR result     = 0000000001
  -- This means SW0 changed.
  --------------------------------------------------------------------
  dev6_data <= "000000" & (switches10 XOR saved_switches);

  PROCESS (CLOCK, RESETN)
  BEGIN
    IF RESETN = '0' THEN
      saved_switches <= "0000000000";

    ELSIF RISING_EDGE(CLOCK) THEN
      IF (IN_RANGE = '1') AND (DEVICE = "110") AND (IO_WRITE = '1') THEN
        saved_switches <= switches10;
      END IF;
    END IF;
  END PROCESS;

  --------------------------------------------------------------------
  -- Select which function returns data to SCOMP.
  --------------------------------------------------------------------
  WITH DEVICE SELECT READ_DATA <=
    dev0_data           WHEN "000",   -- 0x060
    dev1_data           WHEN "001",   -- 0x061
    dev2_data           WHEN "010",   -- 0x062
    dev3_data           WHEN "011",   -- 0x063
    dev4_data           WHEN "100",   -- 0x064
    dev5_data           WHEN "101",   -- 0x065
    dev6_data           WHEN "110",   -- 0x066
    "0000000000000000"  WHEN OTHERS;  -- 0x067 unused

  --------------------------------------------------------------------
  -- Shared tri-state bus driver.
  -- The peripheral only drives IO_DATA when SCOMP is reading from
  -- this address range. Otherwise, it releases the bus with high-Z.
  --------------------------------------------------------------------
  IO_DATA <= READ_DATA WHEN (IN_RANGE = '1') AND (IO_READ = '1')
             ELSE "ZZZZZZZZZZZZZZZZ";

END a;