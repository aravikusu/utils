#!/bin/bash

IS_MAC=false
DISTRO=""

init () {
    case "$(uname)" in
        "Linux") 
            get_distro
            ;;
        "Darwin")
            IS_MAC=true
            ;;
        *) 
            echo "Only Linux and MacOS is supported at the moment" 
            exit;;
    esac
    # Make sure we have my preferred package managers
    if $IS_MAC
    then
        check_brew
    else
        if [ "$DISTRO" == "Arch Linux" ]; then
            check_yay
        fi
        
        check_zsh
    fi

    # Now we have to install gum
    check_gum

    if ! command -v gum &> /dev/null
    then
        echo "seems like gum failed to install, sorry"
        exit
    fi

    gum_ui
}

gum_ui () {
    while :
    do
        clear
        gum style --border normal --margin "1" --padding "1 2" --border-foreground 212 "$(gum style --foreground 212 'aravix')'s system bootstrapper"

        GIT="Install git"; TERMINAL="Configure terminal"; EXIT="Exit"; NODE="Install Node"; RUST="Install Rust"; KDE="Configure KDE"; DOTS="Reset dotfiles pls"
        FLATPAK_GEN="Flatpaks (General)" FLATPAK_GAME="Flatpaks (Games)"

        if $IS_MAC
        then
            ACTIONS=$(gum choose --limit 1 "$GIT" "$TERMINAL" "$NODE" "$RUST" "$DOTS" "$EXIT")
        else
            ACTIONS=$(gum choose --limit 1 "$GIT" "$TERMINAL" "$KDE" "$FLATPAK_GEN" "$FLATPAK_GAME" "$NODE" "$RUST" "$DOTS" "$EXIT")
        fi

        case "$ACTIONS" in
            "$GIT")
                install_git
                ;;
            "$TERMINAL")
                setup_terminal
                ;;
            "$NODE")
                install_node
                ;;
            "$RUST")
                install_rust
                ;;
            "$KDE")
                setup_kde
                ;;
            "$FLATPAK_GEN")
                install_flatpak_general
                ;;
            "$FLATPAK_GAME")
                install_flatpak_games
                ;;
            "$DOTS")
                reset_dots
                ;;
            "$EXIT")
                echo "Aight, see ya later."
                break
        esac
    done
}

# can't do shit without git
install_git () {
    if ! command -v git &> /dev/null
    then
        echo "Installing git..."
        install_pkg "git"
        echo "git installed, continuing..."
    else
        echo "git is already installed."
    fi
    sleep 1
}

# The part that configures my terminal.
setup_terminal () {
    echo "Installing terminal packages..."

    # Download oh-my-posh and other .zshrc dependencies
    if $IS_MAC
    then
        install_pkg "jandedobbeleer/oh-my-posh/oh-my-posh" "fzf" "zoxide"
    else
        curl -s https://ohmyposh.dev/install.sh | bash -s
        install_pkg "fzf" "zoxide"
    fi

    echo "Packages installed, setting up oh-my-posh config..."
    mkdir ~/.config/ohmyposh
    cp -r "$(dirname -- "$0")/configs/ohmyposh.toml" ~/.config/ohmyposh/config.toml
    oh-my-posh font install JetBrainsMono

    echo "Note: font is installed but you're gonna have to actually apply it to your terminals and editors."
    
    if $IS_MAC
    then
        cp -r "$(dirname -- "$0")/dots/mac.zshrc" ~/.zshrc
    else
        cp -r "$(dirname -- "$0")/dots/linux.zshrc" ~/.zshrc
    fi

    mkdir ~/.config/alacritty
    cp -r "$(dirname -- "$0")/configs/alacritty.toml" ~/.config/alacritty/alacritty.toml

    echo "Terminal setup done :)"
    sleep 2
}

# Installs things like nvm and pnpm.
install_node () {
    echo "Installing nvm..."
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash

    echo "Installing pnpm..."
    curl -fsSL https://get.pnpm.io/install.sh | sh - echo "pnpm is already installed"

    echo "Remember to restart the terminal before using nvm or pnpm. For some reason it refuses to let me source .zshrc. Meh."
    sleep 2
}

