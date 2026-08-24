# riscv-soc-core

A modular RISC-V System-on-Chip core featuring an **AXI4** main interconnect bridged to an **APB** peripheral bus, dual instruction/data RAM, boot RAM, and a full peripheral suite including SPI (master & slave), UART, and a JTAG-based Advanced Debug Unit.

This project is designed as an extensible foundation for FPGA prototyping and further SoC/peripheral development.

---

## 📐 Architecture Overview

The SoC is organized around a layered bus hierarchy:

- **RISC-V Core** — connects to instruction memory, data memory, and a debug port
- **AXI4 Interconnect** — high-bandwidth bus linking the core to memories and bridge modules
- **AXI-to-APB Bridge** — steps down to the lower-speed APB bus for peripheral access
- **APB Bus** — connects simple peripherals (UART, SPI Master, Timer, Event Unit)
- **SPI Slave** — connects directly on AXI4 for external host access
- **Advanced Debug Unit** — JTAG interface for debug/trace access into the core



## ✨ Features

- RISC-V core with separate instruction, data, and debug interfaces
- Instruction RAM, Data RAM, and dedicated Boot RAM
- AXI4 interconnect for core and high-speed peripheral access
- AXI4 ↔ APB bridge for low-power/low-speed peripherals
- Peripherals:
  - UART
  - SPI Master
  - SPI Slave (AXI4-connected, external host access)
  - Timer
  - Event Unit
- Advanced Debug Unit with JTAG interface
---

## 📁 Repository Structure

```
riscv-soc-core/
├── rtl/            # RTL source (core, bus fabric, peripherals)
├── tb/             # Testbenches
├── docs/           # Diagrams, architecture notes, specs
├── sim/            # Simulation scripts/configs
├── fpga/           # FPGA-specific constraints, build scripts
└── README.md
```

---

## 🚀 Getting Started

> Setup and build instructions coming soon.

```bash
git clone https://github.com/<your-username>/riscv-soc-core.git
cd riscv-soc-core
```

---

## 🛠️ Roadmap

- [ ] Core integration and verification
- [ ] AXI4 interconnect implementation
- [ ] AXI-to-APB bridge
- [ ] Peripheral IP integration (GPIO, UART, I²C, SPI)
- [ ] Debug unit / JTAG verification
- [ ] FPGA synthesis and bring-up
- [ ] Full testbench and simulation suite

---

## 👥 Authors

- **Hossam Fawzy**
- **Mostafa Hosny**
- **Doaa**

---

## 📄 License

This project is currently unlicensed. Add a license (e.g., MIT, Apache 2.0) before public release if you intend for others to use or contribute to it.
