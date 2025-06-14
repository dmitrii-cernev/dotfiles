To setup on new environemnt:
1. Make script executable:
```
chmod +x setup-environment.sh
```
2. Run in with sudo:
```
sudo ./setup-environment.sh
```
It will automatically install all necessary services in new env.
After runing script:
1. For tmux: Start tmux and press prefix + I (usually Ctrl-b then Shift-i) to install plugins
2. For Vim/Neovim: Run :PlugInstall to install plugins defined in your vimrc
