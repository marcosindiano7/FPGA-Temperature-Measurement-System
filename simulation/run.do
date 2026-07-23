# ============================================================
# ModelSim simulation script
# MEDT - FPGA Temperature Measurement System
# ============================================================

# ============================================================
# ModelSim simulation script
# MEDT - FPGA Temperature Measurement System
#
# IMPORTANT:
# Run this script from the repository root:
# do simulation/run.do
# ============================================================

# Use the current ModelSim directory as the repository root.
set ROOT_DIR [file normalize [pwd]]

set RTL_DIR    [file join $ROOT_DIR "VHD"]
set SCRIPT_DIR [file join $ROOT_DIR "simulation"]
set TB_DIR     $SCRIPT_DIR
set WORK_DIR   [file join $SCRIPT_DIR "work"]

# Check that the script is being executed from the repository root.
if {![file isdirectory $RTL_DIR]} {
    puts ""
    puts "ERROR: VHD directory not found."
    puts "Current directory: $ROOT_DIR"
    puts ""
    puts "Run the following commands before executing the script:"
    puts "cd {PATH_TO_REPOSITORY}"
    puts "do {simulation/run.do}"
    puts ""
    error "The script must be executed from the repository root."
}

# Store the transcript inside the simulation directory.
transcript file [file join $SCRIPT_DIR "modelsim_transcript.log"]
transcript on

puts "============================================================"
puts "MEDT ModelSim simulation"
puts "Repository root: $ROOT_DIR"
puts "RTL directory:   $RTL_DIR"
puts "Testbench:       $TB_DIR"
puts "Work library:    $WORK_DIR"
puts "============================================================"

# Create the compiled VHDL library if it does not exist.
if {![file exists $WORK_DIR]} {
    vlib $WORK_DIR
}

vmap work $WORK_DIR

puts "============================================================"
puts "MEDT ModelSim simulation"
puts "Repository root: $ROOT_DIR"
puts "============================================================"

# Create the compiled VHDL library if it does not exist.
if {![file exists $WORK_DIR]} {
    vlib $WORK_DIR
}

vmap work $WORK_DIR

# ============================================================
# Compile RTL modules
# ============================================================

puts "Compiling RTL modules..."

vcom -2008 -work work [file join $RTL_DIR "gen_sc.vhd"]
vcom -2008 -work work [file join $RTL_DIR "control_spi.vhd"]
vcom -2008 -work work [file join $RTL_DIR "reg_in_out_spi.vhd"]
vcom -2008 -work work [file join $RTL_DIR "control_medidas.vhd"]
vcom -2008 -work work [file join $RTL_DIR "conv_escala_BCD.vhd"]
vcom -2008 -work work [file join $RTL_DIR "rep_disp.vhd"]
vcom -2008 -work work [file join $RTL_DIR "interfaz_spi.vhd"]

# ============================================================
# Compile testbench
# ============================================================

puts "Compiling testbench..."

vcom -2008 -work work [file join $TB_DIR "test_interfaz_spi_entrega.vhd"]

# ============================================================
# Start simulation
# ============================================================

puts "Starting simulation..."

vsim -voptargs=+acc work.test_interfaz_spi

# ============================================================
# Waveform configuration
# ============================================================

delete wave *

add wave -divider "CLOCK AND RESET"
add wave -radix binary sim:/test_interfaz_spi/clk
add wave -radix binary sim:/test_interfaz_spi/nRst

add wave -divider "USER INPUTS"
add wave -radix binary sim:/test_interfaz_spi/key0
add wave -radix binary sim:/test_interfaz_spi/key1

add wave -divider "SPI INTERFACE"
add wave -radix binary sim:/test_interfaz_spi/CS
add wave -radix binary sim:/test_interfaz_spi/CL
add wave -radix binary sim:/test_interfaz_spi/SDAT
add wave -radix hexadecimal sim:/test_interfaz_spi/temp

add wave -divider "DISPLAY OUTPUTS"
add wave -radix binary sim:/test_interfaz_spi/sel_disp
add wave -radix binary sim:/test_interfaz_spi/segmentos

add wave -divider "INTERNAL DUT SIGNALS"
add wave -radix binary sim:/test_interfaz_spi/dut/scl_i
add wave -radix binary sim:/test_interfaz_spi/dut/rising_i
add wave -radix binary sim:/test_interfaz_spi/dut/ena_i
add wave -radix signed sim:/test_interfaz_spi/dut/temp_int
add wave -radix binary sim:/test_interfaz_spi/dut/ena_temp
add wave -radix unsigned sim:/test_interfaz_spi/dut/dato_bin
add wave -radix unsigned sim:/test_interfaz_spi/dut/periodo
add wave -radix binary sim:/test_interfaz_spi/dut/signo
add wave -radix hexadecimal sim:/test_interfaz_spi/dut/salida_BCD
add wave -radix binary sim:/test_interfaz_spi/dut/escala

configure wave -namecolwidth 250
configure wave -valuecolwidth 120
configure wave -timelineunits us

# Run until the testbench finishes.
run -all

wave zoom full

puts "============================================================"
puts "Simulation completed"
puts "============================================================"