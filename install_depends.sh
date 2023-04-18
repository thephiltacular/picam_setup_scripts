#!/bin/bash
################################################################################
# Variables Start
######################################################################

ZSHRC="$HOME/.zshrc"
INPUTRC="$HOME/.inputrc"
INPUTRC_template="inputrc"
DOCKER_DAEMON="/etc/docker/daemon.json"
DOCKER_DAEMON_TEMPLATE="daemon.json"
WORKING_DIR="$(pwd)"

# Colors
normal=$(tput sgr0)
red=$(tput setaf 1)
green=$(tput setaf 2)
yellow=$(tput setaf 3)
blue=$(tput setaf 4)

separator="========================================\n"

######################################################################
# Variables End
################################################################################

################################################################################
# Helper Functions Start
######################################################################
count_down(){
    secs=$1
    printf "\n"
    while [ "$secs" -gt 0 ]; do
    echo -ne "Time remaing: $secs\033[0K  \r"
    sleep 1
    : $((secs--))
    done
}

print_red(){
    text="${red} $1 ${normal}"
    # shellcheck disable=2059
    printf "$text"
}

print_green(){
    text="${green} $1 ${normal}"
    # shellcheck disable=2059
    printf "$text"
}

print_yellow(){
    text="${yellow} $1 ${normal}"
    # shellcheck disable=2059
    printf "$text"
}

print_blue(){
    text="${blue} $1 ${normal}"
    # shellcheck disable=2059
    printf "$text"
}

# Checks if string exists in file
# Example:
# check_if_exists_and_add "str" "file"
check_if_exists_and_add() {
    local str="$1"
    local file="$2"
    if grep -Fxsq "$str" "$file"; then
        echo "found \"$str\" in file, skipping"
    else
        echo >>"$file"
        echo -n "$str" >>"$file"
    fi

}

# Checks if string exists in file, using sudo
# Example:
# check_if_exists_and_add_sudo "str" "file"
check_if_exists_and_add_sudo() {
    local str="$1"
    local file="$2"
    if grep -Fxq "$str" "$file"; then
        echo "found \"$str\" in file, skipping"
    else
        echo -e "$str" | sudo tee -a "$file" >/dev/null
    fi
}

# Backs up file with a data and time stamp
back_up_file() {
    FILE="$(basename -- "$1")"
    FILENAME_BACKUP="$1-backup-$(date +'%m-%d-%Y-%T')"
    FOLDER_BACKUP="$1-backup"
    echo "Storing backups in folder: $FOLDER_BACKUP"
    if [ ! -d "$FOLDER_BACKUP" ]; then
        mkdir "$FOLDER_BACKUP"
    fi

    if [ -f "$1" ]; then
        cat "$1" >>"$FOLDER_BACKUP/$1-backup-$(date +'%m-%d-%Y-%T')"
    fi
    echo "Backing up $FILE to $FOLDER_BACKUP/$FILENAME_BACKUP"
}


# Compares to files and adds any lines from the left
# that are missing in the right to the right
# Example:
# compare_files_add_missing_left_to_right left_file right_file
compare_files_add_missing_left_to_right() {
    LEFT="$1"
    RIGHT="$2"
    back_up_file "$RIGHT"
    grep -F -vxf "$RIGHT" "$LEFT" >>temp
    echo >>"$RIGHT"
    cat temp >>"$RIGHT"
    rm temp
}


add_missing_lines() {
    LEFT=$1
    RIGHT=$2
    ELEVATE=false
    if [ -n "$3" ]; then
        ELEVATE=$3
    else
        ELEVATE=false
    fi
    print_red "Sudo needed: $ELEVATE"
    print_yellow "Comparing $LEFT to $RIGHT and adding missing lines..."
    print_blue "The following lines are being added to your file %s\n" "$LEFT"
    diff "$LEFT" "$RIGHT" | grep '> ' | sed 's/> //'
    if $ELEVATE; then
        diff "$LEFT" "$RIGHT" | grep '> ' | sed 's/> //' | sudo tee -a "$LEFT" >/dev/null
    else
        cat "$LEFT" >>temp
        diff temp "$RIGHT" | grep '> ' | sed 's/> //' >>"$LEFT"
        rm temp
    fi

}


