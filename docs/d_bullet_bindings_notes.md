# D ↔ Bullet C-API Bindings: Notes + Resources + Working Steps (macOS arm64)

These notes capture **what we just did successfully** (Bullet C-API shim + D smoke test), plus the minimum theory you need to continue confidently.

---

## 1) Where to learn this binding process (top resources)

### Core D interoperability docs (authoritative)
1. **D Language Spec — Interfacing to C** (the rules that make `extern(C)` work, type/layout compatibility, structs, callbacks, arrays, etc.).  
   Source: https://dlang.org/spec/interfaceToC.html citeturn0search0

2. **D Wiki — D binding for C** (practical binding patterns, linking notes, ImportC pointers, examples).  
   Source: https://wiki.dlang.org/D_binding_for_C citeturn0search12

3. **D Blog — “Interfacing D with C: Getting Started”** (hands-on walkthrough style, very close to what you’re doing).  
   Source: https://dlang.org/blog/2017/12/05/interfacing-d-with-c-getting-started/ citeturn0search4

### Bullet-specific (what “the C API” is and where it lives)
4. **Bullet repo: the “physics-engine agnostic C-API” header** (`examples/SharedMemory/PhysicsClientC_API.h`) and surrounding code.  
   Source: https://github.com/bulletphysics/bullet3/issues/2647 citeturn1search31  
   (The header/code lives in the Bullet repo under `examples/SharedMemory/…`.)

5. **Bullet discussion: linker dependencies for the C API / DIRECT backend** (why you needed more libs than `BulletDynamics/BulletCollision/LinearMath`).  
   Source: https://github.com/bulletphysics/bullet3/discussions/3895 citeturn0search6

### macOS dynamic linking (rpath / @executable_path)
- **Understanding `@rpath`, `@executable_path`, and dyld loading**  
  Source: https://itwenty.me/posts/01-understanding-rpath/ citeturn0search7  
- **rpath + otool/install_name_tool deep dive**  
  Source: https://medium.com/@donblas/fun-with-rpath-otool-and-install-name-tool-e3e41ae86172 citeturn0search3

### Videos (useful to build intuition)
- **DConf 2023 — Getting from C to D without Tripping** (practical interop pitfalls).  
  Source: https://www.youtube.com/watch?v=4dPfrKkLmV8 citeturn1search3
- **DConf 2024 — State of C++ Interoperability in D** (why C wrappers are often the pragmatic choice).  
  Source: https://www.youtube.com/watch?v=VBNS1nr2JAw citeturn1search0
- (Optional) **General FFI primer** (language-agnostic mental model).  
  Source: https://www.youtube.com/watch?v=fcx02vw9GNs citeturn1search1

---

## 2) What you need to know vs what you can ignore (for now)

### The “must know” set (to be productive safely)

#### A) ABI vs API (the whole reason this works)
- **API**: the functions/types you *want* to call (`b3ConnectPhysicsDirect`, etc.).
- **ABI**: the *binary rules* for how those calls are represented (symbol names, calling convention, struct layout, exception behavior).
- D can reliably call **C ABI** (`extern(C)`), but **C++ ABI** is complicated (name mangling, classes, templates, exceptions).  
  D’s own C++ interop doc lists “build a C wrapper” as a primary strategy for this reason. citeturn0search1

#### B) Link-time vs Run-time
- **Link-time**: the compiler/ld can resolve symbols when producing the executable (`ldc2 ... -L-lbullet_capi_shim`).
- **Run-time**: the dynamic loader (dyld on macOS) can *find and load* the `.dylib` when you execute the program.
- You hit a run-time failure: `dyld: Library not loaded: @rpath/...`.

#### C) Symbol visibility and “C linkage”
- `extern(C)` on the D side tells D to use C calling conventions and symbol naming.
- On the native side, your shim library exports C symbols (no C++ mangling for the exported API).

#### D) “Opaque handles” pattern
- Bullet C API uses opaque handle types (pointers to incomplete structs).
- You should model these in D as:
  - a dummy struct type + pointer alias (`alias Handle = Handle__*;`)
