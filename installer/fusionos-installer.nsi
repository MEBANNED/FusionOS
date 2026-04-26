; ===========================================================================
; FusionOS — Windows Installer Wrapper (NSIS Script)
; ===========================================================================
; This NSIS script creates a Windows .exe that:
;   1. Installs VirtualBox (portable or asks user to install)
;   2. Copies the FusionOS .iso to the user's machine
;   3. Creates a pre-configured VirtualBox VM
;   4. Launches the VM
;
; Compile with:  makensis fusionos-installer.nsi
; Requires:      NSIS 3.x (https://nsis.sourceforge.io)
; ===========================================================================

!include "MUI2.nsh"
!include "FileFunc.nsh"

; ── Metadata ──────────────────────────────────────────────────────────────
Name "FusionOS Installer"
OutFile "FusionOS-Setup.exe"
InstallDir "$PROGRAMFILES\FusionOS"
RequestExecutionLevel admin

; ── UI ────────────────────────────────────────────────────────────────────
!define MUI_ICON "assets\fusionos-icon.ico"
!define MUI_WELCOMEPAGE_TITLE "Welcome to FusionOS"
!define MUI_WELCOMEPAGE_TEXT "This wizard will set up a FusionOS virtual machine on your Windows PC.$\r$\n$\r$\nYou will need VirtualBox installed. If it is not present, we will guide you through the installation."

!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH

!insertmacro MUI_LANGUAGE "English"

; ── Installation ──────────────────────────────────────────────────────────
Section "Install"
    SetOutPath "$INSTDIR"

    ; Copy the ISO
    File "fusionos-1.0-amd64.iso"

    ; Write a helper batch script that creates and boots the VM
    FileOpen $0 "$INSTDIR\launch-fusionos.bat" w
    FileWrite $0 '@echo off$\r$\n'
    FileWrite $0 'echo =============================================$\r$\n'
    FileWrite $0 'echo   FusionOS — Creating Virtual Machine$\r$\n'
    FileWrite $0 'echo =============================================$\r$\n'
    FileWrite $0 '$\r$\n'
    FileWrite $0 'set VBOX="C:\Program Files\Oracle\VirtualBox\VBoxManage.exe"$\r$\n'
    FileWrite $0 '$\r$\n'
    FileWrite $0 'REM Create VM$\r$\n'
    FileWrite $0 '%VBOX% createvm --name "FusionOS" --ostype Debian_64 --register$\r$\n'
    FileWrite $0 '$\r$\n'
    FileWrite $0 'REM Configure hardware$\r$\n'
    FileWrite $0 '%VBOX% modifyvm "FusionOS" --memory 4096 --cpus 2 --vram 128$\r$\n'
    FileWrite $0 '%VBOX% modifyvm "FusionOS" --graphicscontroller vmsvga$\r$\n'
    FileWrite $0 '%VBOX% modifyvm "FusionOS" --nic1 nat$\r$\n'
    FileWrite $0 '%VBOX% modifyvm "FusionOS" --audio-driver dsound --audio-out on$\r$\n'
    FileWrite $0 '%VBOX% modifyvm "FusionOS" --boot1 dvd --boot2 disk$\r$\n'
    FileWrite $0 '%VBOX% modifyvm "FusionOS" --firmware efi$\r$\n'
    FileWrite $0 '$\r$\n'
    FileWrite $0 'REM Create virtual disk$\r$\n'
    FileWrite $0 '%VBOX% createmedium disk --filename "%USERPROFILE%\VirtualBox VMs\FusionOS\FusionOS.vdi" --size 40960 --format VDI$\r$\n'
    FileWrite $0 '$\r$\n'
    FileWrite $0 'REM Attach storage$\r$\n'
    FileWrite $0 '%VBOX% storagectl "FusionOS" --name "SATA" --add sata --controller IntelAhci$\r$\n'
    FileWrite $0 '%VBOX% storageattach "FusionOS" --storagectl "SATA" --port 0 --device 0 --type hdd --medium "%USERPROFILE%\VirtualBox VMs\FusionOS\FusionOS.vdi"$\r$\n'
    FileWrite $0 '%VBOX% storageattach "FusionOS" --storagectl "SATA" --port 1 --device 0 --type dvddrive --medium "$INSTDIR\fusionos-1.0-amd64.iso"$\r$\n'
    FileWrite $0 '$\r$\n'
    FileWrite $0 'REM Start VM$\r$\n'
    FileWrite $0 '%VBOX% startvm "FusionOS"$\r$\n'
    FileWrite $0 '$\r$\n'
    FileWrite $0 'echo =============================================$\r$\n'
    FileWrite $0 'echo   FusionOS VM is running!$\r$\n'
    FileWrite $0 'echo =============================================$\r$\n'
    FileClose $0

    ; Create Start Menu shortcut
    CreateDirectory "$SMPROGRAMS\FusionOS"
    CreateShortcut "$SMPROGRAMS\FusionOS\Launch FusionOS.lnk" "$INSTDIR\launch-fusionos.bat"
    CreateShortcut "$DESKTOP\FusionOS.lnk" "$INSTDIR\launch-fusionos.bat"

SectionEnd

; ── Uninstaller ───────────────────────────────────────────────────────────
Section "Uninstall"
    Delete "$INSTDIR\fusionos-1.0-amd64.iso"
    Delete "$INSTDIR\launch-fusionos.bat"
    RMDir "$INSTDIR"
    Delete "$SMPROGRAMS\FusionOS\Launch FusionOS.lnk"
    RMDir "$SMPROGRAMS\FusionOS"
    Delete "$DESKTOP\FusionOS.lnk"
SectionEnd
