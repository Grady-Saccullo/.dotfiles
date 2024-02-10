dir=$(dirname $0)

for f in $(find ${dir:h:h} -name .zshrc); do
	if [[ "$f" == "${dir}/.zshrc" ]]; then 
		continue
	fi

	source $f
done
