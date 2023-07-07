fastzip() {
    tar -cf - $0| pv | pigz -p 4 > archive.tar.gz
}