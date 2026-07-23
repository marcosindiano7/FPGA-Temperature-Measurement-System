# MEDT - FPGA Temperature Measurement System

Digital temperature measurement system implemented in **VHDL** and prototyped on a **DECA MAX 10 FPGA development board**.

The system acquires temperature measurements from an **LM71 sensor through an SPI interface**, converts the measured value between Celsius, Kelvin and Fahrenheit, and presents the result on a multiplexed eight-digit seven-segment display.

The measurement period and temperature scale can be changed using the push buttons available on the DECA board.

## Overview

MEDT was developed as part of the *Digital Design 2* course at Universidad Politécnica de Madrid.

The objective of the project was to design, verify, synthesize and physically prototype a complete synchronous digital system using RTL design techniques.

Unlike a software-based temperature controller, the complete functionality of this project is implemented directly in digital hardware using VHDL. The design includes:

- SPI communication control
- Finite-state machines
- Serial-to-parallel data acquisition
- Signed binary processing
- Hardware arithmetic
- Binary-to-BCD conversion
- Push-button event detection
- Seven-segment display multiplexing
- Functional simulation
- FPGA synthesis and implementation

## Main Features

- Temperature acquisition from an **LM71 digital sensor**
- Custom **SPI master interface**
- Temperature range from **-40 °C to 150 °C**
- Integer temperature resolution
- Three selectable temperature scales:
  - Celsius
  - Kelvin
  - Fahrenheit
- Four selectable measurement periods:
  - 2 seconds
  - 4 seconds
  - 6 seconds
  - 8 seconds
- Cyclic scale selection using a push button
- Cyclic sampling-period selection using a push button
- Signed temperature representation
- Suppression of non-significant leading zeros
- Binary-to-BCD conversion implemented in hardware
- Eight-digit multiplexed seven-segment display
- New-measurement indicator displayed for one second
- Asynchronous system reset
- Functional verification using ModelSim
- Physical implementation using Quartus Prime
- Prototyping on DECA MAX 10 and XDECA boards

## System Architecture

The complete data path is:

```text
LM71 Temperature Sensor
          │
          │ SPI
          ▼
   SPI Timing Generator
          │
          ▼
 SPI Transaction Controller
          │
          ▼
 9-bit Serial Input Register
          │
          ▼
 Sign and Magnitude Processing
          │
          ▼
 Temperature Scale Conversion
          │
          ▼
     Binary-to-BCD
          │
          ▼
 Seven-Segment Display Controller
```

The system is implemented as a hierarchical structural design. The top-level entity connects several independent and reusable RTL modules.

## RTL Modules

### `interfaz_spi.vhd`

Top-level structural entity of the system.

It integrates all functional blocks and connects:

- The LM71 SPI interface
- The two push buttons
- The reset input
- The seven-segment display outputs
- The display-selection outputs

### `gen_sc.vhd`

Generates the timing signals required by the SPI communication interface.

The module derives the serial clock and provides additional single-cycle pulses used to:

- Detect rising clock edges
- Detect falling clock edges
- Sample the incoming data in the middle of each SPI bit

### `control_spi.vhd`

Controls the complete SPI measurement transaction.

It contains:

- An FSM for the SPI acquisition sequence
- A counter for the received bits
- The LM71 chip-select control
- The serial-clock enable signal
- The serial-register enable signal
- A pulse indicating that a new measurement is available
- An FSM for selecting the measurement period

The acquisition FSM uses the following states:

```text
IDLE → START → TRANSFER → STOP
```

The period-selection logic rotates cyclically between:

```text
2 s → 4 s → 6 s → 8 s → 2 s
```

### `reg_in_out_spi.vhd`

Implements a serial-to-parallel shift register.

It receives the temperature bits transmitted by the LM71 and produces a parallel 9-bit temperature value containing:

- One sign bit
- Eight temperature bits

The data is sampled at the configured point of the SPI clock cycle.

### `control_medidas.vhd`

Processes the signed temperature value received from the SPI register.

The LM71 value is interpreted in two's-complement format. The module separates it into:

- Sign
- Absolute temperature magnitude

Negative measurements are converted from two's complement into their corresponding positive magnitude before being processed by the scale-conversion block.

### `conv_escala_BCD.vhd`

Converts the measured Celsius temperature into the selected temperature scale.

A three-state FSM rotates between:

```text
Celsius → Kelvin → Fahrenheit → Celsius
```

The conversion logic is implemented using combinational hardware arithmetic.

The Fahrenheit calculation uses additions and bit shifts instead of a dedicated hardware multiplier.

The converted temperature is then transformed into a three-digit BCD value:

```text
Hundreds | Tens | Units
```

This module also generates the sign and scale information required by the display controller.

### `rep_disp.vhd`

Controls the eight-digit seven-segment display.

The displays are multiplexed so that only one digit is physically active at a time. The switching frequency is sufficiently high for all digits to appear continuously illuminated.

The display information is distributed as follows:

| Display | Information |
|---:|---|
| 0 | Selected temperature scale |
| 1 | Blank separator |
| 2 | Temperature units |
| 3 | Temperature tens or negative sign |
| 4 | Temperature hundreds or negative sign |
| 5 | Blank separator |
| 6 | Selected measurement period |
| 7 | New-measurement indicator |

Display 7 shows a `0` for approximately one second whenever a new temperature measurement has been received.

The module also suppresses non-significant leading zeros.

## User Interface

The system uses the two push buttons available on the DECA board.

One button changes the temperature scale cyclically:

```text
Celsius → Kelvin → Fahrenheit → Celsius
```

