function agk() {
	eval "$(ssh-agent -s)"
	ssh-add ~/.ssh/zv
}
