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

# Your Apple team for signing on a real iPhone. Set TEAM_ID in local.mk (git-ignored).
-include local.mk
TEAM_ID ?=
DEVICE_APP_PATH := $(DERIVED_DATA)/Build/Products/Release-iphoneos/GREWordGroups.app

XCODEBUILD := xcodebuild -project $(PROJECT) -scheme $(SCHEME) \
	-destination '$(DESTINATION)' -derivedDataPath $(DERIVED_DATA)

.PHONY: gen build run test device backup restore clean

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

# Builds a Release copy, signs it with your (free) team, and installs it on the
# connected iPhone. Free signing expires after 7 days: run this again to renew.
device: $(PROJECT)
	@test -n "$(TEAM_ID)" || { echo "error: set TEAM_ID in local.mk (see README)"; exit 1; }
	@DEVICE_ID=$$(./scripts/device-id.sh) || exit 1; \
	set -e; \
	xcodebuild -project $(PROJECT) -scheme $(SCHEME) -configuration Release \
		-destination "id=$$DEVICE_ID" -derivedDataPath $(DERIVED_DATA) \
		-allowProvisioningUpdates DEVELOPMENT_TEAM=$(TEAM_ID) CODE_SIGN_STYLE=Automatic build; \
	./scripts/progress.sh backup "$$DEVICE_ID"; \
	xcrun devicectl device install app --device "$$DEVICE_ID" "$(DEVICE_APP_PATH)"; \
	xcrun devicectl device process launch --device "$$DEVICE_ID" $(BUNDLE_ID) \
		|| echo "Installed. If it won't open, trust the developer: Settings > General > VPN & Device Management."

# Copies your saved progress from the phone into backups/ (also runs on every `make device`).
backup:
	@DEVICE_ID=$$(./scripts/device-id.sh) || exit 1; ./scripts/progress.sh backup "$$DEVICE_ID"

# Puts a backup back on the phone. Close the app first. Example:
#   make restore BACKUP=backups/2026-09-30_150000
restore:
	@test -n "$(BACKUP)" || { echo "usage: make restore BACKUP=backups/<folder>"; ls -1 backups 2>/dev/null; exit 1; }
	@DEVICE_ID=$$(./scripts/device-id.sh) || exit 1; ./scripts/progress.sh restore "$$DEVICE_ID" "$(BACKUP)"

clean:
	rm -rf $(DERIVED_DATA)
