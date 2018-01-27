function info() {
    echo ""
    echo $1
    echo ""
}

function replaceLine() {
    cat $1 | sed -e "s/$2/$3/" > /tmp/replacement
    mv /tmp/replacement $1
}

function checkIfRoot() {
	if [ "$EUID" -ne 0 ]; then
		echo "Please run as root user"
		su root
		exit
	fi
}

function checkIfNotRoot() {
	if [ "$EUID" -eq 0 ]; then
		echo "Please don't run as root user"
		su alarm
		exit
	fi
}