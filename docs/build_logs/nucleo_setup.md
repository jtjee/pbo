# Nucleo setup (STM32F401RE)

**Date:** 2026-10-11

Bare-metal Rust project for the Nucleo-F401RE in `firmware/nucleo`. It uses a custom linker script and startup code instead of `cortex-m-rt`, flashes with probe-rs, and debugs in VS Code with Cortex-Debug and ST-Link.

## Tools installed

| Tool | Install | Version |
| --- | --- | --- |
| [just](https://github.com/casey/just) (casey/just) | `cargo install just` | 1.58.0 |
| probe-rs (`probe-rs`, `cargo-flash`, `cargo-embed`) | `cargo install probe-rs-tools` | 0.32.0 |
| svd-vector-gen | `cargo install svd-vector-gen` | 0.1.5 |
| Rust target | `rustup target add thumbv7em-none-eabihf` | |
| STM32CubeCLT | ST installer | GNU tools 14.3.1+st.2 |
| Cortex-Debug | VS Code extension | |

## Steps

### 1. Create the crate

```bash
cd firmware
cargo new nucleo
cd nucleo
```

### 2. Cargo config

`.cargo/config.toml` sets the default target, passes the linker script, and runs binaries on the board through probe-rs:

```toml
[build]
target = "thumbv7em-none-eabihf"

[target.thumbv7em-none-eabihf]
rustflags = [
  "-C", "link-arg=-Tmemory.ld"
]
runner = 'probe-rs run --chip STM32F401RE'
```

### 3. Linker script and startup code

- `memory.ld`: copied from template. FLASH is 512K at `0x08000000` and RAM is 96K at `0x20000000`. The entry point is `Reset_Handler`, and the script `INCLUDE`s `device_STM32F401.x`.
- `src/startup_stm32f401.rs`: copied from template. It holds `Reset_Handler`, `Default_Handler`, the fault handlers and the `.isr_vector` table.
- `src/main.rs`: `#![no_std]`/`#![no_main]`, with an empty `main` loop and a panic handler.

### 4. Generate the interrupt vector linker file

Download the SVD file from the [STM32F401 CAD resources](https://www.st.com/en/microcontrollers-microprocessors/stm32f401.html#cad-resources) page, then:

```bash
mkdir -p third-party/st
cp <path/to/svd/file.svd> ./third-party/st/STM32F401.svd
cd third-party/st
svd-vector-gen
mv device_STM32F401.x ../../
```

`svd-vector-gen` scans the current directory for `.svd` files. It writes `device_STM32F401.x`, which uses `PROVIDE` to point every handler at `Default_Handler`. It also writes `vector_STM32F401.txt`, which contains Rust handler stubs and stays in `third-party/st`.

### 5. Flashing

`justfile`:

```just
flash:
    cargo flash --chip STM32F401RE
```

### 6. VS Code debugging

1. Installed STM32CubeCLT and the Cortex-Debug extension.
2. Pointed Cortex-Debug at the CubeCLT GNU toolchain in the VS Code user settings:

   ```json
   "cortex-debug.armToolchainPath.osx": "/Users/<username>/Library/Application Support/stm32cube/bundles/gnu-tools-for-stm32/14.3.1+st.2/bin"
   ```

3. `.vscode/tasks.json`: the task `rust: cargo build[MCU]` runs `cargo build` in `firmware/nucleo` and is the default build task.
4. `.vscode/launch.json`: the configuration "Debug with ST-Link" uses `cortex-debug` with `servertype: stlink`. It loads `target/thumbv7em-none-eabihf/debug/nucleo` and the SVD file for peripheral views, runs to `main`, and builds first through the task above.

## Usage

From `firmware/nucleo`:

```bash
cargo build    # build
cargo run      # flash and run via probe-rs
just flash     # flash only
```

To debug, press F5 in VS Code and choose **Debug with ST-Link**.
