function gtk() {
	eval "$(ssh-agent -s)"
	ssh-add ~/.ssh/zv
}
