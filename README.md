# Python distribution for riSim Studio

- [1. Windows](#1-windows)
  - [1.1. Creating the `python314.lib` file](#11-creating-the-python314lib-file)

## 1. Windows

Building Python under Windows is ~~painful~~ "complicated", even with python-build-standalone.
We instead use an embeddable, pre-built distribution from [python.org](https://www.python.org/downloads/windows/), and add VUnit and its dependencies to it.

### 1.1. Creating the `python314.lib` file

Under Windows, the `python314.lib` file is required to link with the `python314.dll`.
This file isn't included in the pre-built distribution, so we need to create it ourselves; fortunately, it only needs to be re-created when the Python version changes.

1. Open a *x64 Native Tools Command Prompt* and run:

   ```bat
   dumpbin /exports python314.dll > python314.def
   ```

2. Edit `python314.def` to add `EXPORTS` to the top of the file, then remove everything else except for the raw exported symbol names.
   The file should look like this now:

   ```plain
   EXPORTS
   PY_TIMEOUT_MAX
   PyAIter_Check
   ...
   ```

3. Run the following command to create the `python314.lib` file:

   ```bat
   lib /def:python314.def /out:python314.lib /machine:x64
   ```

For convenience, both the `python314.def` and `python314.lib` files are checked into the repository.