- You never dereference it in D; you only pass it back to C functions.

#### E) Data layout and alignment
- For struct parameters (vectors, transforms), you must match:
  - field order
  - field types/sizes
  - alignment/padding
- This is usually straightforward with POD-like C structs, but it’s the #1 source of subtle bugs later.

#### F) Ownership and lifetime
- For every `create(...)` there is usually a `destroy(...)`.
- Define the rule: “Who allocates? Who frees?”
- Later, you’ll likely wrap handles in D `struct`/`class` with `~this()` to ensure cleanup.

### The “nice to know later” set (don’t block on this right now)
- `install_name_tool` (only needed for packaging / relocatable app bundles) citeturn0search3
- Complex CMake toolchain configs
- Automating binding generation (ImportC / bindgen-style)
- Advanced dyld topics (codesigning, hardened runtime), unless you ship an app bundle soon

### The “ignore for now” set (until you need it)
- Directly binding Bullet’s C++ API classes/templates
- Cross-platform Windows/MSVC DLL import libraries
- Creating a fully general “engine-agnostic physics layer”
- Multi-threaded physics correctness (do it after basic stepping works)

---

## 3) The whole process at a high level (conceptual map)

You created a working pipeline:

1. **Get Bullet source** (upstream repo).
2. **Build Bullet** (its core libraries) with CMake.
3. **Build a small “shim” dynamic library** (`libbullet_capi_shim.dylib`) that:
   - compiles Bullet’s C-API implementation sources (`examples/SharedMemory/...`)
   - links them against the Bullet libraries they depend on  
     (and, importantly, the DIRECT backend needs a *bigger* set of libraries than the obvious three). citeturn0search6
4. **Write D declarations** for the C API functions/types you call:
   - `extern(C)` functions
   - opaque handle types
5. **Compile a D smoke test** that links to the shim
6. **Fix runtime loader path (dyld)**:
   - either export `DYLD_LIBRARY_PATH`, or
   - embed an rpath (preferred for convenience)

This approach gives you a stable foundation:
- D never talks to C++ ABI directly.
- You keep the exposed surface area minimal and controlled.
- You can grow the binding incrementally (one function at a time).

---

## 4) Exact commands and files that worked (macOS arm64)

Below is a clean “copy/paste” reference of what you ran, including the fixes.

### A) Build the shim (CMake) — known-good approach

**Folder layout (one of many valid options):**
```
BindingsDemos/Bullet/
  bullet3/              # bullet repo clone
  bullet_capi_shim/      # your shim project
    CMakeLists.txt
    build/               # cmake output
```

#### 1) Clone Bullet
```bash
git clone https://github.com/bulletphysics/bullet3.git
```

#### 2) Create `bullet_capi_shim/CMakeLists.txt`

Key ideas:
- Bring Bullet in via `add_subdirectory(...)`
- Force demos OFF
- Build `bullet_capi_shim` dylib from SharedMemory sources
- Link the larger dependency set (DIRECT backend)

*(This is the “fixed” version you used to resolve missing symbols.)*
```cmake
cmake_minimum_required(VERSION 3.16)
project(bullet_capi_shim LANGUAGES C CXX)

set(CMAKE_CXX_STANDARD 11)

set(BULLET3_DIR "${CMAKE_CURRENT_LIST_DIR}/../bullet3")

# Turn OFF bullet examples/demos when bringing bullet in as subproject
set(BUILD_SHARED_LIBS ON  CACHE BOOL "" FORCE)
set(BUILD_CPU_DEMOS   OFF CACHE BOOL "" FORCE)
set(USE_GLUT          OFF CACHE BOOL "" FORCE)
set(USE_GRAPHICAL_BENCHMARK OFF CACHE BOOL "" FORCE)
set(BUILD_PYBULLET    OFF CACHE BOOL "" FORCE)
set(BUILD_BULLET3     ON  CACHE BOOL "" FORCE)

add_subdirectory(${BULLET3_DIR} bullet3_build)

add_library(bullet_capi_shim SHARED
  ${BULLET3_DIR}/examples/SharedMemory/PhysicsClientC_API.cpp
  ${BULLET3_DIR}/examples/SharedMemory/PhysicsDirectC_API.cpp
  ${BULLET3_DIR}/examples/SharedMemory/PhysicsDirect.cpp
)

target_include_directories(bullet_capi_shim PUBLIC
  ${BULLET3_DIR}/src
  ${BULLET3_DIR}/examples/SharedMemory
)

# DIRECT needs a bigger link set (Bullet maintainer confirms this dependency shape) citeturn0search6
target_link_libraries(bullet_capi_shim PRIVATE
  BulletRobotics
  BulletFileLoader
  BulletWorldImporter
  BulletSoftBody
  BulletDynamics
  BulletCollision
  BulletInverseDynamicsUtils
  BulletInverseDynamics
  LinearMath
  Bullet3Common
)
```

