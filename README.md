# Hamsi

Hamsi (named after the fast and agile Black Sea anchovy) is an LLM-based autocompletion tool for the **Fish shell**. It intercepts your key presses to request context-aware command completions from a locally-hosted **Ollama** LLM based on your recent command history and what you have currently typed.

Hamsi uses a hybrid architecture: a lightweight **Fish shell frontend** handles terminal inputs, keybindings, and ghost text rendering, while a compiled **Rust backend** handles asynchronous Ollama API requests, ensuring zero stuttering or blocking in the shell UI.

---

## Features

- **Context-Aware Suggestions**: Sends your last 5 shell commands and your current input buffer to Ollama.
- **Inline Ghost Preview**: Displays the suggested text directly on your command line after your cursor.
- **Safe & Non-Intrusive**: 
  - Accept suggestions instantly with a keybinding (default: `Ctrl+Y`).
  - Automatically discards the suggestion if you press `Enter` (runs your original command) or `Backspace` (returns to editing).
  - Press the trigger key (default: `Ctrl+O`) to toggle/discard the suggestion.
- **Pure Fish**: No compilation, no external runtimes except `curl` and `jq`.

---

## Requirements

- **Fish shell** (v3.0.0 or higher)
- **Ollama** running locally (e.g. `http://localhost:11434`)
- **Rust / Cargo** (to build the compiled backend during installation)
- **qwen2.5-coder:1.5b** (recommended)
---

## Installation

### Option 1: Manual Installation

To install Hamsi manually, clone this repository and copy the files to your Fish configuration directory:

```bash
# Clone the repository
git clone https://github.com/yourusername/hamsi.git
cd hamsi

# Copy configuration and functions
mkdir -p ~/.config/fish/conf.d/
mkdir -p ~/.config/fish/functions/
cp conf.d/hamsi.fish ~/.config/fish/conf.d/
cp functions/hamsi_*.fish ~/.config/fish/functions/
```

Restart your Fish shell or run `source ~/.config/fish/conf.d/hamsi.fish` to activate.

### Option 2: Using Fisher (Plugin Manager)

Add Hamsi to your `~/.config/fish/fish_plugins` file or install directly:

```bash
fisher install yourusername/hamsi
```

---

## Configuration

You can configure Hamsi interactively by running the configuration script:
```bash
./configure_model.fish
```
This script lists recommended models, checks if they are installed in Ollama, pulls them if missing, and updates your config.

Alternatively, you can manually configure Hamsi by editing the configuration file at `~/.config/hamsi/hamsi.conf`. 

Here is a template with all default settings:

```ini
# ~/.config/hamsi/hamsi.conf

# 1. Choose your locally hosted Ollama model
# Recommended fast model: qwen2.5-coder:1.5b
model = qwen2.5-coder:1.5b

# 2. Set the Ollama API endpoint
api_url = http://localhost:11434/api/generate

# 3. Specify how many past commands to send for context
history_limit = 5

# 4. Configure keybindings
# Trigger completion (default: Ctrl+O)
keybinding = \co

# Accept suggestion (default: Ctrl+Y)
accept_keybinding = \cy
```



---

## How to Use

1. Start typing a command in your shell, e.g., `git comm`.
2. Press `Ctrl+O` (or your configured trigger key).
3. A `[hamsi thinking...]` indicator will appear, and then the suggestion (e.g., `it -m "initial commit"`) will be shown after your cursor.
4. **Accept** the suggestion: Press `Ctrl+Y` (or your configured accept key). The cursor moves to the end of the text.
5. **Discard/Revert**: 
   - Press `Ctrl+O` again (or `Ctrl+G` / `Backspace`). The suggestion disappears.
   - Or simply press `Enter` to run the command you originally typed without the suggestion.

---

## Roadmap

- [x] Pure Fish prototype.
- [x] Rust asynchronous backend.
- [ ] SQLite Local Cache.
- [ ] Daemon Integration.
- [ ] Integration with GPT/Claude/Gemini.
- [ ] Typo correction.
---

## License

This project is licensed under the MIT License.
