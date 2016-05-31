#!/bin/bash
#Basic developer enviroment setup for debian based distros
#Instalation of sublime text thanks to: https://gist.github.com/simonewebdesign/8507139

install_pebble_sdk() {

	sudo apt-get install python-pip python2.7-dev libsdl1.2debian libfdt1 libpixman-1-0
	sudo pip install virtualenv

	if [ "$(uname -m)" = "x86_64" ]; then
	  ARCH="64"
	else
	  ARCH="32"
	fi

	VERSION=$(echo $(curl https://developer.pebble.com/sdk/) | sed -rn "s#.*Current Tool Version: ([0-9]{1,2}([,.][0-9]{1,2})+)..*#\1#p")
	URL="https://s3.amazonaws.com/assets.getpebble.com/pebble-tool/pebble-sdk-{$VERSION}-linux{$ARCH}.tar.bz2"
	DIR="/opt/pebble_sdk"

	curl -o $HOME/pbl.tar.bz2 $URL
	if tar -xf $HOME/pbl.tar.bz2 --directory=$HOME; then
		sudo rm -rf $DIR
		sudo mv $HOME/pebble-sdk-{$VERSION}-linux{$ARCH} $DIR
		#sudo ln -s $DIR/pebble-sdk-{$VERSION}-linux{$ARCH}/bin/pebble /bin/
	fi
	rm $HOME/pbl.tar.bz2
	cd $DIR/pebble-sdk-{$VERSION}-linux{$ARCH}
	virtualenv --no-site-packages .env
	source .env/bin/activate
	pip install -r requirements.txt
	deactivate
}

install_sublime() {

	if [ "$(uname -m)" = "x86_64" ]; then
	  ARCHITECTURE="x64"
	else
	  ARCHITECTURE="x32"
	fi

	BUILD=$(echo $(curl http://www.sublimetext.com/3) | sed -rn "s#.*The latest build is ([0-9]+)..*#\1#p")

	URL="https://download.sublimetext.com/sublime_text_3_build_{$BUILD}_{$ARCHITECTURE}.tar.bz2"
	INSTALLATION_DIR="/opt/sublime_text"

	curl -o $HOME/st3.tar.bz2 $URL
	if tar -xf $HOME/st3.tar.bz2 --directory=$HOME; then
	  sudo rm -rf $INSTALLATION_DIR /bin/subl
	  sudo mv $HOME/sublime_text_3 $INSTALLATION_DIR
	  sudo ln -s $INSTALLATION_DIR/sublime_text /bin/subl
	fi
	rm $HOME/st3.tar.bz2

	sudo ln -s $INSTALLATION_DIR/sublime_text.desktop /usr/share/applications/sublime_text.desktop

	sudo sed -i.bak 's/Icon=sublime-text/Icon=\/opt\/sublime_text\/Icon\/128x128\/sublime-text.png/g' /usr/share/applications/sublime_text.desktop
}

install_packages() {
	if [ $1 = "Sublime Text" ]; then
		install_sublime
	elif [ $1 = "pebble" ]; then
		install_pebble_sdk
	else
		sudo apt-get install $1
	
	fi
}

choose_packages() {
	OPTIONS=$(whiptail --title "Test Checklist Dialog" --checklist --separate-output \
	"Choose packages to install " 15 60 4 \
	"gcc" "GNU C Compiler" OFF \
	"g++" "GNU C++ compiler" OFF \
	"golang" "Go compiler" OFF \
	"default-jre" "Java Runtime Environment" OFF \
	"default-jdk" "Java Development Kit" OFF \
	"scala" "Scala Compiler" OFF  \
	"pebble" "Pebble Smartwatch SDK" OFF 3>&1 1>&2 2>&3)

	selection=$?

	if [ $selection=0 ]; then 
		for p in $OPTIONS; do
			install_packages $p
		done
	else
		whiptail --title "Cancel" --msgbox "Operation Cancelled" 10 60
	fi
}

choose_editors() {
		OPTIONS=$(whiptail --title "Test Checklist Dialog" --checklist --separate-output \
	"Choose packages to install " 15 60 4 \
	"Emacs" "GNU Emacs editor" OFF \
	"vim" "Vi Improved" OFF \
	"Sublime Text" "Sublime Text 3" OFF 3>&1 1>&2 2>&3)

	selection=$?

	if [ $selection=0 ]; then 
		for p in $OPTIONS; do
			install_packages $p
		done
	else
		whiptail --title "Cancel" --msgbox "Operation Cancelled" 10 60
	fi
}

update_system() {
	echo "Updating"
	sudo apt-get update
}

main_menu() {
	OPTION=$(whiptail --title "Debian Dev Tools" --menu "Choose your option" 15 60 4 \
		"1" "Install Compilers" \
		"2" "Install Text Editors" \
		"3" "Update Sublime Text" \
		"4" "Exit"  3>&1 1>&2 2>&3)
	 
	exitstatus=$?
	if [ $exitstatus = 0 ]; then
	    case $OPTION in 
	    	1) choose_packages
			;;
			2) choose_editors
			;;
			3)install_sublime
			;;
			4) exit 0
			;;
		esac
	else
	    whiptail --title "Cancel" --msgbox "Operation Cancelled" 10 60
	    exit 0
	fi
}

if [ "$(id -u)" != "0" ]; then
	if (whiptail --title "No Root" --yesno "No root permissions detected, shall we get them with sudo?" 10 60) then
	    update_system
	    install_packages "curl"
	    while true 
	    do
	    	main_menu
	    done
	else
	    whiptail --title "Error" --msgbox "Can't continue without root permissions." 10 60 
	    exit 1
	fi
fi

