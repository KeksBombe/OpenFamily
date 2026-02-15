{
  description = "Go (Swagger) backend + Flutter frontend + Android emulator dev shell";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config = {
            android_sdk.accept_license = true;
            allowUnfree = true;
          };
        };

        androidSdk = pkgs.androidenv.composeAndroidPackages {
          toolsVersion = "26.1.1";
          platformToolsVersion = "35.0.2";
          emulatorVersion = "35.1.19";
          platformVersions = [ "36" "35" ];
          buildToolsVersions = [ "28.0.3" "35.0.0" ];


          includeEmulator = true;
          includeSystemImages = true;
          systemImageTypes = [ "google_apis" ];
          abiVersions = [ "x86_64" ];
          includeNDK = false;
          includeExtras = [
            "extras;google;gcm"
            "extras;google;m2repository"
            "extras;android;m2repository"
          ];
        };

        sdk = androidSdk.androidsdk;
      in
      {
        devShells.default = pkgs.mkShell {
          name = "go-swagger-flutter-android";

          packages = with pkgs; [
            gnumake
            go
            gopls
            delve
            golangci-lint
            swagger-codegen
            openapi-generator-cli
            flutter
            dart
            sdk
            jdk17
            git
            unzip
            zip
            curl
            which
            file
            chromium

          ];
          ANDROID_HOME = "${sdk}/libexec/android-sdk";
          ANDROID_SDK_ROOT = "${sdk}/libexec/android-sdk";
          JAVA_HOME = "${pkgs.jdk17}/lib/openjdk";

          shellHook = ''
            SDK_STORE="${sdk}/libexec/android-sdk"

            export ANDROID_HOME="$HOME/.android-sdk"
            export ANDROID_SDK_ROOT="$ANDROID_HOME"
            export JAVA_HOME="${pkgs.jdk17}/lib/openjdk"
            export CHROME_EXECUTABLE="${pkgs.chromium}/bin/chromium"

            export ANDROID_HOME="$HOME/.android-sdk"
            export ANDROID_SDK_ROOT="$ANDROID_HOME"
            export PATH="$ANDROID_HOME/platform-tools:$ANDROID_HOME/emulator:$ANDROID_HOME/cmdline-tools/latest/bin:$PATH"


            mkdir -p "$ANDROID_HOME"
            mkdir -p "$ANDROID_HOME/licenses"

            for d in platform-tools emulator cmdline-tools build-tools platforms system-images; do
              if [ -e "$SDK_STORE/$d" ] && [ ! -e "$ANDROID_HOME/$d" ]; then
                ln -s "$SDK_STORE/$d" "$ANDROID_HOME/$d"
              fi
            done

            export PATH="$ANDROID_HOME/platform-tools:$ANDROID_HOME/emulator:$ANDROID_HOME/cmdline-tools/latest/bin:$PATH"
          '';
        };
      }
    );
}
