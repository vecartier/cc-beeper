.PHONY: build install uninstall clean dmg

build:
	@./build.sh

install: build
	@echo ""
	@echo "Setting up Claude Code hooks..."
	@python3 setup.py
	@echo ""
	@echo "Launching Claumagotchi..."
	@open Claumagotchi.app

uninstall:
	@echo "Uninstalling Claumagotchi..."
	@python3 uninstall.py

clean:
	@rm -rf .build Claumagotchi.app Claumagotchi.dmg
	@echo "Cleaned build artifacts"

dmg: build
	@./create-dmg.sh
