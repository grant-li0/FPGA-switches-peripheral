# SCOMP Smart Switches

ECE 2031 FPGA project integrating a Smart Switches peripheral with the SCOMP processor. The peripheral computes values from the board's ten switches and exposes them through memory-mapped I/O instructions.

## Layout

| Path | Contents |
| --- | --- |
| `src/` | VHDL for SCOMP, Smart Switches, timer, display, digital output, and clock divider |
| `schematics/` | Top-level block diagrams and schematic symbols |
| `asm/` | Assembly examples/tests and corresponding memory initialization files |
| `ip/pll/` | Generated PLL HDL, IP settings, and associated simulation support files |
| `constraints/` | Original timing-constraint file |
| `tools/scasm.cfg` | Configuration for the SCOMP assembler |
| `SCOMP.qpf`, `SCOMP.qsf` | Quartus project and device/pin/source assignments |

## Smart Switches interface

| I/O address | Value |
| --- | --- |
| `0x060` | Current switch value |
| `0x061` | Two's-complement negative of the switch value |
| `0x062` | Number of switches up |
| `0x063` | Number of switches down |
| `0x064` | Highest-numbered raised switch |
| `0x065` | Lowest-numbered raised switch |
| `0x066` | Write to save a baseline; read to return current switches XOR baseline |

See `src/SSW.vhd` for the implementation and exact behavior.

## Opening the project

Open `SCOMP.qpf` in Intel Quartus Prime. The project targets the Cyclone V `5CSXFC6D6F31C6`, with `SCOMP_System` as its top-level entity. Use the repository root as the working directory when compiling.

The project currently initializes processor memory from `asm/ATM.mif`. To select another included program, change the `init_file` setting in `src/SCOMP.vhd` and the `MIF_FILE` assignment in `SCOMP.qsf` to the corresponding image in `asm/`.

The `.mif` files are retained so that existing programs can be used without first assembling them. Assembly sources and `tools/scasm.cfg` are included, but the assembler executable is not part of this snapshot.

The original `SCOMP.sdc` is empty and is preserved under `constraints/`. No timing constraints have been added or timing closure verified. The project settings record Quartus 25.1 Standard Lite as the last-used version; the generated PLL metadata records version 24.1.

## Organization changes

- Grouped diagrams and symbols under `schematics/` and PLL files under `ip/pll/`.
- Updated Quartus source/IP paths and added schematic/assembly search paths.
- Replaced the missing `IODemo.mif` assignment with `asm/ATM.mif`, matching the program selected by the CPU source.
- Updated the CPU's memory-image path to `asm/ATM.mif`.
- Omitted build databases, backup copies, workspace preferences, the generated IP report, and the pin-model dump.

The CPU memory-image path is the only functional source setting changed during organization. HDL logic was not modified. File references were checked, but the reorganized project has not been compiled or tested in Quartus.

## Attribution

This project includes ECE 2031 SCOMP support material and generated Intel FPGA PLL files. Their inclusion does not imply original authorship of all files. Preserve existing notices and distinguish your peripheral/program contributions from supplied course infrastructure when describing the project.
