# Managed by GNU Stow from the devbox controller repository.
# Keep secrets out of this file; personal configuration belongs in the tracked
# dotfile packages and machine-specific values belong in ignored local files.

export ZSH="$HOME/.local/share/oh-my-zsh"
ZSH_THEME=""

if [[ -r "$ZSH/oh-my-zsh.sh" ]]; then
  source "$ZSH/oh-my-zsh.sh"
fi

if [[ -r "$HOME/.local/share/powerlevel10k/powerlevel10k.zsh-theme" ]]; then
  source "$HOME/.local/share/powerlevel10k/powerlevel10k.zsh-theme"
fi

if [[ -r "$HOME/.p10k.zsh" ]]; then
  source "$HOME/.p10k.zsh"
fi
