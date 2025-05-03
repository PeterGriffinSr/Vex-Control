# Getting Started with Vex

Welcome to Vex! This guide will help you install Vex, write your first program, and understand the basics to get up and running quickly.

---

## Installation

Follow these steps to install Vex:

### Option 1: Using Prebuilt Binaries (Recommended)
1. Visit the [official Vex website](#) and download the latest release for your operating system.
2. Extract the archive and add the `vex` binary to your system's `PATH`.

### Option 2: Building from Source
If you prefer to build Vex from source, follow the instructions below:

#### For Linux/Windows (x86_64)
1. Install `ghcup`, the official Haskell toolchain installer, by visiting the [ghcup website](https://www.haskell.org/ghcup/) and following the installation guide.
2. Clone the Vex repository and build the project:
    ```bash
    git clone https://github.com/PeterGriffinSr/Vex.git
    cd Vex
    cabal build
    ```

#### Special Instructions for x86 Windows Users
If you're using an x86 Windows system, switch to the `x86-windows` branch before building:
```bash
git checkout x86-windows
```

#### For Linux (i386)
If you're on a 32-bit Linux system, install the toolchain manually:

1. **Install GHC**:
    ```bash
    wget https://downloads.haskell.org/~ghc/9.6.7/ghc-9.6.7-i386-deb9-linux.tar.xz
    tar -xf ghc-9.6.7-i386-deb9-linux.tar.xz
    cd ghc-9.6.7
    ./configure
    sudo make install
    ```

2. **Install Cabal**:
    ```bash
    wget https://downloads.haskell.org/~cabal/Cabal-3.12.1.0/
    tar -xf Cabal-3.12.1.0.tar.gz
    sudo mv cabal /usr/local/bin
    ```

3. Verify the installation:
    ```bash
    ghc --version
    cabal --version
    ```

4. Build Vex:
    ```bash
    git clone https://github.com/PeterGriffinSr/Vex.git
    cd Vex
    cabal build
    ```

---

## Writing Your First Vex Program

1. Create a file named `main.vex` with the following content:
    ```h
    val () -> int: main fn () =>
         print<string> "Hello, world";
         0;
    ```

2. Compile and run the program:
    ```bash
    vex main.vex -o hello
    ./hello
    ```

---

## Using the REPL

Experiment with Vex interactively using the REPL:
```bash
vex repl
```

$f = \frac{5}{4}$

For example:
```h
> val (int) -> int: square fn (x) => x * x;
> square(4);
> 16
```

---