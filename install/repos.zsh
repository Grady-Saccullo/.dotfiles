echo "Root: Initializing the submodules"
git submodule update --remote --merge

echo "Root: Running repo install scripts"
for f in $(find . -name dotfiles-init.zsh); do
	echo "\t$f"
	bash $f
done


