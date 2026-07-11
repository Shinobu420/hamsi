# Hamsi

Hamsi (named after the fast and agile Black Sea anchovy) is an LLM-based autocompletion tool for the **Fish shell**. It intercepts your key presses to request context-aware command completions from a locally-hosted **Ollama** LLM based on your recent command history and what you have currently typed.

Currently, Hamsi is written in **pure Fish shell script**, making it easy to install and inspect, with no heavy runtimes required.

> [!NOTE]
> **Future Goal**: While Hamsi starts as a pure Fish shell plugin, the long-term goal is to migrate the backend to a **Go or Rust based daemon**. This will allow for asynchronous execution, lower latency, local request caching, and complex context merging.

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
- **jq** (for fast, robust JSON construction and parsing)
- **curl**
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

Hamsi can be configured by creating a configuration file at `~/.config/hamsi/config.fish`. 

Here is a template with all default settings:

```fish
# ~/.config/hamsi/config.fish

# 1. Choose your locally hosted Ollama model
# Recommended fast model: qwen3.5:9b (installed) or qwen2.5-coder:1.5b
set -g hamsi_model "qwen3.5:9b"

# 2. Set the Ollama API endpoint
set -g hamsi_api_url "http://localhost:11434/api/generate"

# 3. Specify how many past commands to send for context
set -g hamsi_history_limit 5

# 4. Configure keybindings
# Trigger completion (default: Ctrl+O)
set -g hamsi_keybinding \co

# Accept suggestion (default: Ctrl+Y)
set -g hamsi_accept_keybinding \cy
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
- [ ] Go/Rust backend daemon:
  - Asynchronous background worker (no shell stuttering).
  - Shell-agnostic integration.
  - SQLite cache for past suggestions.
  - Better context parsing (detecting project directories, git branches).
- [ ] Integration with GPT/Claude/Gemini
- [ ] Typo correction
---

## License

This project is licensed under the MIT License.
