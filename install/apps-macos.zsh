# ensure xcode command line tools are installed
if ! xcode-select -p > /dev/null; then
  echo "Installing xcode command line tools..."
  xcode-select --install
fi

# ensure homebrew is installed
if ! which brew > /dev/null; then
  echo "Installing homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi


