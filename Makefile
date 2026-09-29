# GREWordGroups — build/run/test from the command line (or VS Code tasks).
# Override the simulator with: make run SIM_NAME="iPhone 16 Pro"

PROJECT      := GREWordGroups.xcodeproj
SCHEME       := GREWordGroups
BUNDLE_ID    := com.rushil.grewordgroups
DERIVED_DATA := ./build
APP_PATH     := $(DERIVED_DATA)/Build/Products/Debug-iphonesimulator/GREWordGroups.app
SIM_NAME     ?= iPhone 16
SIM_ID       := $(shell ./scripts/sim-id.sh "$(SIM_NAME)")
DESTINATION  := platform=iOS Simulator,id=$(SIM_ID)

XCODEBUILD := xcodebuild -project $(PROJECT) -scheme $(SCHEME) \
	-destination '$(DESTINATION)' -derivedDataPath $(DERIVED_DATA)

.PHONY: gen build run test clean

# Regenerates the Xcode project and buildServer.json, which lets VS Code's Swift
# extension (via xcode-build-server) use the same compiler flags as `make build`.
define GENERATE
	xcodegen generate
	@if command -v xcode-build-server >/dev/null; then \
		xcode-build-server config -project $(PROJECT) -scheme $(SCHEME) >/dev/null 2>&1 \
		&& plutil -replace build_root -string "$(CURDIR)/build" buildServer.json; \
	fi
endef

gen:
	$(GENERATE)

$(PROJECT): project.yml
	$(GENERATE)

build: $(PROJECT)
	$(XCODEBUILD) build

run: build
	xcrun simctl boot $(SIM_ID) 2>/dev/null || true
	@# Xcode 27 ships DeviceHub instead of Simulator.app; use whichever exists.
	@open -a Simulator --args -CurrentDeviceUDID $(SIM_ID) 2>/dev/null \
		|| open -a DeviceHub 2>/dev/null \
		|| echo "warning: couldn't open Simulator.app or DeviceHub.app; the app still runs on the booted simulator"
	xcrun simctl bootstatus $(SIM_ID) -b
	xcrun simctl install $(SIM_ID) "$(APP_PATH)"
	xcrun simctl launch --terminate-running-process $(SIM_ID) $(BUNDLE_ID)

test: $(PROJECT)
	$(XCODEBUILD) test

clean:
	rm -rf $(DERIVED_DATA)
