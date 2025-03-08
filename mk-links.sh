#!/usr/bin/env bash
DOTFILES_DIR=$1
ln -s "$DOTFILES_DIR/wezterm" ~/.config/wezterm
ln -s "$DOTFILES_DIR/hammerspoon" ~/.hammerspoon
ln -s "$DOTFILES_DIR/.xonshrc" ~/.xonshrc
ln -s "$DOTFILES_DIR/.tmux.conf" ~/.tmux.conf
