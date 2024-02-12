git submodule update --init --recursive
git submodule foreach --recursive git fetch
git submodule update --recursive --remote --merge
