cask "cc-beeper" do
  version "1.0.0"
  sha256 :no_check

  url "https://github.com/vecartier/CC-Beeper/releases/download/v#{version}/CC-Beeper.dmg"
  name "CC-Beeper"
  desc "Floating widget companion for Claude Code — LCD pager with hotkeys, voice, and permissions"
  homepage "https://github.com/vecartier/CC-Beeper"

  depends_on macos: ">= :sequoia"

  app "CC-Beeper.app"

  postflight do
    # Install Claude Code hooks after app is in /Applications
    system_command "/usr/bin/open", args: ["-a", "CC-Beeper"]
  end

  zap trash: [
    "~/.claude/cc-beeper",
    "~/.cache/cc-beeper",
    "~/Library/Preferences/com.vecartier.CC-Beeper.plist",
  ]
end
