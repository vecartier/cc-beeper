# Homebrew Cask for CC-Beeper

## Setup (one-time)

Create a tap repo on GitHub called `homebrew-cc-beeper`, then:

```bash
# Clone the tap
mkdir -p $(brew --repository)/Library/Taps/vecartier
cd $(brew --repository)/Library/Taps/vecartier
git clone https://github.com/vecartier/homebrew-cc-beeper.git

# Copy the cask formula
mkdir -p homebrew-cc-beeper/Casks
cp /path/to/CC-Beeper/homebrew/cc-beeper.rb homebrew-cc-beeper/Casks/
cd homebrew-cc-beeper && git add -A && git commit -m "Add CC-Beeper cask" && git push
```

## Install

```bash
brew tap vecartier/cc-beeper
brew install --cask cc-beeper
```

## Update version

After tagging a new release, update `version` in `cc-beeper.rb` and push to the tap repo.
