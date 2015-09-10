#!/bin/bash

ELECTRON_VERSION=$(npm info electron-prebuilt version)
VERSION=$(node -e "console.log(require('./package').version)")
PLATFORMS=("darwin-x64" "linux-ia32" "linux-x64" "win32-ia32" "win32-x64")

cd dist
cd darwin-x64
mv Electron.app Yakyak.app
defaults write $(pwd)/Yakyak.app/Contents/Info.plist CFBundleDisplayName -string "Yakyak"
defaults write $(pwd)/Yakyak.app/Contents/Info.plist CFBundleExecutable -string "Yakyak"
defaults write $(pwd)/Yakyak.app/Contents/Info.plist CFBundleIdentifier -string "com.github.yakyak"
defaults write $(pwd)/Yakyak.app/Contents/Info.plist CFBundleName -string "Yakyak"
defaults write $(pwd)/Yakyak.app/Contents/Info.plist CFBundleVersion -string "$VERSION"
plutil -convert xml1 $(pwd)/Yakyak.app/Contents/Info.plist
mv Yakyak.app/Contents/MacOS/Electron Yakyak.app/Contents/MacOS/Yakyak
cp -R ../../app Yakyak.app/Contents/Resources/app
cp ../../src/icons/atom.icns Yakyak.app/Contents/Resources/atom.icns
zip -r ../yakyak-osx.app.zip Yakyak.app
cd ..

cd win32-ia32
mv electron.exe yakyak.exe
cp -R ../../app resources/app
cd ..
zip -r yakyak-win32-ia32.zip win32-ia32

cd win32-x64
mv electron.exe yakyak.exe
cp -R ../../app resources/app
cd ..
zip -r yakyak-win32-x64.zip win32-x64

cd linux-ia32
mv electron yakyak
cp -R ../../app resources/app
cd ..
zip -r yakyak-linux-ia32.zip linux-ia32

cd linux-x64
mv electron yakyak
cp -R ../../app resources/app
cd ..
zip -r yakyak-linux-x64.zip linux-x64

cd ..
