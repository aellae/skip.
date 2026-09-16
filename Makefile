.DEFAULT_GOAL := help

FLUTTER ?= flutter
KEY_PROPERTIES := android/key.properties
EXPORT_OPTIONS := ios/ExportOptions.plist

.PHONY: help get analyze test clean run run-ios run-android aab ios release

help:
	@echo "SKIP - available targets:"
	@echo "  make get          Install Flutter/Dart dependencies"
	@echo "  make run          Run the app on the iOS Simulator (default)"
	@echo "  make run-android  Run the app on the Android emulator (asks to confirm first)"
	@echo "  make analyze      Run flutter analyze"
	@echo "  make test         Run flutter test"
	@echo "  make aab          Build a release Android App Bundle (.aab) for Play Store"
	@echo "  make ios          Build a release iOS .ipa for App Store / TestFlight"
	@echo "  make release      Build both the .aab and the .ipa"
	@echo "  make clean        Remove build artifacts"

get:
	$(FLUTTER) pub get

analyze:
	$(FLUTTER) analyze

test:
	$(FLUTTER) test

clean:
	$(FLUTTER) clean

# CLAUDE.md: default to the iOS Simulator for routine runs; the Android
# emulator eats disk space and should only start when asked for explicitly.
run: run-ios

run-ios:
	@SIM_ID=$$(xcrun simctl list devices booted | grep -Eo '[0-9A-F]{8}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{12}' | head -1); \
	if [ -z "$$SIM_ID" ]; then \
		echo "No iOS Simulator booted - launching the default one..."; \
		$(FLUTTER) emulators --launch apple_ios_simulator >/dev/null 2>&1; \
		for i in 1 2 3 4 5 6 7 8 9 10; do \
			SIM_ID=$$(xcrun simctl list devices booted | grep -Eo '[0-9A-F]{8}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{12}' | head -1); \
			[ -n "$$SIM_ID" ] && break; \
			sleep 2; \
		done; \
	fi; \
	if [ -z "$$SIM_ID" ]; then echo "error: could not boot an iOS Simulator"; exit 1; fi; \
	$(FLUTTER) run -d $$SIM_ID

run-android:
	@echo "This starts the Android emulator (Medium_Phone_API_36.1), which can"
	@echo "consume several GB of RAM/disk and has filled this machine's disk before."
	@read -p "Continue? [y/N] " ans; [ "$$ans" = "y" ] || [ "$$ans" = "Y" ] || exit 1
	$(FLUTTER) run -d android

# Requires android/key.properties (copy android/key.properties.example and
# fill in your keystore) - falls back to debug signing otherwise, which
# Play Store will reject.
aab: get
	@test -f $(KEY_PROPERTIES) || { \
		echo "error: $(KEY_PROPERTIES) not found."; \
		echo "Copy android/key.properties.example to $(KEY_PROPERTIES) and fill in your release keystore."; \
		exit 1; \
	}
	$(FLUTTER) build appbundle --release
	@echo "AAB ready at build/app/outputs/bundle/release/app-release.aab"

# Requires ios/ExportOptions.plist (copy ios/ExportOptions.plist.example
# and fill in your Apple Team ID). Archiving/signing happens via Xcode, so
# this must run on macOS with the release certificate/profile installed.
ios: get
	@test -f $(EXPORT_OPTIONS) || { \
		echo "error: $(EXPORT_OPTIONS) not found."; \
		echo "Copy ios/ExportOptions.plist.example to $(EXPORT_OPTIONS) and fill in your Apple Team ID."; \
		exit 1; \
	}
	$(FLUTTER) build ipa --release --export-options-plist=$(EXPORT_OPTIONS)
	@echo "IPA ready in build/ios/ipa/"

release: aab ios
