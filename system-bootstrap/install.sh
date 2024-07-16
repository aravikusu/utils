#!/bin/bash

IS_MAC=false

init() {
    case "$(uname)" in
        "Linux") 
            ;;
        "Darwin")
            $IS_MAC=true
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

        GIT="Install git"; TERMINAL="Configure terminal"; EXIT="Exit"
        ACTIONS=$(gum choose --limit 1 "$GIT" "$TERMINAL" "$EXIT")

        case "$ACTIONS" in
            "$GIT")
                install_git
                ;;
            "$TERMINAL")
                setup_terminal
                ;;
            "$EXIT")
                echo "Aight, see ya later."
                break
        esac
    done
}

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
    cp -r "$(dirname -- "$0")/omp-conf.toml" ~/.config/ohmyposh/config.toml
    oh-my-posh font install JetBrainsMono
    
    if $IS_MAC
    then
        cp -r "$(dirname -- "$0")/zshrc/mac.zshrc" ~/.zshrc
    else
        cp -r "$(dirname -- "$0")/zshrc/linux.zshrc" ~/.zshrc
    fi

    echo "Terminal setup done :)"
    sleep 1
}

# Check if yay is installed, tries to install it otherwise. Only used on Linux
check_yay () {
    if ! command -v yay &> /dev/null
    then
        echo "yay is not installed, installing"
        pacman -S --needed git base-devel
        git clone https://aur.archlinux.org/yay.git
        cd yay
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
    yay -S $@
}

# General utility for installing things on MacOS
mac_install () {
    brew install $@
}

init