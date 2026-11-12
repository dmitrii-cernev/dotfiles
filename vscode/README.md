# VS Code + Vim

Port of `ideavimrc/.ideavimrc` for **VSCodeVim** (`vscodevim.vim`), not
VSCode Neovim. Space is the leader. No changes to the IdeaVim configuration.

## Install

```sh
code --install-extension vscodevim.vim
```

Run **Preferences: Open User Settings (JSON)** from the Command Palette and
merge `.config/Code/User/settings.json` from this directory into that file.
Preserve your other settings; if you already have `vim.*KeyBindings*` arrays,
merge their entries rather than adding duplicate JSON keys. Disable other Vim
emulators and conflicting keymap extensions (such as IntelliJ IDEA Keybindings).

The directory also follows this repository's GNU Stow layout for Linux VS Code:

```sh
# Preview only; resolve existing settings conflicts before stowing.
stow --simulate --verbose -d ~/dotfiles -t ~ vscode
stow -d ~/dotfiles -t ~ vscode
```

Use Stow only if you want this file to manage your complete user settings.
`stow-dotfiles.sh` does not automatically deploy this package, so it won't replace
your existing VS Code preferences. On macOS, Windows, VSCodium, or a custom VS Code
profile, merge through the Settings command instead of using this Linux path.

Settings apply automatically. The reload mappings below reload the entire window.

## Main mappings (Normal mode)

`Space` below means the leader, not a literal word.

| Keys | Action |
| --- | --- |
| `Space Space`, `Space ff`, `Space .` | Quick Open files |
| `Space /`, `Space sg` | Search project |
| `Space sa` | Command Palette |
| `Space e`, `Space E` | Explorer |
| `H`, `L` | Previous / next editor in group |
| `Space ,`, `Space bb`, `Space fb` | Open editor picker |
| `Space bd`, `Space bo`, `Space br` | Close / close others in group / reopen |
| `Ctrl-h/j/k/l` | Focus editor group left / down / up / right |
| `Space wv`, `Space ws`, `Space wh` | Split right / right / down (matches IdeaVim) |
| `Space ww`, `Space wo`, `Space wq` | Next group / join groups and hide panels / close |
| `gd`, `gD`, `gi` / `gI`, `gr`, `K` | Definition / type / implementation / references / hover |
| `Space ca`, `Space cr`, `Space cf`, `Space co` | Quick fix / rename / format / organize imports |
| `Space cs`, `Space ss`, `Space sS` | File symbols / file symbols / workspace symbols |
| `Space cR`, `Space cg` | Refactor / source actions |
| `[d`, `]d`, `Space cd`, `Ctrl-w d` | Previous / next problem / hover diagnostic |
| `Space xx`, `Space xm`, `Space sd` | Problems panel |
| `gt` | Related test (requires a supporting test provider) |
| `Space tt`, `Space td` | Run / debug tests in current file |
| `Space tm`, `Space tM`, `Space tr`, `Space ts` | Run / debug test at cursor / rerun / cancel |
| `Space db`, `Space dd`, `Space dc` | Breakpoint / start debug / continue |
| `Space di`, `Space do`, `Space dO` | Step into / out / over |
| `Space rr`, `Space rm` | Run without debugging / select debug configuration and start |
| `Space gg`, `Space gb`, `Space gB`, `Space gh` | Source Control / checkout branch / inline blame / Timeline |
| `Space gc`, `Space gn`, `Space gp`, `Space gP`, `Space gm` | Commit / create branch / push / pull / merge |
| `[h`, `]h`, `[H`, `]H` | Previous / next change; uppercase for diff editors |
| `Space ft`, `Ctrl-/` | Toggle terminal |
| `Space fn` | New untitled file |
| `Ctrl-o`, `Ctrl-i` | VS Code navigation back / forward |
| `Space vr`, `Space hrr` | Reload VS Code window |
| `Space uit` | Keyboard Shortcuts editor |
| `Space aa` | Chat (requires a configured chat provider) |

Also ports centered paging/search, `Q` → `gq`, Escape to clear search highlights,
`vv` → line selection, `vag` → whole-file selection, `[Space` / `]Space` to insert
blank lines, and visual `<` / `>` to retain selection. Visual `Space sw` opens
project search with the selected text. VSCodeVim provides `gc` / `gcc` commenting;
surround, sneak, and yank highlighting are enabled in the settings.

## Differences and requirements

- Code navigation, formatting, imports, source actions, tests, and debugging need
  the corresponding language extensions and project configuration. For Java,
  **Extension Pack for Java** (`vscjava.vscode-java-pack`) is a useful starting point.
- Quick Open replaces Search Everywhere; `Space fr` opens recent workspaces, not
  IntelliJ's recent-files popup. Use `Space fb` for open files.
- `Space wo` joins groups rather than reproducing IntelliJ's exact layout action.
  `Space bd` closes an editor, not a Vim buffer. `Space fn` creates an untitled file.
- `Space cd` keeps the final mapping in the source: diagnostics, not safe delete.
  `Space cg` lists available source actions; constructors/getters depend on the
  language extension. Safe delete has no generic equivalent.
- Test class actions become current-file actions. `Space dd` starts the selected
  launch configuration, not necessarily the test class. `Space ts` cancels tests;
  it does not stop an unrelated debug session.
- Git mappings use VS Code's built-in Git extension. Blame requires a recent
  VS Code version; Timeline is the nearest built-in file-history view.
  Push, pull, commit, and merge perform real Git operations.
- `]n` / `[n` move between editor find matches, not arbitrary tool-window results.
- IntelliJ-only options, extra text-object plugins (`mini-ai`, argument/function/
  entire-file objects), method/class jumps, TODO tool window, and Scala/SBT actions
  are not ported. Standard VSCodeVim motions/text objects remain available.
- Mappings apply while the editor has focus. Once focus enters Explorer, search,
  or the terminal, VS Code's native shortcuts apply. Use the usual terminal toggle
  shortcut to return. Some keyboard layouts do not deliver `Ctrl-/`; `Space ft`
  is the fallback. `Ctrl-f` is deliberately left to VS Code's Find command.

Validation: JSON structure, duplicate mappings, Vim setting names, and command
identifiers were checked against the locally installed VSCodeVim/VS Code. GUI
behavior and language-provider actions still need a smoke test in your project.
