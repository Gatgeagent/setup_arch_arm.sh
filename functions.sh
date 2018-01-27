function info() {
    echo ""
    echo -e "\3[36m$1"
    echo ""
}

function info_simple() {
	echo -e "\3[36m$1"
}

function replaceLine() {
    cat $1 | sed -e "s/$2/$3/" > /tmp/replacement
    mv /tmp/replacement $1
}

function checkIfRoot() {
	if [ "$EUID" -ne 0 ]; then
		echo "Please run as root user"
		su root
		exit 1
	fi
}

function checkIfNotRoot() {
	if [ "$EUID" -eq 0 ]; then
		echo "Please don't run as root user"
		su alarm
		exit 1
	fi
}