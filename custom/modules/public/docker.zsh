function docker-stop-all() {
  docker stop $(docker ps -aq)
}

function docker-rm-all() {
  docker rm $(docker ps -aq)
}
