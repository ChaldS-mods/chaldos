# ChaldOS Live — root .bashrc

# Colorize
alias ls='ls --color=auto'
alias ll='ls -la'
alias la='ls -A'
alias grep='grep --color=auto'

# ChaldOS shortcuts
alias install='~/chaldos/install-chaldos.sh'
alias chaldos-mascot='~/chaldos/mascot.sh'

# Package management
alias update='pacman -Syu'
alias search='pacman -Ss'

# Info
alias sysinfo='fastfetch'

# PS1
PS1='\[\e[1;31m\][ChaldOS]#\[\e[0m\] '

[[ -f /etc/motd ]] && cat /etc/motd
