[Setup]
AppName=Swell
AppVersion=1.0.0
Uninstallable=no
DefaultDirName={commoncf}\VST3
LicenseFile=license.txt
OutputDir=.
OutputBaseFilename=Swell Installer 1.0.0
Compression=lzma
SolidCompression=yes

[Files]
; Install the VST3 plugin to the official VST3 folder
Source: "build\Swell.vst3"; DestDir: "{commoncf}\VST3"; Flags: ignoreversion