The other button changes the measurement period:

```text
2 s → 4 s → 6 s → 8 s → 2 s
```

The selected configuration is immediately reflected on the seven-segment displays.

## Temperature Representation

The system supports positive and negative temperatures.

Positive examples:

```text
25 C
298 K
77 F
```

Negative values are displayed with the minus sign placed in the highest available position.

Examples:

```text
-5 C
-20 C
```

Non-significant zeros are not displayed.

## Verification

The design was functionally verified using **ModelSim**.

The testbench includes an SPI slave model that emulates the behaviour of the LM71 temperature sensor.

The simulation applies a sequence of 191 temperature measurements covering:

```text
0 °C to 150 °C
-40 °C to -1 °C
```

The verification process exercises:

- SPI chip-select timing
- Serial-clock generation
- Serial temperature acquisition
- Positive and negative temperature processing
- Scale selection
- Measurement-period selection
- BCD conversion
- Display multiplexing
- New-measurement indication
- Integration of all RTL modules

## FPGA Implementation

The final design was synthesized and implemented using **Quartus Prime** for the following FPGA:

```text
Family: MAX 10
Device: 10M50DAF484C6GES
Top-level entity: interfaz_spi
Input clock: 50 MHz
```

The design was successfully compiled and physically prototyped on:

- DECA MAX 10 development board
- XDECA display expansion board
- Integrated LM71 temperature sensor

## Resource Utilization

The final Quartus implementation reported:

| Resource | Utilization |
|---|---:|
| Logic elements | 405 / 49,760 |
| Combinational functions | 391 |
| Dedicated registers | 156 |
| I/O pins | 22 / 360 |
| Memory bits | 0 |
| Embedded multipliers | 0 |
| PLLs | 0 |

The complete design uses less than **1% of the available logic elements** in the selected MAX 10 FPGA.

The unit conversions, BCD conversion and control logic are implemented without embedded multiplier blocks.

## Hardware Used

- **DECA MAX 10 FPGA development board**
- **Intel/Altera MAX 10 FPGA**
- **XDECA expansion board**
- **LM71 digital temperature sensor**
- Eight seven-segment displays
- Two push buttons
- Reset switch
- 50 MHz system clock

## Software and Tools

- **VHDL**
- **ModelSim**
- **Quartus Prime**
- RTL simulation
- TimeQuest Timing Analyzer
- FPGA programming tools

## Repository Structure

```text
.
├── README.md
├── .gitignore
│
├── VHD/
│   ├── interfaz_spi.vhd
│   ├── gen_sc.vhd
│   ├── control_spi.vhd
│   ├── reg_in_out_spi.vhd
│   ├── control_medidas.vhd
│   ├── conv_escala_BCD.vhd
│   └── rep_disp.vhd
│
├── simulation/
│   ├── tb_medt.vhd
│   └── run.do
│
├── quartus/
│   ├── hito3.qpf
│   ├── hito3.qsf
│   └── hito3.sdc
│
├── docs/
│   ├── MEDT_technical_report.pdf
│   ├── architecture.png
│   ├── simulation-waveform.png
│   └── prototype.jpg
│
└── reports/
    ├── resource_utilization.txt
    └── timing_summary.txt
```

## Running the Simulation

Open ModelSim from the repository root and execute:

```tcl
do simulation/run.do
```

The script should:

1. Create the working library
2. Compile the RTL files
3. Compile the testbench
4. Start the simulation
5. Add the main signals to the waveform window
6. Run the complete test sequence

## Building the FPGA Project

1. Open Quartus Prime.
2. Open:

```text
quartus/hito3.qpf
```

3. Run a complete compilation.
4. Review the Analysis & Synthesis, Fitter and TimeQuest reports.
5. Connect the DECA MAX 10 board.
6. Program the generated `.sof` file using the Quartus Programmer.
7. Connect the XDECA display expansion board.
8. Use the push buttons to change the temperature scale and sampling period.

## Skills Demonstrated

This project demonstrates practical experience in:

- RTL design with VHDL
- FPGA development
- Hierarchical digital design
- Synchronous circuit design
- Finite-state machine implementation
- SPI protocol implementation
- Digital sensor integration
- Serial-to-parallel conversion
- Two's-complement arithmetic
- Hardware-based unit conversion
- Binary-to-BCD conversion
- Seven-segment display multiplexing
- Push-button synchronization and event detection
- ModelSim testbench development
- Functional verification
- Quartus synthesis and implementation
- FPGA resource analysis
- Physical FPGA prototyping
- Hardware debugging and system integration

## Future Improvements

- Develop a fully self-checking testbench with assertions
- Add automated regression tests
- Add functional coverage for all temperatures and configurations
- Use `ieee.numeric_std` for all arithmetic operations
- Improve push-button debouncing
- Add explicit input and output timing constraints
- Add a decimal temperature digit
- Add configurable alarm thresholds
- Add minimum and maximum temperature storage
- Add a UART interface for external monitoring
- Add continuous integration using GHDL and GitHub Actions
- Create reusable generic modules for the counters and display controller

## Academic Context

This project was developed as a collaborative four-student assignment for the **Digital Design 2** course at Universidad Politécnica de Madrid.

The development followed three incremental milestones:

1. LM71 SPI temperature acquisition
2. Temperature-scale conversion and BCD processing
3. Complete system integration, display control, FPGA implementation and physical prototyping

## Author

**Marcos Indiano**  
Electronic Engineering Student  
Universidad Politécnica de Madrid

Developed as part of a four-student engineering team.
