#!/bin/bash
mkdir -p builds
rm -rf dist
mkdir dist

cp -r src work

moonc work/**.moon
rm work/assets/maps/*.tmx work/assets/graphics/*.psd
rm work/**.moon
for file in $(find work -iname "*.lua") ; do
    luajit -b ${file} ${file}
done

name=$1
ver=$2

rm "${name}-${ver}.love"
rm "${name}-${ver}.zip"

rm "builds/${name}-win32-${ver}.zip"
rm "builds/${name}-win64-${ver}.zip"

n32="dist/${name}-win32-${ver}"
n64="dist/${name}-win64-${ver}"
mac="dist/${name}-${ver}.app"

cp -r bin/win32 "${n32}"
cp -r bin/win64 "${n64}"
#cp -r bin/love.app "${mac}"

cd work
zip -r "../${name}-${ver}.love" *
cd ..
rm -rf work

cat "${n32}/love.exe" "${name}-${ver}.love" > "${n32}/$name.exe"
cat "${n64}/love.exe" "${name}-${ver}.love" > "${n64}/$name.exe"
#cp "${name}-${ver}.love" "${mac}/Contents/Resources/game.love"

cp work/LICENSE* "${n32}"
cp work/LICENSE* "${n64}"

rm "${n32}/love.exe" "${n64}/love.exe"

cd "${n32}"
zip -r "../../builds/${name}-win32-${ver}.zip" *
cd "../../${n64}"
zip -r "../../builds/${name}-win64-${ver}.zip" *
cd ../..
rm -rf dist

mv "${name}-${ver}.love" builds/
