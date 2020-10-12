# nix-react-native

This is set of nix library functions to give you tools to develop and build `react-native` projects.

## Why

- `nix` provides clear way to do multilanguage project dependency management
- want to build android project with isolated environment (which `nix` provides)
- need to use mixed tools (yarn/gradle) with offline sandboxing

## How to do offline react-natvie build for android

https://gist.github.com/erikyuntantyo/d5ca92b19cb06aedb61c89324f6abc27

```
 mkdir android/app/src/main/assets
 react-native bundle --platform android --dev false --entry-file index.js --bundle-output android/app/src/main/assets/index.android.bundle --assets-dest android/app/src/main/res/
 cd android
 ./gradlew assembleDebug
 ./gradlew assembleRelease
```

# How to use it

## To Bootstrap `react-native` Project From Scratch

What: you have empty directory and you want to create fresh `react-native` project

- you can run `react-native init`

or

- create `env.nix` with versions set (this provides shell with required tools)
- `nix-shell env.nix -A bootstrap-shell` (that enters the minimal bootstrap shell)
- `yarn add react-native@0.62` (or whatever version you choose, latest tested is 0.62)
- `./node_modules/.bin/react-native init exampleproject`
- `react-native init` does create new folder and new `package.json` inside, it does not use one you have already, so we need to
  shift all project to use `exampleproject` folder now. 
- remove `node_modules` from root
- remove `package.json` and `yarn.lock` (everything except `env.nix` and `exampleproject`)

## To nixify `react-native`

What: You can have new bootstrapped (using method above) project or existing one and you want to build it with nix.

- you have `exampleproject` with `react-native` project inside and `env.nix` in root folder
- make sure versions are set correctly for your project
  - get versions from changelog https://github.com/react-native-community/releases/blob/master/CHANGELOG.md
  - make sure `env.nix` gradle version you use is the same as `android/gradle/wrapper/gradle-wrapper.properties`.
  - make sure `android/build.gradle` has correct gradle-download-task (com.android.tools.build:gradle:4.0.1)

## To Update/Rebuild Nix Dependency Tree When You Modify Project Dependencies

- enter shell
- cd android
- nix-react-native-android-gradle-generate-dependencies .  # this generates json file (you need to restart shell to catch new changes)

## To Continue Development of `react-native` Project

- enter shell (`make shell`)
- run emulator (`make emulator`)
- `react-native start` and `react-native run-android`

## To Release `react-native` Project



## thanks to status-react

This projects is based on great work from https://github.com/status-im/status-react/
