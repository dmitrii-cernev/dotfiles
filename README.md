VS Code Vim configuration (ported from IdeaVim): [setup and mappings](vscode/README.md).

## Minimal Vim (alternative configuration)

`vim-minimal/.vimrc` reproduces the screenshot's plugin-free Neovim setup in Vim:
Slate colors, relative line numbers, built-in netrw, recursive file completion,
buffer/window shortcuts, and ripgrep search. No plugin installation required.

Try it without replacing your current config (run from this repository):

```sh
vim -u "$PWD/vim-minimal/.vimrc"
```

To use it as your default, unstow the existing Vim package first:

```sh
stow -D -t "$HOME" vim
stow -t "$HOME" vim-minimal
```

If `~/.vimrc` is an unmanaged file, back it up and move it aside before stowing.
Do not stow `vim` and `vim-minimal` together. The existing setup scripts still
select `vim` and install its plugins; they do not select this alternative.
To switch back, unstow `vim-minimal` and stow `vim`.

Leader is **Space**:

| Keys | Action |
| --- | --- |
| `Space e` / `Space E` | Explorer at working directory / current file's directory |
| `Space fo` / `Space .` | Find file (type a name, use Tab to complete) |
| `Space fr` / `Space br` | List buffers and prompt for one |
| `Space /` | Project grep (type a pattern and press Enter) |
| `Space q` | Open quickfix search results |
| `Ctrl-h/j/k/l` | Move between windows |
| `Space bn/bp/bb/bl/bq` | Next / previous / alternate / list / delete buffer |
| `Space wv/ws/wh` | Vertical / horizontal / horizontal split |
| `Space ww/wq/wo` | Next window / close window / only window |
| `Ctrl-s` | Save (normal mode) |
| `Space hrr` | Reload configuration |
| `gd` | Recursive text search for word under cursor; open quickfix |
| `Ctrl-=` / `Ctrl--` | GUI font size up / down |

Install `ripgrep` for smart-case project grep; otherwise Vim's default grep is
retained. Clipboard integration requires a clipboard-enabled Vim build. Consolas
16 and font resizing apply only to GUI Vim and require that font to be installed;
terminal fonts are controlled by your terminal. If Ctrl-s freezes your terminal,
run `stty -ixon` in your shell to disable terminal flow control.

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
