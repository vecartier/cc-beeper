.PHONY: build install uninstall clean dmg update autoupdate no-autoupdate

build:
	@./build.sh

install: build
	@echo ""
	@echo "Setting up Claude Code hooks..."
	@python3 scripts/setup.py
	@echo ""
	@echo "Installing to /Applications..."
	@pkill -x CC-Beeper 2>/dev/null; sleep 1; rm -rf /Applications/CC-Beeper.app
	@cp -R CC-Beeper.app /Applications/CC-Beeper.app
	@echo "Launching CC-Beeper..."
	@open /Applications/CC-Beeper.app

uninstall: no-autoupdate
	@echo "Uninstalling CC-Beeper..."
	@python3 scripts/uninstall.py

clean:
	@rm -rf .build CC-Beeper.app CC-Beeper.dmg
	@echo "Cleaned build artifacts"

dmg:
	@./scripts/create-dmg.sh

update:
	@./scripts/update.sh

autoupdate:
	# NOTE: plist file retains legacy name com.cc-beeper.autoupdate.plist — rename not required for functionality
	@REPO="$$(cd "$(CURDIR)" && pwd)" && \
	sed "s|__REPO_PATH__|$$REPO|g" scripts/com.cc-beeper.autoupdate.plist \
		> ~/Library/LaunchAgents/com.cc-beeper.autoupdate.plist && \
	launchctl bootout gui/$$(id -u) ~/Library/LaunchAgents/com.cc-beeper.autoupdate.plist 2>/dev/null || true && \
	launchctl bootstrap gui/$$(id -u) ~/Library/LaunchAgents/com.cc-beeper.autoupdate.plist && \
	echo "Auto-update enabled — checks every 6 hours."

no-autoupdate:
	@launchctl bootout gui/$$(id -u) ~/Library/LaunchAgents/com.cc-beeper.autoupdate.plist 2>/dev/null || true
	@rm -f ~/Library/LaunchAgents/com.cc-beeper.autoupdate.plist
	@echo "Auto-update disabled."