#!/bin/bash
# Author : Teddy Skarin

# 1. Create ProgressBar function
# 1.1 Input is currentState($1) and totalState($2)
function ProgressBar {
    # Process data
    # shellcheck disable=2017
    (( _progress=(${1}*100/${2}*100)/100 ))
    (( _done=(_progress*4)/10 ))
    (( _left=40-_done ))
    # Build progressbar string lengths
    _fill=$(printf "%${_done}s")
    _empty=$(printf "%${_left}s")

    # 1.2 Build progressbar strings and print the ProgressBar line
    # 1.2.1 Output example:
    # 1.2.1.1 Progress : [########################################] 100%
    # printf "\rProgress : [${_fill// /▇}${_empty// / }] ${_progress}%%\033[0K\r"
    echo -ne "                                                                               Progress : [${_fill// /▇}${_empty// / }] ${_progress}%%\033[0K\r"

}

# Variables
_start=1
# This accounts as the "totalState" variable for the ProgressBar function
_end=100

# Function that increments progress and displays progress bar
update_progress(){
    _start=$((_start+1))
    echo
    ProgressBar _start _end
    echo
}


######################################################################
# Helper Functions End
################################################################################

######################################################################
# Setup Functions start
################################################################################

# Displays intro message and waits for user to read it
print_intro_message() {
    print_yellow "$separator"
    print_yellow "\nThis script will automatically set up raspi cam system on raspberry pi\n"
    print_red "\n IMPORTANT:\n"
    print_yellow "During the zsh install process you will have to input your password\n"
    print_yellow "During this process, the zsh shell might open...\n"
    print_yellow "If your prompt changes and the script pauses, to continue type:\n\n"
    print_green "exit\n\n"
    print_blue "\n\n Please contact Philip Mai if you run into any issues :) \n\n"
    print_yellow "$separator\n"
    print_yellow "Please read the above message, this script will start in 10 seconds...."
    count_down 10
    update_progress
}


# Installs all necessary dependencies and pre-commit
install_dependencies() {
    # Install necessary packages
    print_yellow "Installing necessary packages ... \n"
    # Install script for all depends for cameras on raspberry pi
    sudo apt update && sudo apt upgrade -y
    sudo apt update --fix-missing && update_progress
    sudo apt install -y xserver-xorg raspberrypi-ui-mods && update_progress
    sudo apt install -y gcc g++ ffmpeg && update_progress
    sudo apt install -y autoconf automake autopoint build-essential pkgconf libtool libzip-dev && update_progress
    sudo apt install -y avahi-daemon insserv && update_progress
    sudo apt install -y x11-xserver-utils && update_progress
    sudo apt install -y build-essential cmake pkg-config libjpeg-dev libtiff5-dev libjasper-dev libpng-dev libavcodec-dev libavformat-dev libswscale-dev libv4l-dev libxvidcore-dev libx264-dev libfontconfig1-dev libcairo2-dev libgdk-pixbuf2.0-dev libpango1.0-dev libgtk2.0-dev libgtk-3-dev libatlas-base-dev gfortran libhdf5-dev libhdf5-serial-dev libhdf5-103 python3-pyqt5 python3-dev && update_progress
    sudo apt install -y libopencv-dev python3-opencv opencv-data && update_progress
    sudo apt install -y vlc && update_progress
    sudo apt install -y python3-pyqt5 python3-opengl && update_progress
    sudo apt install -y python3-picamera2 && update_progress
    sudo apt install -y cmake && update_progress
    sudo apt install -y python-imaging && update_progress
    sudo apt install -y qt5-default && update_progress
    sudo apt install -y libjpeg-dev zlib1g-dev libfreetype6-dev liblcms1-dev libopenjp2-7 libtiff5 libjpeg62-turbo-dev:armhf libjpeg62-turbo-dev libsdl-image1.2-dev && update_progress
    sudo apt install -y libsdl2-dev && update_progress
    sudo apt install -y protobuf-compiler libprotobuf-dev && update_progress
    sudo apt install -y libjpeg8-dev && update_progress
    sudo apt install -y libjpeg9-dev libjpeg62-turbo-dev && update_progress
    sudo apt install -y python3-libcamera python3-kms++ && update_progress
    sudo apt install -y python3-pyqt5 python3-prctl libatlas-base-dev ffmpeg python3-pip && update_progress
    sudo apt install -y libpcap-dev && update_progress
    sudo apt install -y libpcap0.8 libpcap0.8-dev libpcap-dev && update_progress
    sudo apt install -y v4l-utils && update_progress
    sudo apt update --fix-missing && update_progress
    sudo apt auto-remove && update_progress
    print_yellow "Done! \n"
}

