#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls --color=auto'
alias grep='grep --color=auto'
PS1='[\u@\h \W]\$ '

export EDITOR=micro
eval "$(starship init bash)"


fo() {
  local file
  file=$(find "${1:-.}" -type f | fzf --preview 'bat --style=numbers --color=always {} 2>/dev/null || cat {}')
  [ -n "$file" ] && ${EDITOR:-micro} "$file"
}


alias ll='eza -lah --icons --git --group-directories-first'
alias ii='sudo pacman -S --needed'
alias rr='sudo pacman -Rns'
alias disk='ncdu /'
alias tree='eza -a --icons --tree'

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/home/bita/miniconda3/bin/conda' 'shell.bash' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/home/bita/miniconda3/etc/profile.d/conda.sh" ]; then
        . "/home/bita/miniconda3/etc/profile.d/conda.sh"
    else
        export PATH="/home/bita/miniconda3/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<

