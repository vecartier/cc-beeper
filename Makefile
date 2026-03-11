.PHONY: build install uninstall clean

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
	@rm -rf .build Claumagotchi.app
	@echo "Cleaned build artifacts"