# Installs all vscode extensions found in the vscode_extensions file if code
# has already been installed on your windows system
install_dependencies_vscode() {
    print_yellow "Installing vscode extensions...\n"
    if [ -d "$WINDOWS_USER_PATH/AppData/Local/Programs/Microsoft VS Code" ]; then
        print_green "code exists" && update_progress
    fi
    cd "$WORKING_DIR" || exit
    FILE=vscode_extensions
    for arg in $(<$FILE);
    do
        code --install-extension "$arg" &> /dev/null
        echo -ne "Installing: $arg"
        update_progress
    done
    # xargs -a "$FILE" -I{} -d'\n' command --option {} other args
    print_yellow "Done!"
    update_progress
}

# TODO: create function that installs and configures ROS/ROS2

# Install docker if it doesn't exist already
install_docker() {
    print_yellow "Setting up docker ... \n"
    if ! command -v docker &>/dev/null; then
        print_yellow "Existing installation not found, installing...\n"
        sudo apt install apt-transport-https ca-certificates curl gnupg-agent software-properties-common -y &> /dev/null && update_progress
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add - && update_progress
        sudo apt-key fingerprint 0EBFCD88 && update_progress
        sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" -y && update_progress
        sudo apt install docker-ce docker-ce-cli containerd.io -y &> /dev/null && update_progress
        sudo groupadd docker && update_progress
        sudo usermod -aG docker "$USER" && update_progress
        print_green "Done! \n" && update_progress

    else
        print_green "Docker already installed, skipping...\n" && update_progress
    fi
}

# Script that generates a default ssh key and displays the result
setup_ssh() {
    # Set up SSH keys and display public key
    if ! [ -f "$HOME"/.ssh/id_rsa.pub ]; then

        print_yellow "Setting up SSH Keys ... \n"
        print_yellow '\n\n\n\n\n' | ssh-keygen
        cat "$HOME"/.ssh/id_rsa.pub
        printf "\n"
    else
        print_green "ssh key already exists\n"
    fi
}

setup_bash() {
    # Set up .bashrc and .bash_profile
    # echo "source $HOME/.bashrc" >> $HOME/.bash_profile
    if ! [ -f "$HOME"/.bashrc ]; then
        cat "$HOME"/.bashrc_example >>"$HOME"/.bashrc
        # shellcheck disable=SC1091
        source "$HOME"/.bashrc
    fi
    check_if_exists_and_add "source $HOME/.bashrc" "$HOME/.bash_profile" && update_progress
}

