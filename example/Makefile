.PHONY: build

bootstrap-shell:
	nix-shell --pure ./env.nix -A provides.packages.bootstrap-shell -j1

shell:
	@mkdir -p build
	@export BUILD_PATH=$$(readlink -f build) && \
		cd ./exampleproject/ && nix-shell --keep BUILD_PATH --pure ./../env.nix -A provides.packages.shell -j1

build:
	@nix build -L -f ./env.nix provides.packages.mobile-app-android -j1

emulator:
	@mkdir -p build/emulator

	@export BUILD_PATH=$$(readlink -f build) && \
		export EMULATOR_STATE_PATH=$$(readlink -f build/emulator-android) && \
		cd ./exampleproject/ && \
		nix-shell \
			--keep BUILD_PATH \
			--keep EMULATOR_STATE_PATH \
			--pure ./../env.nix \
			-A provides.packages.shell -j1 \
			--run "nix-react-native-android-emulator"
