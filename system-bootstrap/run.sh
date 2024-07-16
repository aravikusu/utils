#!/bin/bash

IS_MAC=false

init () {
    case "$(uname)" in
        "Linux") 
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
        check_yay
        check_zsh
    fi

    # Now we have to install gum
    check_gum

    gum_ui
}

gum_ui () {
    while :
    do
        clear
        gum style --border normal --margin "1" --padding "1 2" --border-foreground 212 "$(gum style --foreground 212 'aravix')'s system bootstrapper"

        GIT="Install git"; TERMINAL="Configure terminal"; EXIT="Exit"; NODE="Install Node"; RUST="Install Rust"; KDE="Configure KDE"; DOTS="Reset dotfiles pls"
        ACTIONS=$(gum choose --limit 1 "$GIT" "$TERMINAL" "$KDE" "$NODE" "$RUST" "$DOTS" "$EXIT")

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
        if $IS_MAC
        then
            mac_install "git"
        else
            linux_install "git"
        fi
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
        mac_install "jandedobbeleer/oh-my-posh/oh-my-posh" "fzf" "zoxide"
    else
        linux_install "oh-my-posh" "fzf" "zoxide"
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

# Check if yay is installed, tries to install it otherwise. Only used on Linux
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
        linux_install "zsh"
        chsh
        echo "zsh installed, continuing..."
    fi
}

# Check if gum is installed, install it otherwise
check_gum () {
    if ! command -v gum &> /dev/null
    then
        echo "gum is not installed, installing"

        if $IS_MAC
        then
            mac_install "gum"
        else
            linux_install "gum"
        fi
    fi
}

# General utility for installing things on Arch Linux
linux_install () {
    yay -S "$@"
}

# General utility for installing things on MacOS
mac_install () {
    brew install "$@"
}

init