# Installs and configures zsh
setup_zsh() {
    # Install zsh and oh-my-zsh for a better shell experience
    print_yellow "Backing up zshrc if it exists...\n"

    print_yellow "Installing zsh if it is not already installed...\n"

    if command -v zsh &> /dev/null; then
        print_green "oh-my-zsh or ezsh is installed\n" && update_progress

    else
        print_red "oh-my-zsh or ezsh is not installed\n"
        sudo apt update && sudo apt install zsh -y &> /dev/null && update_progress

        cd "$HOME/" || exit
        sudo apt update
        print_red "=================\n\n\nIMPORTANT\n\n\nWhen the next portion completes, enter y, then when the shell changes type \"exit\"\n\n\n\n\n=================\n"
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" -y
        git clone https://github.com/jotyGill/ezsh.git && update_progress
        print_yellow "Installing for current user ...\n" && update_progress
        sudo chmod +x ezsh/* && update_progress
        cd ezsh || exit
        ./install.sh -c -y
        cd .. || exit
        print_green "done! \n"
        cd "$WORKING_DIR" || exit
        # shellcheck disable=SC1091
        echo "[[ -s \"$HOME/.config/ezsh/marker/marker.sh\" ]] && source \"$HOME/.config/ezsh/marker/marker.sh\"" >> $HOME/.bashrc
        [[ -s "$HOME/.config/ezsh/marker/marker.sh" ]] && source "$HOME/.config/ezsh/marker/marker.sh"
    fi
    print_yellow "Checking .zshrc for any missing components and adding them...\n"
    # while read arg; do check_if_exists_and_add "$arg" "$ZSHRC"; done < example.zshrc
    compare_files_add_missing_left_to_right "example.zshrc" "$ZSHRC" && update_progress

    print_blue "Done! \n"

}

# Update inputrc so that things are more comfortable
# disable bell on tab complete and ignore capitalization during tab complete
setup_inputrc() {
    print_yellow "Setting up inputrc...\n"
    cd "$WORKING_DIR" || exit
    # for arg in $(< "$INPUTRC_template"); do check_if_exists_and_add "$arg" "$INPUTRC"; done
    compare_files_add_missing_left_to_right "$INPUTRC_template" "$INPUTRC" && update_progress
    print_green "Done! \n"

}

######################################################################
# Setup Functions End
################################################################################


################################################################################
# Main
######################################################################

print_intro_message && update_progress
print_yellow "Starting installation of dependencies and set up of camera system\non raspberry pi running mainsailOS...\n"
setup_zsh && update_progress
install_dependencies && update_progress
# install_dependencies_vscode && update_progress
# install_docker && update_progress
# setup_docker_daemon && update_progress
# setup_ssh && update_progress
# setup_bash && update_progress
setup_inputrc && update_progress
# setup_systemd && update_progress

# Final update to progress bar
_end=$_start-1
_end=$((_start+1))
update_progress

print_green "\n===========\n\nRestart the shell to apply all changes\n\n===========\n"


# # Install script for all depends for cameras on raspberry pi
# sudo apt update && sudo apt upgrade -y
# sudo apt update --fix-missing
# sudo apt install -y xserver-xorg raspberrypi-ui-mods
# sudo apt install -y gcc g++ ffmpeg
# sudo apt install -y autoconf automake autopoint build-essential pkgconf libtool libzip-dev
# sudo apt install -y avahi-daemon insserv
# sudo apt install -y x11-xserver-utils
# sudo apt install -y build-essential cmake pkg-config libjpeg-dev libtiff5-dev libjasper-dev \
#  libpng-dev libavcodec-dev libavformat-dev libswscale-dev libv4l-dev libxvidcore-dev libx264-dev \ 
#  libfontconfig1-dev libcairo2-dev libgdk-pixbuf2.0-dev libpango1.0-dev libgtk2.0-dev libgtk-3-dev \
#  libatlas-base-dev gfortran libhdf5-dev libhdf5-serial-dev libhdf5-103 python3-pyqt5 python3-dev
# sudo apt install -y libopencv-dev python3-opencv opencv-data
# sudo apt install -y vlc
# sudo apt install -y python3-pyqt5 python3-opengl
# sudo apt install -y python3-picamera2
# sudo apt install -y cmake
# sudo apt install -y python-imaging
# sudo apt install -y qt5-default
# sudo apt install -y libjpeg-dev zlib1g-dev libfreetype6-dev liblcms1-dev libopenjp2-7 libtiff5 libjpeg62-turbo-dev:armhf libjpeg62-turbo-dev libsdl-image1.2-dev
# sudo apt install -y libsdl2-dev
# sudo apt install -y protobuf-compiler libprotobuf-dev
# sudo apt install -y libjpeg8-dev
# sudo apt install -y libjpeg9-dev libjpeg62-turbo-dev
# sudo apt install -y python3-libcamera python3-kms++
# sudo apt install -y python3-pyqt5 python3-prctl libatlas-base-dev ffmpeg python3-pip
# sudo apt install -y libpcap-dev 
# sudo apt install -y libpcap0.8 libpcap0.8-dev libpcap-dev
# sudo apt install -y v4l-utils
# sudo apt update --fix-missing
# sudo apt auto-remove