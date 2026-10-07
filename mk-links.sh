#!/usr/bin/env bash
DOTFILES_DIR=$1
ln -s "$DOTFILES_DIR/wezterm" ~/.config/wezterm
ln -s "$DOTFILES_DIR/hammerspoon" ~/.hammerspoon
ln -s "$DOTFILES_DIR/.xonshrc" ~/.xonshrc
ln -s "$DOTFILES_DIR/.tmux.conf" ~/.tmux.conf

mkdir -p ~/.config/fish
if [ -e ~/.config/fish/config.fish ] && [ ! -L ~/.config/fish/config.fish ]; then
    mv ~/.config/fish/config.fish ~/.config/fish/config.local.fish
fi
ln -sfn "$DOTFILES_DIR/fish/config.fish" ~/.config/fish/config.fish
