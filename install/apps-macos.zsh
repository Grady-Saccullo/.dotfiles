echo "Root: Installing app dependencies..."

# ensure xcode command line tools are installed
echo "\tXcode: checking instillation"
if ! xcode-select -p > /dev/null; then
  echo "\t\tInstalling"
  xcode-select --install
else
  echo "\t\tAlready installed"
fi

# ensure homebrew is installed
echo "\tHomebrew: checking instillation"
if ! which brew > /dev/null; then
  echo "\t\tInstalling"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  echo "\t\tInstalled"
else
  echo "\t\tAlready installed"
fi


# ensure nix is installed
echo "\tNix: checking instillation"
if ! which nix > /dev/null; then
  echo "\t\tInstalling"
  /bin/bash -c "$(curl -L https://nixos.org/nix/install) --darwin-use-unencrypted-nix-store-volume"
  echo "\t\tInstalled"
else
  echo "\t\tAlready installed"
fi