#### 3) Configure + build (arm64)
```bash
cd bullet_capi_shim
rm -rf build

cmake -S . -B build   -DCMAKE_BUILD_TYPE=Release   -DCMAKE_OSX_ARCHITECTURES=arm64

cmake --build build -j
```

**Success indicators**
- You get `build/libbullet_capi_shim.dylib`
- No “Undefined symbols for architecture arm64” at link time

---

### B) D bindings: split into module + main

#### 1) Create `bullet_capi.d`
```d
module bullet_capi;

extern(C) {
    struct b3PhysicsClientHandle__ { int unused; }
    alias b3PhysicsClientHandle = b3PhysicsClientHandle__*;

    b3PhysicsClientHandle b3ConnectPhysicsDirect();
    void b3DisconnectSharedMemory(b3PhysicsClientHandle physClient);
}
```

#### 2) Create `main.d`
```d
import std.stdio;
import bullet_capi;

void main() {
    writeln("D -> Bullet C-API smoke test...");

    auto client = b3ConnectPhysicsDirect();
    if (client is null) {
        writeln("FAILED: connect returned null");
        return;
    }

    writeln("OK: connected (non-null handle). Disconnecting...");
    b3DisconnectSharedMemory(client);
    writeln("OK: disconnected. Done.");
}
```

#### 3) Compile the D smoke test
```bash
ldc2 main.d bullet_capi.d   -L-L./build   -L-lbullet_capi_shim   -of=smoke_test
```

#### 4) Run it (dyld fix)
You hit:
```
dyld: Library not loaded: @rpath/libbullet_capi_shim.dylib
```

Fast fix that worked:
```bash
export DYLD_LIBRARY_PATH="$PWD/build:$DYLD_LIBRARY_PATH"
./smoke_test
```

**Expected output (what you got):**
```
D -> Bullet C-API smoke test...
OK: connected (non-null handle). Disconnecting...
OK: disconnected. Done.
```

#### 5) (Optional) Better fix: embed rpath so you don’t need DYLD_LIBRARY_PATH
Rebuild with:
```bash
ldc2 main.d bullet_capi.d   -L-L./build   -L-lbullet_capi_shim   -L-rpath -L@executable_path/build   -of=smoke_test
```

Now `./smoke_test` should work without exporting `DYLD_LIBRARY_PATH`.

To inspect rpaths:
```bash
otool -l smoke_test | grep -A2 LC_RPATH
```

---

## Next recommended milestone (when you continue)
After connect/disconnect, the next minimal “real functionality” test is:

1) connect
2) set gravity
3) create a simple rigid body
4) step simulation N frames
5) read back position

We’ll add *only the necessary* C-API functions in `bullet_capi.d`, one at a time, and keep the test small.

---

## Quick glossary (so logs make sense)
- **dylib**: macOS shared library.
- **dyld**: macOS dynamic loader.
- **@rpath**: placeholder resolved using embedded runpaths.
- **@executable_path**: “directory containing the executable”.
- **undefined symbols**: link-time error = missing libraries or missing object files.
- **opaque handle**: a pointer you treat as an abstract ID.

---
