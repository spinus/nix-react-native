{pkgs?import ./../../../nixpkgs/nixpkgs-unstable.nix {}}:
rec {
  bootstrap-shell = nix-react-native.provides.packages.bootstrap-shell;

  nix-react-native = import ../flake.nix {inherit pkgs;};

  composeAndroidPackages = import "${pkgs.path}/pkgs/development/mobile/androidenv/compose-android-packages.nix" {
      inherit (pkgs) requireFile autoPatchelfHook;
      licenseAccepted = true;
      pkgs = pkgs;
      pkgs_i686 = import pkgs.path { system = "i686-linux"; };
    };
    android-sdk-args = {
      toolsVersion = "26.1.1";
      platformToolsVersion = "29.0.6";
      buildToolsVersions = [ "28.0.3" ];
      includeEmulator = true;
      emulatorVersion = "30.0.3";
      platformVersions = ["28"];
      includeSources = false;
      includeDocs = false;
      includeSystemImages = true;
      systemImageTypes = [ "default" ];
      abiVersions = [ 
        "x86_64"
        ];
      lldbVersions = [  ];
      cmakeVersions = [ ];
      includeNDK = true;
      ndkVersion = "18.1.5063045";
      useGoogleAPIs = true;
      useGoogleTVAddOns = false;
      # includeExtras = ["extras;android;m2repository" "extras;google;m2repository"];
    };

    provides.packages = nix-react-native.provides.packages // nix-react-native.provides.parametrized-packages {
      android-composition = composeAndroidPackages android-sdk-args;
      android-emulator-platform ="28"; 
      android-emulator-abi = "x86_64";
      android-emulator-system-image-type ="default";
      yarn-modules = nix-react-native.provides.packages.yarn2nix.mkYarnModules {
        name="my-node-modules";
        pname="my-node-modules";
        version="0";
        packageJSON = ./exampleproject/package.json;
        yarnLock = ./exampleproject/yarn.lock;
      };
      custom-gradle = nix-react-native.provides.packages.gradle601;
      custom-java = pkgs.openjdk8;
      custom-nodejs = pkgs.nodejs-14_x;
      react-native-project-path = ./exampleproject;
      custom-aapt2=nix-react-native.provides.packages.aapt2-template {
          version="3.6.3-6040484";
          jar-sha="06wnrz7c3knvndbxc1cmylq3v00wzlrf0hg8k9plriy2fnzcsbqy";
          sha-sha="157pwsrrsqndppp6mpgfrwzciqvdkhdd07xy4kdxdk50cwp15wgl";
          pom-sha="0l9xgn7r9f5kr9gmk2mgm4vywfv83vldaiyfvfpq4wv76nf7svnc";
        };
      gradle-dependencies-attrs = pkgs.lib.importJSON ./exampleproject/android/nix-react-native-gradle-dependencies.generated.json;
    };
}
