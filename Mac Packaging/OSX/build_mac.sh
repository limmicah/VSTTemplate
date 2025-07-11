#!/bin/bash

# MACOS BUILD SCRIPT
version=1.0.3
buildStandalone=0
buildPlugin=1
buildInstaller=1
codesignStandalone=0
codesignPlugin=1
notarize=1

hiseSource="/Users/micahlim/HISE"
projectName="Granola"
projectFolder="/Users/micahlim/Documents/HISE Projects/Granola"
xmlFile="Granola"
teamId="Stephanie Lim (W8G565M7XQ)"
appleId="syulim@gmail.com"
appSpecificPassword="rppg-mygm-epie-ekat"

bundleId='com.'${projectName// /}'.pkg'
hisePath=$hiseSource"/projects/standalone/Builds/MacOSX/build/Release/HISE.app/Contents/MacOS/HISE"
projuectPath=$hiseSource"/tools/projucer/Projucer.app/Contents/MacOS/Projucer"
whiteboxPackages="/usr/local/bin/packagesbuild"

#Create packaging directory for packaging
packaging="$projectFolder/Packaging/OSX"
mkdir -p "$packaging"

mkdir -p "$projectFolder/Binaries"
cd "$projectFolder/Binaries" || exit

# STEP 1: BUILDING THE BINARIES
# ====================================================================
"$hisePath" set_project_folder -p:$projectFolder
"$hisePath" set_version -v:$version

echo Making the Projucer accessible for this project
chmod +x "$projuectPath"

if (($buildStandalone==1))
then
  echo Building the standalone app
  "$hisePath" clean -p:$projectFolder --all
  "$hisePath" export_ci XmlPresetBackups/$xmlFile.xml -t:standalone -a:x64
  chmod +x ./batchCompileOSX
  sh ./batchCompileOSX
  cp -R "./Compiled/$projectName.app" "$packaging/$projectName.app"
fi

if (($buildPlugin==1))
then
  echo Building the plugins
  "$hisePath" clean -p:$projectFolder --all
  "$hisePath" export_ci XmlPresetBackups/$xmlFile.xml -t:effect -p:VST_AU -a:x64
  chmod +x "./batchCompileOSX"
  sh "./batchCompileOSX"
  cp -R "./Builds/MacOSX/build/Release/$projectName.vst3" "$packaging/$projectName.vst3"
  cp -R "./Builds/MacOSX/build/Release/$projectName.component" "$packaging/$projectName.component"
fi

echo Codesigning

if [[ $codesignStandalone = 1 ]]
then
  codesign --remove-signature "$packaging/$projectName.app"
  codesign --deep --force --options runtime --sign "Developer ID Application: $teamId" "$packaging/$projectName.app"
fi

if [[ $codesignPlugin = 1 ]]
then
  codesign --remove-signature "$packaging/$projectName.vst3"
  codesign --remove-signature "$packaging/$projectName.component"
  codesign -s "Developer ID Application: $teamId" "$packaging/$projectName.vst3" --timestamp
  codesign -s "Developer ID Application: $teamId" "$packaging/$projectName.component" --timestamp
fi

# STEP 2: BUILDING INSTALLER
# ====================================================================

if (($buildInstaller==1))
then
  echo "Build Installer"

  $whiteboxPackages "$packaging/$projectName.pkgproj"

  productsign --sign "Developer ID Installer: $teamId" "$packaging/build/$projectName.pkg" "$packaging/build/$projectName""_signed.pkg"

  cp -R "$packaging/build/$projectName""_signed.pkg" "$packaging/$projectName Installer $version.pkg"

  echo "Cleanup"
  rm -rf "$packaging/build"

  if (($notarize==1))  # <- Missing 'then' fixed here
  then
    echo "Notarizing with notarytool..."

    pkgPath="$packaging/$projectName Installer $version.pkg"

    # Submit for notarization and wait for it to complete
    xcrun notarytool submit "$pkgPath" \
      --apple-id "syulim@gmail.com" \
      --password "rppg-mygm-epie-ekat" \
      --team-id "W8G565M7XQ" \
      --wait

    echo "Stapling..."
    xcrun stapler staple "$pkgPath"
  fi  # <- Ensure this 'fi' is here to close the 'if'
fi  # <- This 'fi' closes the build installer step
