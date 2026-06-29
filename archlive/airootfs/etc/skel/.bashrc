# ChaldOS Live Environment — ~/.bashrc

# Colorize
alias ls='ls --color=auto'
alias ll='ls -la'
alias la='ls -A'
alias grep='grep --color=auto'
alias diff='diff --color=auto'
alias ip='ip -color=auto'

# ChaldOS shortcuts
alias chaldos-install='sudo /root/chaldos/install-chaldos.sh'
alias chaldos-mascot='/root/chaldos/mascot.sh'

# Package management (on live system, for debugging)
alias update='sudo pacman -Syu'
alias install='sudo pacman -S'
alias remove='sudo pacman -Rns'
alias search='pacman -Ss'

# Info
alias sysinfo='fastfetch'
alias neofetch='fastfetch'

# PS1 with ChaldOS branding
PS1='\[\e[35m\][ChaldOS]\[\e[0m\] \[\e[34m\]\u\[\e[0m\]@\[\e[32m\]\h\[\e[0m\] \[\e[33m\]\w\[\e[0m\]\$ '

# Welcome message on first login (not in SSH)
if [[ -z "$SSH_CONNECTION" ]] && [[ -z "$SSH_CLIENT" ]] && [[ -z "$SSH_TTY" ]]; then
    [[ -f /etc/motd ]] && cat /etc/motd
fi
