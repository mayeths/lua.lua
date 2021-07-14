# ✨Lua.lua

[Lua](https://www.lua.org/) language implemented in Lua (half-finished).

[![Open in Visual Studio Code](https://open.vscode.dev/badges/open-in-vscode.svg)](https://open.vscode.dev/mayeths/lua.lua)

### Usage

```bash
git clone http://github.com/mayeths/lua.lua
cd lua.lua

luac -o quicksort.bytecode ./benchmark/quicksort.lua
### Use lua runtime
lua ./quicksort.bytecode
### Use llua runtime
lua ./llua.lua ./quicksort.bytecode
```

### Components

- Compiler (not implemented)
- Runtime
    - Virtual Machine (implemented without solid tests)
    - Standard Library (only `print()`)

### Dependence

This project is build on the top of Lua 5.3.3, which has `Integer`, `Package`, and
other useful features. Lua 5.4 and higher have changed the header of binary
chunk, so lua.lua is not compatible with them at the moment.


<details>
<summary><strong>Install prebuilt Lua 5.3.3 for Windows x86_64</strong></summary>

Modify `$install_top=` bellow if installing to another directory.

```powershell
# Powershell

# Download Lua 5.3.3 from sourceforge
$src="https://master.dl.sourceforge.net/project/luabinaries/5.3.3/Tools%20Executables/lua-5.3.3_Win64_bin.zip"
$dst="$env:TMP/lua53.zip"
$agent="[Microsoft.PowerShell.Commands.PSUserAgent]::FireFox"
Invoke-WebRequest -UserAgent $agent -OutFile $dst -Uri $src

# Unzip to output directory
$install_top="$env:userprofile/Desktop/lua53"
Expand-Archive -Path $dst -DestinationPath $install_top
mv "$install_top/lua53.exe" "$install_top/lua.exe"
mv "$install_top/luac53.exe" "$install_top/luac.exe"

# Add to PATH environment variable
$oldpath = [Environment]::GetEnvironmentVariable('PATH', 'User')
[Environment]::SetEnvironmentVariable('PATH', "$install_top;$oldpath",'User')
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","User") + ";$env:Path"

# Test version (should print "Lua 5.3.3")
lua.exe -v
luac.exe -v
```
</details>


<details>
<summary><strong>Install prebuilt Lua 5.3.3 for Linux x86_64</strong></summary>

Modify `export INSTALL_TOP=` bellow if installing to another directory.

```bash
#!/bin/bash

# Download Lua 5.3.3 from sourceforge
export SRC=https://master.dl.sourceforge.net/project/luabinaries/5.3.3/Tools%20Executables/lua-5.3.3_Linux32_64_bin.tar.gz
export DST=/tmp/lua53.tar.gz
wget -O $DST $SRC

# Unzip to output directory
export INSTALL_TOP=~/lua53
mkdir $INSTALL_TOP 2>/dev/null
tar -xf $DST -C $INSTALL_TOP
mv $INSTALL_TOP/lua53 $INSTALL_TOP/lua
mv $INSTALL_TOP/luac53 $INSTALL_TOP/luac

# Add to PATH environment variable
echo "export PATH=$INSTALL_TOP:\$PATH" >> ~/.bashrc
source ~/.bashrc

# (Optional) Ensure libreadline.so.6 exists to run lua
# (Assuming on x86_64 Ubuntu)
sudo apt-get install libreadline-dev
cd /lib/x86_64-linux-gnu/
sudo ln -s libreadline.so.7.0 libreadline.so.6 2> /dev/null

# Test version (should print "Lua 5.3.3")
lua -v
luac -v
```
</details>


<details>
<summary><strong>Build Lua 5.3.3 from source code for Linux</strong></summary>

Modify `export INSTALL_TOP=` bellow if installing to another directory.

```bash
#!/bin/bash

# Download Lua 5.3.3 source code from lua.org/ftp/
export SRC=https://www.lua.org/ftp/lua-5.3.3.tar.gz
export DST=/tmp/lua53_source_code.tar.gz
wget -O $DST $SRC

# Unzip to directory
export OUTPUT=/tmp/lua53_source_code
mkdir $OUTPUT 2>/dev/null
tar -xf $DST -C $OUTPUT --strip-components=1

# Build Lua 5.3.3 using make
export INSTALL_TOP=~/lua53
cd $OUTPUT
make linux
mkdir $INSTALL_TOP 2>/dev/null
make install INSTALL_TOP=$INSTALL_TOP

# Add to PATH environment variable
echo "export PATH=$INSTALL_TOP/bin:\$PATH" >> ~/.bashrc
source ~/.bashrc

# (Optional) Ensure libreadline.so.6 exists to run lua
# (Assuming on x86_64 Ubuntu)
sudo apt-get install libreadline-dev
cd /lib/x86_64-linux-gnu/
sudo ln -s libreadline.so.7.0 libreadline.so.6 2> /dev/null

# Test version (should print "Lua 5.3.3")
lua -v
luac -v
```
</details>