# Installs Rust. That's it.
install_rust () {
    echo "Installing Rust..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

    echo "Rust is installed. Since sourcing .zshrc is refusing to work, restart the terminal to start using rustup and cargo."
    sleep 2
}

# KDE-specific things. Currently just applies the catppuccin theme.
setup_kde () {
    if $IS_MAC
    then
        echo "You're on MacOS you silly bitch, you don't have KDE :)"
        sleep 2
    else
        echo "Installing KDE catppuccin theme..."
        git clone --depth=1 https://github.com/catppuccin/kde catppuccin-kde && cd catppuccin-kde || exit
        ./install.sh
        cd ..

        rm -rf catppuccin-kde

        echo "catppuccin theme installed."
        sleep 2
    fi
}

# Just all the general Flatpak apps I always get.
# Flatseal, Firefox, Thunderbird, Spotify, VS Code, Resources, Godot Engine, VLC, Krita, Blender, GitHub Desktop, Proton Pass
install_flatpak_general () {
    echo "General Flatpak applications installed."
    flatpak install flathub org.mozilla.firefox org.mozilla.Thunderbird com.spotify.Client com.visualstudio.code net.nokyan.Resources org.godotengine.Godot org.videolan.VLC org.kde.krita org.blender.Blender io.github.shiftey.Desktop me.proton.Pass
    sleep 2
}

# Similar to the general one, except just game related. Since every system doesn't need these, it's a separate command.
# Steam, ProtonUp-QT, Bolt Launcher (RS3/OSRS), XIVLauncher, Lutris, RetroArch
install_flatpak_games () {
    echo "General Flatpak applications installed."
    flatpak install flathub com.valvesoftware.Steam net.davidotek.pupgui2 com.adamcake.Bolt dev.goats.xivlauncher net.lutris.Lutris org.libretro.RetroArch
    sleep 2
}

# For when I randomly break my dot files. This resets them to my last-known working version.
reset_dots () {
    if $IS_MAC
    then
        cp -r "$(dirname -- "$0")/dots/mac.zshrc" ~/.zshrc
    else
        cp -r "$(dirname -- "$0")/dots/linux.zshrc" ~/.zshrc
    fi

    echo "Done. Now stop breaking things."
    sleep 2
}

# Check if yay is installed, tries to install it otherwise. Only used on Arch Linux
check_yay () {
    if ! command -v yay &> /dev/null
    then
        echo "yay is not installed, installing"
        # Git needs to be installed, so...
        pacman -S --needed git base-devel
        git clone https://aur.archlinux.org/yay.git
        cd yay || exit
        makepkg -si
        cd ..

        # Clean up after ourselves
        rm -rf yay

        echo "yay installed, continuing..."
    fi
}

# Check if Homebrew is installed, tries to install it otherwise. Only used on MacOS
check_brew () {
    if ! command -v brew &> /dev/null
    then
        echo "Homebrew is not installed, installing"
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
}

# Check if zsh is installed, tries to install it otherwise. Only used on Linux
check_zsh () {
    if ! command -v zsh &> /dev/null
    then
        echo "zsh is not installed, installing"
        install_pkg "zsh"
        chsh
        echo "zsh installed, continuing..."
    fi
}

# Check if gum is installed, install it otherwise
check_gum () {
    if ! command -v gum &> /dev/null
    then
        echo "gum is not installed, installing"

        # gum isn't in the DNF repos
        if [ "$DISTRO" == "Fedora Linux" ]
        then
            curl -L https://github.com/charmbracelet/gum/releases/download/v0.14.3/gum-0.14.3-1.x86_64.rpm > gum.rpm
            sudo dnf install gum.rpm
            rm gum.rpm
        else
            install_pkg "gum"
        fi
    fi
}

install_pkg () {
    if $IS_MAC
    then
        brew install "$@"
    else
        case $DISTRO in
            "Arch Linux"|"EndeavourOS")
                yay -S "$@"
                ;;
            "Fedora Linux")
                sudo dnf install "$@"
                ;;
            "openSUSE Tumbleweed"|"openSUSE Leap"|"Aeon")
                sudo zypper install "$@"
                ;;
            "Debian GNU/Linux"|"Linux Mint")
                sudo apt install "$@"
                ;;
        esac
    fi
}

get_distro () {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        DISTRO=$NAME
    fi
}

init
