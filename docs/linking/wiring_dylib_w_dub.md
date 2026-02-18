# Using a `.dylib` in a DUB (D language) Project on macOS

This guide documents the correct, reproducible way to integrate a dynamic library (`.dylib`) into a DUB project.
The process solves two distinct problems: **link-time** and **run-time** resolution.

---

# Core Concepts

Once you have a `.dylib`, there are **two problems** to solve:

## 1. Link Time

The linker must:

* Find the library
* Know what to link against

If not solved → compile/link errors.

## 2. Runtime (macOS `dyld`)

At runtime macOS must:

* Locate the `.dylib` when executable runs

If not solved →

```
dyld: Library not loaded
```

Both must be handled correctly.

---

# Recommended Structure

Place the dylib somewhere stable inside repo:

```
project_root/
 ├── dub.json
 ├── source/
 ├── prog (built executable)
 └── third_party/
      └── bullet/
           └── lib/
                └── libbullet_capi_shim.dylib
```

Example path:

```
third_party/bullet/lib/libbullet_capi_shim.dylib
```

---

# Step-by-Step Setup

## Step 1 — Add dylib to repo (stable location)

Place dylib inside project:

```
third_party/bullet/lib/libbullet_capi_shim.dylib
```

Never rely on random absolute paths outside repo.

---

# Step 2 — Modify `dub.json`

You must do **two things**:

1. Link the dylib at compile time
2. Ensure dylib sits next to executable at runtime

## Add `copyFiles`

Ensures dylib is physically copied beside executable.

```json
"copyFiles": [
    "third_party/bullet/lib/libbullet_capi_shim.dylib"
],
```

## Add linker flags

Tell linker:

* where dylib is
* embed runtime search path

```json
"lflags-osx": [
    "-Wl,-rpath,@executable_path",
    "third_party/bullet/lib/libbullet_capi_shim.dylib"
]
```

### What this does

| Flag                          | Purpose                                           |
| ----------------------------- | ------------------------------------------------- |
| Link via relative path        | lets linker see library                           |
| copyFiles                     | ensures dylib sits beside executable              |
| `-Wl,-rpath,@executable_path` | tells macOS to look next to executable at runtime |

---

# Step 3 — Fix macOS install-name (CRITICAL)

macOS dylibs often remember absolute build paths.
This breaks portability.

Fix it once:

```bash
install_name_tool -id @rpath/libbullet_capi_shim.dylib \
third_party/bullet/lib/libbullet_capi_shim.dylib
```

Verify:

```bash
otool -D third_party/bullet/lib/libbullet_capi_shim.dylib
```

Expected output:

```
@rpath/libbullet_capi_shim.dylib
```

---

# Step 4 — Clean and Build

```bash
dub clean
dub build
```

You should see:

```
Copying files for prog...
```

---

# Step 5 — Confirm dylib beside executable

```bash
ls -lah | grep -E "prog|libbullet"
```

Expected:

```
prog
libbullet_capi_shim.dylib
```

They must be in the same directory.

---

# Step 6 — Verify linkage

Check executable links using `@rpath`:

```bash
otool -L ./prog | grep bullet
```

Expected:

```
@rpath/libbullet_capi_shim.dylib
```

NOT absolute path.

---

# Step 7 — Verify runtime search path

```bash
otool -l ./prog | grep -A2 LC_RPATH
```

Expected:

```
path @executable_path
```

This tells macOS:

> look for dylibs beside executable

---

# Step 8 — Run program

```bash
./prog
```

If setup correct → program runs normally.

If not:

```
dyld: Library not loaded
```

means runtime path issue.

---

# Common Fixes

## If executable references absolute dylib path

Fix with:

```bash
install_name_tool -change \
/ABSOLUTE/PATH/libbullet_capi_shim.dylib \
@rpath/libbullet_capi_shim.dylib \
./prog
```

---

## If dylib depends on other dylibs

Check:

```bash
otool -L third_party/bullet/lib/libbullet_capi_shim.dylib
```

If additional non-system dylibs appear:

* copy them via `copyFiles`
* fix install names similarly

---

# Best Practices

## Ignore build outputs in git

Add to `.gitignore`:

```
prog
libbullet_capi_shim.dylib
```

DUB will copy automatically each build.

---

# Mental Model Summary

## Link time

Compiler must see dylib
→ link via relative path in `lflags-osx`

## Runtime

Executable must find dylib
→ copy beside executable
→ embed rpath `@executable_path`

## macOS requirement

Fix install-name so dylib uses:

```
@rpath/libname.dylib
```

---

# One-command rebuild workflow (future)

Whenever something breaks:

```bash
dub clean
dub build --force
./prog
```

---

# End Result (Correct Setup)

```
project_root/
 ├── prog
 ├── libbullet_capi_shim.dylib   (auto copied)
 ├── dub.json
 └── third_party/bullet/lib/
      └── libbullet_capi_shim.dylib (source)
```

This setup is:

* portable
* reproducible
* macOS-correct
* DUB-native
* future-safe
