# taken from https://github.com/status-im/status-react/

# This is the Android Asset Packaging Tool(AAPT2).
# It is used by Gradle to package Android app resources.
# See: https://developer.android.com/studio/command-line/aapt2

{ lib, stdenv, pkgs, fetchurl }:
let
  repoUrl = "https://dl.google.com/dl/android/maven2";
  pkgPath = "com/android/tools/build/aapt2";
in
{version? "3.5.3-5435860",
platform?"linux",
pom-sha ? "1kdjfmrd4h2qljsdlqmyskin0564csg0q8j7bynag17w511bn4d3",
src-pom? fetchurl {
      url = "${repoUrl}/${pkgPath}/${version}/aapt2-${version}.pom";
      sha256 = pom-sha;
    },
jar-sha ? "05gln93wfj4l5b0zfn6ipkx0i9p0x928ygwkrcfyl58aslxg5gx2",
src-jar? fetchurl {
      url = "${repoUrl}/${pkgPath}/${version}/aapt2-${version}-${platform}.jar";
      sha256 = jar-sha;
    },
sha-sha?"0rr7ly0f3w5jw0q985hmxmv8q2nlw1k72n6kl7kcmj4a7i479q90",
    src-sha? fetchurl {
      url = "${repoUrl}/${pkgPath}/${version}/aapt2-${version}-${platform}.jar.sha1";
      sha256 = sha-sha;
    },
  }:

let
  inherit (lib) getAttr optionals;
  inherit (pkgs) zip unzip patchelf;
  inherit (stdenv) isLinux;

  pname = "aapt2";


in stdenv.mkDerivation {
  inherit pname version;

  srcs = [ src-jar src-sha src-pom ];
  phases = [ "unpackPhase" ]
    ++ optionals isLinux [ "patchPhase" ]; # OSX binaries don't need patchelf
  buildInputs = [ zip unzip patchelf ];

  unpackPhase = ''
    mkdir -p $out
    for src in $srcs; do
      filename=$(stripHash $src)
      cp $src $out/$filename
    done
  '';

  # On Linux, we need to patch the interpreter in Java packages
  # that contain native executables to use Nix's interpreter instead.
  patchPhase = ''
    # We need an stdenv with a compiler
    [[ -n "$NIX_CC" ]] || exit 1

    # Patch executables from maven dependency to use Nix's interpreter
    tmpDir=$(mktemp -d)
    jarName="aapt2-${version}-${platform}.jar"
    ${unzip}/bin/unzip $out/$jarName -d $tmpDir
    for exe in `find $tmpDir/ -type f -executable`; do
      ${patchelf}/bin/patchelf --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" $exe
    done

    # Rebuild the .jar file with patched binaries
    pushd $tmpDir > /dev/null
    chmod u+w $out/$jarName
    ${zip}/bin/zip -fr $out/$jarName
    chmod $out/$jarName --reference=$out/$jarName.sha1
    popd > /dev/null
    rm -rf $tmpDir
  '';
}
