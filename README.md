# 2nd-Order Sigma-Delta DAC on Basys 3

A 1-bit PDM (pulse-density modulation) DAC implemented in Verilog for the Digilent Basys 3 (Xilinx Artix-7), using a 2nd-order noise-shaping modulator, with a live 7-segment decimal readout of the input code and LED mirroring for sanity-checking switch input.

Flip the 8 slide switches to set an 8-bit code (0–255). The design converts it to a 1-bit PDM stream on a Pmod pin; feed that through a simple RC low-pass filter to recover an analog voltage proportional to the switch setting.

## Features

- **2nd-order sigma-delta modulator** (`sigma_delta_dac_2nd.v`) — cascaded integrators (CIFB topology) with saturating accumulators, guaranteeing the accumulator states can never overflow the register width regardless of input code or run length. Gives better noise shaping (pushes quantization noise to higher frequency, away from the passband) than a simple 1st-order accumulator.
- **7-segment display driver** (`seg7_display.v` + `bin_to_bcd8.v`) — shows the current switch value as a live 3-digit decimal number (000–255) on the Basys 3's multiplexed display.
- **LED mirror** — LD0–LD7 mirror the switch state, independent of the DAC, for a quick sanity check that switch input is being read correctly.

## File overview

| File | Purpose |
|---|---|
| `top.v` | Top-level: wires switches → DAC + display, DAC output → Pmod JA pin 1, switches → LEDs |
| `sigma_delta_dac_2nd.v` | 2nd-order sigma-delta modulator |
| `seg7_display.v` | Multiplexed 4-digit 7-segment display driver |
| `bin_to_bcd8.v` | 8-bit binary → 3-digit BCD converter (double-dabble algorithm) |
| `basys_3.xdc` | Board constraints: clock, switches, LEDs, reset button, PDM output pin, 7-segment pins, bitstream config |
| `tb_sigma_delta_dac_2nd.v` | Testbench — checks duty cycle within ±4 LSB tolerance over a 4096-sample window |

## Building and simulating

### Behavioral simulation (Icarus Verilog)

```bash
iverilog -g2012 -o sim2 sigma_delta_dac_2nd.v tb_sigma_delta_dac_2nd.v
vvp sim2
```

Prints a per-code PASS/FAIL table and a final `ALL TESTS PASSED` / `TESTS FAILED` summary, and dumps a `.vcd` waveform for viewing in GTKWave or Vivado's waveform viewer.

### Vivado (synthesis → bitstream)

1. Create a new project targeting your Basys 3 part (e.g. `xc7a35tcpg236-1`).
2. Add `top.v`, `sigma_delta_dac_2nd.v`, `seg7_display.v`, and `bin_to_bcd8.v` as design sources.
3. Add `basys_3.xdc` as a constraints source.
4. Run synthesis → implementation → generate bitstream.
5. Check `report_drc` and `report_timing_summary` before programming — this design should close with 0 DRC violations and comfortable positive slack at 100 MHz, but always verify rather than assume.

```tcl
# Quick Tcl-console equivalent
add_files {top.v sigma_delta_dac_2nd.v seg7_display.v bin_to_bcd8.v}
add_files -fileset constrs_1 basys_3.xdc
synth_design -top top -part xc7a35tcpg236-1
opt_design; place_design; route_design
report_drc
report_timing_summary -delay_type max -report_unconstrained
write_bitstream -force top.bit
```

## Hardware setup

`pdm_out` (Pmod JA, pin 1 / `J1`) is a raw 1-bit PDM bitstream — on its own it just looks like a fast digital square-ish wave, not an analog voltage. To recover the actual DC level:

1. Build a simple RC low-pass filter: R ≈ 4.7–10 kΩ, C ≈ 0.01–0.1 µF (adjust for your desired cutoff — lower cutoff = smoother output but slower to settle).
2. Connect Pmod JA pin 1 → R → node → C → GND.
3. Measure/probe the analog output across C.

Sweeping the switches from 0 to 255 should give a roughly linear voltage ramp from 0V to ~3.3V.

## Design notes / known behavior

- Uses a CIFB (cascade-of-integrators, feedback) structure with **saturating integrators** — this is a required part of the design, not an optional safety margin. A naive equal-gain two-integrator cascade *without* saturation was tested and found to be only conditionally stable: integrator states drift unboundedly for some input codes and eventually overflow. Saturation guarantees the accumulator states stay within a fixed bound for every input code and every run length.
- DC tracking is accurate to within a few LSBs over long measurement windows (verified in simulation against an exhaustive/extended-run sweep of input codes, including the edge cases 0, 1, 254, 255).
- The 7-segment display shows `sw` directly (the DAC's *input* code), not a measurement of the analog output — it's a debug aid for confirming what code is being fed to the DAC, not a voltmeter.

