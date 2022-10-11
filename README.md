# PowerPy
PowerPy is a PowerShell script that installs Python projects into separate virtual environments and makes it easy to call them afterwards.

## Freatures
- A single, self-contained, and easy to use script that can run on any Windows machine with Python and Git installed.
- Supports installing projects that require repo cloning, Pip, or [Pipenv](https://pipenv.pypa.io/en/latest) into seperate environments out of the box.
- Allows calling installed projects without changing to their directories and activating their virtual environments.
- Supports updating downloaded projects.

## Installation
Make sure to have Python and Git installed, and then clone the repo or copy the `powerpy.ps1` file to the directory you want to install the tools in.

## Usage
PowerPy uses an interanal hash table to know which tools to install.
To add a new tool, create a new line after line 7 (`$PythonTools = [ordered]@{}`) that looks like this:
```powershell
$PythonTools["Project name"] = @{Download = "Download method"; Exec = "How is the tool executed" }
```
For example:
```powershell
# Installation method 1: git clone
$PythonTools["carbon14"] = @{Download = "git clone https://github.com/Lazza/Carbon14.git"; Exec = "python .\carbon14.py" }
# Installation method 2: pip install
$PythonTools["maigret"] = @{Download = "python -m pip install maigret"; Exec = "maigret" }
```

Run the script and follow the on-screen instructions:
```powershell
.\powerpy.ps1
```

Restart your terminal for changes to take effect.
Prefix `tool-` to the tool's name and use it as you normally would:
```powershell
tool-[tool name] [arguments]
```
For example:
```powershell
tool-maigret --help
```

## ToDo
- [ ] Provide support for [Poetry](https://python-poetry.org) projects out of the box. Right now tools using Poetry require it to be preinstalled.

## Credits
All credit for the tools used as examples - [Carbon14](https://github.com/Lazza/Carbon14), [Maigret](https://github.com/soxoj/maigret), and [Telegram-phone-number-checker](https://github.com/bellingcat/telegram-phone-number-checker) - goes to their respective developers.
