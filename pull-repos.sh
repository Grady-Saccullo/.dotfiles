repos=(
	"configs/nvim/.config/nvim"
	"repos/personal"
	"repos/work/voze"
	"repos/work/seer"
)


dir=$(pwd)
for repo in "${repos[@]}"; do
	printf "Pulling %s\n" "$repo"
	cd "$dir/$repo" || exit
	git fetch origin
	git checkout main
	git pull
	printf "\n"
done
