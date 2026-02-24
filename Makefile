DEVELOPER_DIR ?= /Applications/Xcode.app/Contents/Developer
APP_NAME      := PomodoroTimer
BUILD_DIR     := $(CURDIR)/build

.PHONY: generate build install uninstall clean

generate:
	xcodegen generate

build: generate
	DEVELOPER_DIR="$(DEVELOPER_DIR)" \
	xcodebuild \
	  -scheme "$(APP_NAME)" \
	  -configuration Release \
	  -destination 'platform=macOS' \
	  CONFIGURATION_BUILD_DIR="$(BUILD_DIR)" \
	  CODE_SIGN_IDENTITY="-" \
	  CODE_SIGN_STYLE=Manual \
	  build

install: build
	@echo "→ Installing to /Applications/..."
	rm -rf "/Applications/$(APP_NAME).app"
	cp -Rf "$(BUILD_DIR)/$(APP_NAME).app" /Applications/
	xattr -rd com.apple.quarantine "/Applications/$(APP_NAME).app" 2>/dev/null || true
	@echo "✓ Installed. Launching $(APP_NAME)..."
	open "/Applications/$(APP_NAME).app"

uninstall:
	osascript -e 'quit app "$(APP_NAME)"' 2>/dev/null || true
	rm -rf "/Applications/$(APP_NAME).app"
	@echo "✓ $(APP_NAME) removed."

clean:
	rm -rf "$(BUILD_DIR)"
	rm -rf ~/Library/Developer/Xcode/DerivedData/$(APP_NAME)-*
