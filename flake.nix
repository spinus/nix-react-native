{pkgs?import <nixpkgs> {}}: {
  name="nix-react-native";
  epoch=2020;
  description="tools to support react-native development and building under nix";
  requires= [ flake:nixpkgs ];
  provides = rec {
    packages = rec {
      yarn = pkgs.yarn;
      gradle2nix = import (fetchTarball {
        url="https://github.com/tadfisher/gradle2nix/archive/c3c40795660f0c523dbfc65e2d74bdaceb6a2849.tar.gz";
        sha256="04skv5nhbqzybxsqp7b7l4s7nl66p8cd92f6czlivwcjnj36lzya";
      }) {inherit pkgs;};
      yarn2nix = import (fetchTarball {
        url="https://github.com/moretea/yarn2nix/archive/9e7279edde2a4e0f5ec04c53f5cd64440a27a1ae.tar.gz";
        sha256="0zz2lrwn3y3rb8gzaiwxgz02dvy3s552zc70zvfqc0zh5dhydgn7";
      }) {inherit pkgs;};
      gradle62 = pkgs.callPackage ({ gradleGen, fetchurl }:gradleGen.gradleGen rec {
        name = "gradle-6.2";
        nativeVersion = "0.21";

        src = fetchurl {
          url = "https://services.gradle.org/distributions/${name}-bin.zip";
          sha256 = "12ng4f75b0rc25j1i3bb10j9rma2iff043r43qhfr58is0q5yfmr";
        };
      }) {};
      gradle601 = pkgs.callPackage ({ gradleGen, fetchurl }:gradleGen.gradleGen rec {
        name = "gradle-6.0.1";
        nativeVersion = "0.18";

        src = fetchurl {
          url = "https://services.gradle.org/distributions/${name}-bin.zip";
          sha256 = "0i5sxwhjnxp62s9k7vaqmi9i76d1285dq0rnk9bmhblzic4vfr6k";
        };
      }) {};
      gradle551 = pkgs.callPackage ({ gradleGen, fetchurl }:gradleGen.gradleGen rec {
        name = "gradle-5.5.1";
        nativeVersion = "0.17";

        src = fetchurl {
          url = "https://services.gradle.org/distributions/${name}-bin.zip";
          sha256 = "006d42s71ywrd0wkmqprfdzagm7bg2gm9sbwfs8kdbzwyby06ai2";
        };
      }) {};
      gradle511 = pkgs.callPackage ({ gradleGen, fetchurl }: gradleGen.gradleGen rec {
        name = "gradle-5.1.1";
        nativeVersion = "0.14";

        src = fetchurl {
          url = "https://services.gradle.org/distributions/${name}-bin.zip";
          sha256 = "16671jp5wdr3q6p91h6szkgcxg3mw9wpgp6hjygbimy50lv34ls9";
        };
      }) {};
      aapt2-template = pkgs.callPackage ./aapt2.nix {};
      aapt2 = aapt2-template {};
      bootstrap-shell = pkgs.mkShell {
        name = "bootstrapShell";
        buildInputs = with pkgs;[which yarn];
        buildPhase="true";
        shellHook = ''
          echo "==== START REACT-NATIVE BOOTSTRAP SHELL ===="
          echo "Use this shell only to bootstrap 'react-native' app with yarn/npm"
          echo
          echo "1. Make sure you have 'package.json' with proper react-native and react versions"
          echo "2. Run 'yarn' to generate 'yarn.lock' file"
          echo "3. Exit bootstrap shell and enter dev shell"
        '';
      };
    };
    parametrized-packages = {
      android-composition,  # created with (import "${pkgs.path}/pkgs/development/mobile/androidenv/compose-android-packages.nix")
      android-emulator-platform ? abort "Please provide nix-react-native parametrized-packages { android-emulator-platform = X } argument",
      android-emulator-abi ? abort "Please provide nix-react-native parametrized-packages { android-emulator-abi = X } argument",
      android-emulator-system-image-type ? abort "Please provide nix-react-native parametrized-packages { android-emulator-system-image-type = X } argument",
      yarn-modules,  # generate that with yarn2nix
 
      custom-gradle,
      custom-java,
      custom-nodejs,
      react-native-project-path,  # string with a path (not the nix path)
      gradle-dependencies-attrs,  # load this with importJSON
      custom-aapt2,
    }: with pkgs; with pkgs.lib; rec {
      gradle-dependencies-repository = pkgs.callPackage (import ./gradle-dependencies.nix {aapt2=custom-aapt2; gradle-dependencies-attrs= gradle-dependencies-attrs;}) {};
      env = pkgs.symlinkJoin {
        name="dealomat-mobile-build-env";
        preferLocalBuild=true;
        paths = with pkgs; [
          bash
          gnused
          # gradle2nix
          coreutils
          findutils
          bash
          unzip
          file
          gnumake
          custom-nodejs
          custom-gradle
          nix-react-native-env
          yarn
          lsof  # start-react-native
          yarn  # to manage node packages
          nodejs-12_x  # to run node packages (react native cli)
          custom-java # for test framework (espresso)
          nix-react-native-tools
          nix
          go-maven-resolver
          parallel
          curl
          cacert
        ];
      };
    mobile-app-android = stdenv.mkDerivation {
      name = "mobile-app-android";
      src = react-native-project-path;
      buildInputs = [env pkgs.gnused];
      preferLocalBuild=true;
      buildPhase = ''
        export BUILD_PATH=$(readlink -f .)
        source nix-react-native-env
        sed -i 's/gradlePluginPortal()/mavenLocal()/g' android/settings.gradle
        sed -i 's/google()/mavenLocal()/g' android/build.gradle
        sed -i 's/jcenter()/mavenLocal()/g' android/build.gradle
        sed -i 's/google()/mavenLocal()/g' android/build.gradle
        cd android
        gradle -version
        gradle \
          --offline \
          --stacktrace\
          -Dmaven.repo.local="${gradle-dependencies-repository}" \
          assembleRelease
        '';
    };
    shell = pkgs.mkShell {
#      inputsFrom = with pkgs; [
#        mobile-app-android
#      ];
      buildInputs = with pkgs;[
        env
      ];
      buildPhase="true";
      shellHook = ''
        set -eu
        echo "==== START NIX REACT-NATIVE DEVELOPMENT SHELL ===="
        echo
        echo "Running nix-react-native environment setup script..."
        source nix-react-native-env
        set +eu
      '';
    };
    nix-react-native-tools = pkgs.stdenv.mkDerivation {
      name="nix-react-native-tools";
      src = ./src;
      buildPhase = ''
        mkdir -p $out/bin
      '';
      buildInputs = with pkgs;  [
        makeWrapper
        # bash curl flock git custom-gradle jq maven custom-nodejs yarn
      ];
      installPhase = with pkgs.lib; ''
          cp nix* $out/bin/
          cp *awk $out/bin/
          wrapProgram $out/bin/nix-react-native-android-gradle-generate-dependencies-file --prefix PATH : ${makeBinPath [go-maven-resolver bash curl flock gnused gnugrep coreutils parallel jq]}
          wrapProgram $out/bin/nix-react-native-android-gradle-url2json --prefix PATH : ${makeBinPath [go-maven-resolver bash curl flock gnused gnugrep coreutils nix cacert]}
          wrapProgram $out/bin/nix-react-native-android-emulator \
            --prefix PATH : ${makeBinPath [netcat custom-java bash curl flock gnused gnugrep coreutils procps]} \
            --set NIX_ANDROID_EMULATOR_PLATFORM_VERSION ${android-emulator-platform} \
            --set NIX_ANDROID_EMULATOR_SYSTEM_IMAGE_TYPE ${android-emulator-system-image-type} \
            --set NIX_ANDROID_EMULATOR_ABI_VERSION ${android-emulator-abi} \
            --set JAVA_HOME ${custom-java} \
            --set ANDROID_SDK_ROOT ${android-composition.androidsdk}/libexec/android-sdk
      '';
    };
    go-maven-resolver = pkgs.callPackage ./go-maven-resolver {};
    nix-react-native-env = pkgs.writeScriptBin "nix-react-native-env" ''
          #!${pkgs.bash}/bin/bash
          set -eu
          if [[ ! -d ''${BUILD_PATH} ]];then
            echo "ERROR: Please provide BUILD_PATH and make sure it exists and is not used by other programs, as it is required to store some build files for nix-react-native builds."
            exit 1
          fi
          if [[ ''${BUILD_PATH:0:1} != / ]];then
            echo "ERROR: BUILD_PATH='$BUILD_PATH' must be absolute path! Please use absolute path."
            exit 2
          fi
          if [[ ! -f package.json ]] || [[ ! -d android ]] || [[ ! -f index.js ]] || [[ ! -f android/gradlew ]] || [[ ! -f android/gradle.properties ]] || [[ ! -d ios ]];then
            echo "ERROR: you must run that script inside react-native project directory (where android and ios directories are)"
            exit 3
          fi

          export NIX_SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt
          export SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt

          export _REACT_NATIVE_PROJECT_PATH=$(readlink -f .)
          export _ANDROID_SDK_CHECKSUM=$(echo "${android-composition.androidsdk}" | sha256sum | cut -f1 -d' ')
          export _ANDROID_SDK_LOCAL_COPY="$BUILD_PATH/android-sdk-$_ANDROID_SDK_CHECKSUM"
          export _NODE_MODULES_CHECKSUM=$(echo "${yarn-modules}" | sha256sum | cut -f1 -d' ')
          export _NODE_MODULES_LOCAL_COPY="$BUILD_PATH/node_modules-$_NODE_MODULES_CHECKSUM"

          if [[ "''${COPY_ANDROID_SDK:-0}" -ne 0 ]];then
            export BUILD_PATH=$(pwd)/build/android-env/sdk
            if [[ -f "$BUILD_PATH/.copied-$_ANDROID_SDK_CHECKSUM" ]];then
              echo "SDK already in place: $BUILD_PATH"
            else
              echo "Copying SDK to writeable directory: $BUILD_PATH"
              chmod u+rwX "$BUILD_PATH" -R || true
              rm "$BUILD_PATH" -rf
              mkdir -p "$BUILD_PATH"
              cp -Lr --preserve=mode ${android-composition.androidsdk}/libexec/android-sdk/* "$BUILD_PATH/"
              chmod u+rwX -R "$BUILD_PATH" 
              touch "$BUILD_PATH/.copied-$ANDROID_SDK_CHECKSUM"
            fi
          else
            true
            # this is just a trick to not copy android sdk during this derivation build but only at runtime
            # echo "- not copying SDK to writeable directory"
            # do gradle need tihs variable??!?
            # export BUILD_PATH=${android-composition.androidsdk}/libexec/android-sdk
          fi

          if [[ -d "$_NODE_MODULES_LOCAL_COPY" ]];then
            echo "- node-modules already copied to $_NODE_MODULES_LOCAL_COPY"
          else
            echo "[i] unfortunatelly react-native modifies node_modules so we need to copy that to be outside of nix store and writeable"
            test -d "$_NODE_MODULES_LOCAL_COPY-tmp" && chmod ug+rwX -R "$_NODE_MODULES_LOCAL_COPY-tmp"
            rm -rf "$_NODE_MODULES_LOCAL_COPY-tmp"
            cp -Lr ${yarn-modules}/node_modules $_NODE_MODULES_LOCAL_COPY-tmp
            chmod ug+rwX -R "$_NODE_MODULES_LOCAL_COPY-tmp"
            mv $_NODE_MODULES_LOCAL_COPY-tmp $_NODE_MODULES_LOCAL_COPY
          fi

          ### looks like crazy javascript ecosystem didn't learn about symlinks yet
          ### ln -s $_NODE_MODULES_LOCAL_COPY "$_REACT_NATIVE_PROJECT_PATH/node_modules"  # hopefuly this line can be uncommented some day
          if [[ -f "$_REACT_NATIVE_PROJECT_PATH/node_modules/.done-$_NODE_MODULES_CHECKSUM" ]];then
            echo "[i] $_REACT_NATIVE_PROJECT_PATH/node_modules/.done-$_NODE_MODULES_CHECKSUM exists, not copying node_modules (cached)"
          else
            rm -rf "$_REACT_NATIVE_PROJECT_PATH/node_modules"
            cp -Llr "$_NODE_MODULES_LOCAL_COPY" "$_REACT_NATIVE_PROJECT_PATH/node_modules"
            touch "$_REACT_NATIVE_PROJECT_PATH/node_modules/.done-$_NODE_MODULES_CHECKSUM"
            echo "- link to node_modules created in $_REACT_NATIVE_PROJECT_PATH/node_modules"
          fi

          export JAVA_HOME=${custom-java}
          # ANDROID_HOME should not be used anymore! but old gradleplugin requires it
          # export ANDROID_HOME="$BUILD_PATH" #BAK
          export ANDROID_SDK_HOME="/tmp/android-sdk-home"
          # export ANDROID_SDK_ROOT="$BUILD_PATH" #BAK
          export ANDROID_SDK_ROOT="${android-composition.androidsdk}/libexec/android-sdk"
          # ANDROID_NDK for backward compatibility
          export ANDROID_NDK="${android-composition.androidsdk}/libexec/android-sdk/ndk-bundle"
          export ANDROID_NDK_ROOT="${android-composition.androidsdk}/libexec/android-sdk/ndk-bundle"
          export ANDROID_NDK_HOME="${android-composition.androidsdk}/libexec/android-sdk/ndk-bundle"
          export NODE_PATH=$_NODE_MODULES_LOCAL_COPY
          export PATH="$ANDROID_SDK_ROOT/bin:$ANDROID_SDK_ROOT/tools:$ANDROID_SDK_ROOT/tools/bin:$ANDROID_SDK_ROOT/platform-tools:$ANDROID_SDK_ROOT/build-tools/28.0.3:$NODE_PATH/.bin:$JAVA_HOME/bin:$PATH"
          # this is for gradle, don't ask me why that's the name in ./android/gradlew
          export GRADLE_OPTS="-Dmaven.repo.local=${gradle-dependencies-repository} -Dorg.gradle.offline=true -Doffline=true"
          export GRADLE_REPO_PATH="${gradle-dependencies-repository}"
          alias gradle="gradle $GRADLE_OPTS "


          (
            ls ${android-composition.androidsdk}/libexec/android-sdk/platform-tools/{adb,fastboot,hprof-conv,mke2fs}
            ls ${android-composition.androidsdk}/libexec/android-sdk/tools/{android,mksdcard}
            ls ${android-composition.androidsdk}/libexec/android-sdk/tools/bin/{avdmanager,sdkmanager,archquery,monkeyrunner}
            ls ${android-composition.androidsdk}/libexec/android-sdk/platform-tools/{mke2fs.conf,e2fsdroid,adb}
            ls ${android-composition.androidsdk}/libexec/android-sdk/build-tools/28.0.3/{aapt,dexdump,dx,zipalign,apksigner}
          ) > /dev/null
          # sdkmanager --licenses  # optional, let's see how we can grab licenses other way

          echo "- BUILD_PATH = $BUILD_PATH"
          env | egrep '^ANDROID|^NODE|^PATH|^JAVA'

          echo "- android-sdk: ${android-composition.androidsdk}/libexec/android-sdk"
          echo "- android-sdk checksum: $_ANDROID_SDK_CHECKSUM"
          echo "- android-sdk local: $_ANDROID_SDK_LOCAL_COPY"

          echo "- node-modules: ${yarn-modules}"
          echo "- node-modules checksum: $_NODE_MODULES_CHECKSUM"
          echo "- node-modules local: $_NODE_MODULES_LOCAL_COPY"

          echo "- gradle-dependencies-repository: ${gradle-dependencies-repository}"

    '';
  };
    };
}
