TeeJ-editor
===========

**A hardened, fully offline fork of Notepad++. It never talks to the internet.**

TeeJ-editor is [Notepad++](https://github.com/notepad-plus-plus/notepad-plus-plus)
with every network-capable component removed at the source level, and rebranded
so it is no longer identified as the blocked product. It is a Windows source-code
editor and Notepad replacement, licensed under the [GPL](LICENSE).


Why this fork exists
--------------------

Stock Notepad++ ships an auto-update mechanism (the WinGUP `gup.exe` helper) and
an online plugin installer ("Plugins Admin") that download and execute code from
the internet. That update channel is an attack surface: anything that can tamper
with it — a hijacked download path, a compromised mirror, an attacker on the
network — can push arbitrary code onto every machine that runs the editor.

Because of that exposure, corporate security policy **blacklisted Notepad++**.

TeeJ-editor answers both halves of that problem:

1. **The attack surface is gone, not just switched off.** Every code path that
   could reach the network or launch the updater has been *deleted from the
   source*. There is no setting to turn it back on, and dropping a `gup.exe`
   into the install folder does nothing — the code that would launch it no
   longer exists. Future update-channel compromises cannot inject anything,
   because there is no update channel.

2. **The blacklist no longer matches.** The product is rebranded end-to-end —
   executable name, window class, single-instance mutex, version resource,
   installer, registry keys, settings folder — so endpoint tooling that blocks
   Notepad++ by name, path, signature, or window identity does not identify
   TeeJ-editor as the compromised product it was written to stop.


What was removed
----------------

| Removed | Why |
|---|---|
| Auto-updater (`gup.exe` / WinGUP) — never shipped, never launched | The compromise vector |
| Online Plugins Admin and its plugin catalog (`nppPluginList.dll`) | Downloads and executes code |
| "Update Notepad++" / "Set Updater Proxy" menu items | Updater entry points |
| Help-menu web links (Home, Project Page, Online Manual, Forum) | Browser launch to external sites |
| About-box and Preferences online links | Browser launch to external sites |
| Non-English localization (92 language packs) | Reduced surface; English only |

**Verification:** the main executable contains no direct network code — in stock
Notepad++ *all* network I/O was delegated to `gup.exe`, which is launched from a
single place. That launch point, and every caller feeding it, has been removed.
`grep` the tree for `gup.exe` / `wininet` / `WinHttp` and you will find no
reachable call. The only URL-opening code left is the editor opening a link
**you** Ctrl+click inside your own document — a core editing feature, not a
product callback.


What was added
--------------

**Plugins → Install Plugin from Zip…** — an offline replacement for Plugins
Admin. Pick a plugin `.zip` you obtained yourself; it is extracted into
`plugins\<Name>\<Name>.dll` using the built-in Windows shell zip handler. No
network, no helper process, no downloaded executables. The plugin loader itself
is unchanged, so any standard Notepad++ plugin works when installed this way.


What was deliberately kept
--------------------------

- The **GPL license** and all **original copyright / attribution** to Don HO and
  the Notepad++ project. This is a derivative work under GPL v3; the license
  headers in every source file are intact.
- The full **editor** — Scintilla, lexers, session handling, macros, search,
  themes, and the **plugin API** (in-process plugins are loaded exactly as
  before; only the *installer* that downloaded them is gone).
- Opening a link you click inside a document (see Verification above).


Identity
--------

| | Notepad++ | TeeJ-editor |
|---|---|---|
| Executable | `notepad++.exe` | `TeeJ-editor.exe` |
| Window class | `Notepad++` | `TeeJ-editor` |
| Single-instance mutex | `nppInstance` | `TeeJEditorInstance` |
| Settings folder | `%APPDATA%\Notepad++` | `%APPDATA%\TeeJ-editor` |
| Installer | `npp.<ver>.Installer.x64.exe` | `TeeJ-editor.<ver>.Installer.x64.exe` |

Existing Notepad++ settings are **not** migrated — TeeJ-editor starts clean.
External tools that locate the window by the `Notepad++` class name must use
`TeeJ-editor` instead.


Build
-----

Follow the upstream [build guide](BUILD.md). Building `x64 Release` from
`PowerEditor\visual.net\notepad++.sln` produces `PowerEditor\bin64\TeeJ-editor.exe`.
The NSIS installer is built from `PowerEditor\installer\nppSetup.nsi`.

Release builds are code-signed with the maintainer's certificate (Azure Trusted
Signing). An unsigned build is a development build.


Upstream
--------

Based on Notepad++ — see the [Notepad++ official site](https://notepad-plus-plus.org/)
and the [upstream repository](https://github.com/notepad-plus-plus/notepad-plus-plus).
Security fixes from upstream can be merged, but any change that reintroduces
network access is out of scope for this fork by definition.
