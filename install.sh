#!/bin/bash

linuxID=$(lsb_release -si)

if [ $linuxID != "ChimeraOS" ]; then

echo "安装 EmuDeck"

elif [ $linuxID != "SteamOS" ]; then


    zenityAvailable=$(command -v zenity &> /dev/null  && echo true)

    if [[ $zenityAvailable = true ]];then
        PASSWD="$(zenity --password --title="输入密码" --text="输入你的用户 sudo 密码以安装所需的依赖项" 2>/dev/null)"
        echo "$PASSWD" | sudo -v -S
        ans=$?
        if [[ $ans == 1 ]]; then
            #incorrect password
            PASSWD="$(zenity --password --title="输入密码" --text="密码不正确，再试一次。 （你记得在运行这个之前为 Linux 设置密码吗？）" 2>/dev/null)"
            echo "$PASSWD" | sudo -v -S
            ans=$?
            if [[ $ans == 1 ]]; then
                    text="$(printf "<b>密码不被接受</b>\n需要密码的高级模式工具将无法工作，禁用它们。")"
                    zenity --error \
                    --title="EmuDeck" \
                    --width=400 \
                    --text="${text}" 2>/dev/null
                    setSetting doInstallPowertools false
                    setSetting doInstallGyro false
            fi
        fi
    fi

    SCRIPT_DIR=$( cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)

    function log_err {
      echo "$@" >&2
    }

    function script_failure {
      log_err "发生错误:$([ -z "$1" ] && " on line $1" || "(unknown)")."
      log_err "安装失败！"
      exit
    }

    #trap 'script_failure $LINENO' ERR

    echo "正在安装 EmuDeck 依赖项..."


    if command -v apt-get >/dev/null; then
        echo "使用 apt 安装软件包..."
        DEBIAN_DEPS="jq zenity flatpak unzip bash libfuse2 git rsync whiptail"

        sudo killall apt apt-get
        sudo apt-get -y update
        sudo apt-get -y install $DEBIAN_DEPS
    elif command -v pacman >/dev/null; then
        echo "使用 pacman 安装软件包..."
        ARCH_DEPS="steam jq zenity flatpak unzip bash fuse2 git rsync whiptail"

        sudo pacman --noconfirm -Syu
        sudo pacman --noconfirm -S $ARCH_DEPS
    elif command -v dnf >/dev/null; then
        echo "正在使用 dnf 安装软件包..."
        FEDORA_DEPS="jq zenity flatpak unzip bash fuse git rsync whiptail"

        sudo dnf -y upgrade
        sudo dnf -y install $FEDORA_DEPS
    elif command -v zypper >/dev/null; then
        echo "使用 zypper 安装软件包..."
        SUSE_DEPS="steam jq zenity flatpak unzip bash libfuse2 git rsync whiptail"

        sudo zypper --non-interactive up
        sudo zypper --non-interactive install $SUSE_DEPS
    elif command -v xbps-install >/dev/null; then
        echo "正在使用 xbps 安装软件包..."
        VOID_DEPS="steam jq zenity flatpak unzip bash fuse git rsync whiptail"

        sudo xbps-install -Syu
        sudo xbps-install -Sy $VOID_DEPS
    else
        log_err "此脚本不支持您的 Linux 发行版 $linuxID，我们邀请你提出 PR 或帮助我们将你的操作系统添加到此脚本中。 https://github.com/dragoonDorise/EmuDeck/issues"
        exit 1
    fi


    # this could be replaced to immediately start the EmuDeck setup script

    echo "所有必备软件包均已安装，现在将安装 EmuDeck！"

fi

set -eo pipefail

report_error() {
    FAILURE="$(caller): ${BASH_COMMAND}"
    echo "出了些问题！"
    echo "错误为 ${FAILURE}"
}

trap report_error ERR

EMUDECK_GITHUB_URL="https://api.github.com/repos/EmuDeck/emudeck-electron/releases/latest"
EMUDECK_URL="$(curl -s ${EMUDECK_GITHUB_URL} | grep -E 'browser_download_url.*AppImage' | cut -d '"' -f 4)"

mkdir -p ~/Applications
curl -L "${EMUDECK_URL}" -o ~/Applications/EmuDeck.AppImage 2>&1 | stdbuf -oL tr '\r' '\n' | sed -u 's/^ *\([0-9][0-9]*\).*\( [0-9].*$\)/\1\n#Download Speed\:\2/' | zenity --progress --title "正在下载 EmuDeck" --width 600 --auto-close --no-cancel 2>/dev/null
chmod +x ~/Applications/EmuDeck.AppImage
~/Applications/EmuDeck.AppImage
