# Dragon Ball: Raging Blast 2 on Xbox Series X|S (Dev Mode)

This runs **Raging Blast 2 Recompiled**
([WistfulHopes/RB2](https://github.com/WistfulHopes/RB2)) on an Xbox Series X
or Series S in Developer Mode. Raging Blast 2 Recompiled is a native port of
the Xbox 360 game, made with the ReXGlue SDK. It is not an emulator.

This repository holds the Xbox (UWP) changes and scripts that build it and
send it to your Xbox from a Windows PC. Most of the work is automatic: you run
three scripts.

**What works:** the game is playable: menus, battles and saving. The B
button no longer closes the game, and the picture is upscaled with AMD FSR.

**Known problem:** ki blasts and some other effects are invisible.

**No game files are included.** You need your own copy of Dragon Ball: Raging
Blast 2 for Xbox 360, with its files extracted from the disc image (a folder
with `default.xex` in it).

---

## What you need

- An **Xbox Series X or S in Developer Mode**. See
  [Xbox Dev Mode activation](https://learn.microsoft.com/windows/uwp/xbox-apps/devkit-activation).
  It needs a Microsoft Partner Center developer account, which costs a
  one-time fee.
- A **Windows 10 or 11 PC** (64-bit), with about 40 GB free and the same
  network as the Xbox.
- Your **extracted Raging Blast 2 game files**. If you have a disc image
  (`.iso`), extract it with
  [extract-xiso](https://github.com/XboxDev/extract-xiso), for example by
  dragging the `.iso` onto `extract-xiso.exe`.

---

## Step 1: Set up the Xbox (once)

1. Turn on Dev Mode and restart into it. Open **Dev Home**.
2. In Dev Home, open **Remote Access Settings**:
   - turn on **Enable Xbox Device Portal**;
   - turn on **Require authentication**;
   - set a **user name** and **password**. You'll type these on the PC
     later.
3. Write down the Xbox's **IP address**, shown under Remote Access in
   Dev Home (for example `192.168.1.50`).

## Step 2: Download this repository (once)

1. On this page, click the green **Code** button, then **Download ZIP**.
2. Extract it to a short folder **with no spaces**, for example `C:\RB2UWP`.
   Make sure the scripts sit directly in that folder, not one level down.
3. Copy your extracted game files into the **`game`** folder inside it, so
   that `default.xex` is directly in `game` (for example
   `C:\RB2UWP\game\default.xex`).

## Step 3: Install the build tools (once)

Double-click **`install-tools.bat`**. It installs Git and Visual Studio 2022
Community with the C++, Clang and UWP tools. Say **yes** when Windows asks for
permission. Restart your PC when it's done.

<details>
<summary>Install them by hand instead</summary>

- [Git for Windows](https://git-scm.com/download/win).
- [Visual Studio 2022 Community](https://visualstudio.microsoft.com/vs/community/).
  In the Visual Studio Installer, choose **More → Import configuration** and
  pick the `.vsconfig` file from this folder. That selects the workloads
  **Desktop development with C++** and **Universal Windows Platform
  development**, plus **C++ (v143) Universal Windows Platform tools**,
  **C++ Clang Compiler for Windows** and **C++ CMake tools for Windows**.
</details>

## Step 4: Build (first time: an hour or more)

Double-click **`build-xbox.bat`**.

- It downloads the ReXGlue SDK and Raging Blast 2 Recompiled, applies the
  Xbox changes, turns the game's code into C++ and compiles it. Leave it running; the PC will be busy.
- When it says **DONE**, go to the next step.

If something fails, the window shows the last lines of `build-log.txt`. You
can run it again after fixing the problem: it continues where it stopped.

## Step 5: Send it to the Xbox and play

1. Make sure the Xbox is on, in Dev Mode, on Dev Home.
2. Double-click **`deploy-xbox.bat`**.
   - The first time, it asks for the Xbox's IP address and the Device Portal
     user name and password from Step 1. It remembers them in this folder,
     with the password encrypted for your Windows account.
   - It copies the app and your game files to the Xbox. The first time this
     takes a while; later runs only copy what changed.
   - **First time only:** it asks you to set the app type to **Game**. On the
     Xbox, in Dev Home, highlight **Raging Blast 2**, press the **Menu**
     button, choose **View details**, set **App type** to **Game**, then
     press Enter on the PC.
3. The game starts on the Xbox. After this, you can launch it from Dev Home
   like any other app.

Your saves stay on the Xbox when you run `deploy-xbox.bat` again.

---

## Updating

Download the new version of this repository and extract it over your folder.
Keep `rexglue-sdk`, `rb2`, `game` and `deploy-xbox.settings.xml`. Then run
`build-xbox.bat` and `deploy-xbox.bat` again. The build only redoes what changed.

## If something goes wrong

- **`get-xbox-log.bat`** downloads the game's log from the Xbox to
  `xbox-log.txt`. Run it **before** starting the game again, because every
  launch starts a new log.
- **`xbox-options.bat`** restarts the game with experimental graphics
  settings, for testing the invisible effects. Pick **0** to go back to
  normal.
- Please [open an issue](../../issues) and attach `build-log.txt` or
  `xbox-log.txt`.

## Known issues

- Ki blasts and some other effects are invisible.

---

## What's in here

| File | What it is |
|---|---|
| `install-tools.bat`, `.vsconfig` | Installs Git and Visual Studio with the needed parts |
| `build-xbox.bat` | Builds the Xbox app (logs to `build-log.txt`) |
| `deploy-xbox.bat`, `deploy-xbox.ps1` | Sends the app and game files to the Xbox and starts it (uses the Device Portal) |
| `get-xbox-log.bat`, `xbox-options.bat` | Log download and fixes, see above |
| `game\` | Put your extracted game files here |
| `rexglue-sdk-v0.1.2-xbox-uwp.patch` | Xbox (UWP) support for the ReXGlue SDK v0.1.2 |
| `rexglue-sdk-fix-*.patch` | Xbox fixes found while testing, applied in order |
| `rb2-xbox-uwp.patch`, `rb2-fix-*.patch` | Xbox changes for the RB2 project (WistfulHopes/RB2, downloaded by the build) |

### What the Xbox changes do

- **App:** run the ReXGlue runtime as a UWP app (CoreWindow,
  Windows.Gaming.Input, XAudio2, LocalState for saves and settings), with
  graphics through Direct3D 12.
- **Controls:** keep the B button from closing the game.
- **Picture:** upscale the output with AMD FSR.
- **Graphics driver workaround:** no tiled resources, which the Xbox driver
  mishandles.
- **Diagnostics:** logs for crashes and graphics problems.

## Credits

- **[Raging Blast 2 Recompiled](https://github.com/WistfulHopes/RB2):**
  WistfulHopes and contributors. This is their port; this repository only adds
  the Xbox version.
- **[ReXGlue SDK](https://github.com/rexglue/rexglue-sdk):** Tom Clay and
  contributors (BSD 3-Clause).
- **[Xenia](https://xenia.jp):** Ben Vanik and the Xenia contributors. The
  ReXGlue runtime is derived from it.
- **Xbox port:** DerrickTilleryWT.

Not affiliated with or endorsed by Bandai Namco, Spike, Toei Animation or
Microsoft. No game code or assets are included. Please support official
releases.
