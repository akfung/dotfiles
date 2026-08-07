#!/bin/bash
set -e

# setup_machine.sh - Bootstrap neovim with LazyVim on Linux
# Installs: neovim, lazygit, ripgrep
# Sets up: LazyVim with custom config and keybindings

echo "🚀 Starting neovim setup..."

# Detect Linux distribution
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
else
    echo "❌ Cannot detect Linux distribution"
    exit 1
fi

# Install dependencies based on distro
case "$OS" in
    ubuntu|debian)
        echo "📦 Detected Debian/Ubuntu, installing packages..."
        sudo apt-get update
        sudo apt-get install -y \
            neovim \
            git \
            curl \
            build-essential \
            tmux
        ;;
    fedora)
        echo "📦 Detected Fedora, installing packages..."
        sudo dnf install -y \
            neovim \
            git \
            curl \
            gcc \
            make \
            tmux
        ;;
    arch)
        echo "📦 Detected Arch Linux, installing packages..."
        sudo pacman -S --noconfirm \
            neovim \
            git \
            curl \
            base-devel \
            tmux
        ;;
    *)
        echo "⚠️  Unsupported distribution: $OS"
        echo "Please install neovim, git, and curl manually"
        exit 1
        ;;
esac

# Create config directory
echo "📁 Creating config directory..."
mkdir -p ~/.config/nvim
mkdir -p ~/.config/nvim/lua/config
mkdir -p ~/.config/nvim/lua/plugins

# Install lazygit
echo "🔧 Installing lazygit..."
LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
curl -Lo /tmp/lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
tar xf /tmp/lazygit.tar.gz -C /tmp lazygit
sudo install /tmp/lazygit /usr/local/bin
rm /tmp/lazygit /tmp/lazygit.tar.gz
echo "✅ lazygit installed: $(lazygit --version)"

# Install ripgrep
echo "🔧 Installing ripgrep..."
case "$OS" in
    ubuntu|debian)
        sudo apt-get install -y ripgrep
        ;;
    fedora)
        sudo dnf install -y ripgrep
        ;;
    arch)
        sudo pacman -S --noconfirm ripgrep
        ;;
esac
echo "✅ ripgrep installed: $(rg --version | head -1)"

# Verify neovim installation
echo "🔍 Verifying neovim installation..."
NVIM_VERSION=$(nvim --version | head -1)
echo "✅ neovim installed: $NVIM_VERSION"

# Copy neovim config
echo "📋 Setting up neovim config..."
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ ! "$SCRIPT_DIR" = ~/.config/nvim ]; then
    echo "📋 Copying config from $SCRIPT_DIR to ~/.config/nvim..."
    cp -r "$SCRIPT_DIR"/* ~/.config/nvim/
fi

# Ensure config files exist
if [ ! -f ~/.config/nvim/init.lua ]; then
    cat > ~/.config/nvim/init.lua << 'EOF'
-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")
vim.opt.clipboard = "unnamed"
vim.g.autoformat = false
EOF
fi

if [ ! -f ~/.config/nvim/lua/config/lazy.lua ]; then
    cat > ~/.config/nvim/lua/config/lazy.lua << 'EOF'
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  spec = {
    -- add LazyVim and import its plugins
    { "LazyVim/LazyVim", import = "lazyvim.plugins" },
    -- import/override with your plugins
    { import = "plugins" },
  },
  defaults = {
    lazy = false,
    version = false,
  },
  install = { colorscheme = { "tokyonight", "habamax" } },
  checker = {
    enabled = true,
    notify = false,
  },
  performance = {
    rtp = {
      disabled_plugins = {
        "gzip",
        "tarPlugin",
        "tohtml",
        "tutor",
        "zipPlugin",
      },
    },
  },
})
EOF
fi

if [ ! -f ~/.config/nvim/lua/config/keymaps.lua ]; then
    cat > ~/.config/nvim/lua/config/keymaps.lua << 'EOF'
-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
vim.keymap.set({ "v", "n" }, "<C-d>", "<C-d>zz")
vim.keymap.set({ "v", "n" }, "<C-u>", "<C-u>zz")
vim.keymap.set({ "n", "v" }, "<leader>yf", function()
  local filepath = vim.fn.expand("%:p")
  vim.fn.setreg("+", filepath)
  vim.notify("Copied full path: " .. filepath, vim.log.levels.INFO)
end, { desc = "Yank full file path" })
vim.keymap.set({ "n", "v" }, "<leader>yr", function()
  local filepath = vim.fn.expand("%")
  vim.fn.setreg("+", filepath)
  vim.notify("Copied relative path: " .. filepath, vim.log.levels.INFO)
end, { desc = "Yank relative file path" })
EOF
fi

if [ ! -f ~/.config/nvim/lua/config/options.lua ]; then
    cat > ~/.config/nvim/lua/config/options.lua << 'EOF'
-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here
EOF
fi

if [ ! -f ~/.config/nvim/lua/config/autocmds.lua ]; then
    cat > ~/.config/nvim/lua/config/autocmds.lua << 'EOF'
-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
-- Add any additional autocmds here
EOF
fi

# Copy lazy-lock.json if it exists
if [ -f "$SCRIPT_DIR/lazy-lock.json" ]; then
    cp "$SCRIPT_DIR/lazy-lock.json" ~/.config/nvim/
    echo "📌 Copied lazy-lock.json for reproducible plugin versions"
fi

# Bootstrap lazy.nvim by running neovim
echo "🚀 Bootstrapping LazyVim (this may take a minute)..."
nvim --headless "+Lazy! sync" +qa

# Setup tmux config
echo "⚙️  Setting up tmux config..."
mkdir -p ~/.config
cat > ~/.tmux.conf << 'EOF'
# Change prefix to backtick
unbind C-b
set-option -g prefix `
bind-key ` send-prefix

# Auto-split on new session
set-hook -g after-new-session "split-window -h; split-window -v"

# Vi mode for copy and paste
setw -g mode-keys vi

# Vi-style pane navigation
bind-key h select-pane -L
bind-key j select-pane -D
bind-key k select-pane -U
bind-key l select-pane -R

# Vi-style pane resizing
bind-key -r H resize-pane -L 5
bind-key -r J resize-pane -D 5
bind-key -r K resize-pane -U 5
bind-key -r L resize-pane -R 5

# Window management
bind-key c new-window -c "#{pane_current_path}"
bind-key n next-window
bind-key p previous-window
bind-key u copy-mode

# Mouse support
set -g mouse on

# Enable status bar
set -g status on
set -g status-interval 1
EOF
echo "✅ tmux config created: ~/.tmux.conf"

echo ""
echo "✅ Setup complete!"
echo ""
echo "Summary:"
echo "  ✓ neovim: $NVIM_VERSION"
echo "  ✓ tmux: $(tmux -V)"
echo "  ✓ lazygit: $(lazygit --version)"
echo "  ✓ ripgrep: $(rg --version | head -1)"
echo "  ✓ LazyVim config: ~/.config/nvim"
echo "  ✓ Tmux config: ~/.tmux.conf"
echo ""
echo "Next steps:"
echo "  1. Open neovim: nvim"
echo "  2. Start tmux: tmux"
echo "  3. In neovim, run :checkhealth to verify setup"
echo ""
echo "Neovim keybindings:"
echo "  • <C-d>zz / <C-u>zz - Center screen on half-page navigation"
echo "  • <leader>yf - Yank full file path"
echo "  • <leader>yr - Yank relative file path"
echo ""
echo "Tmux keybindings (prefix: backtick):"
echo "  • \` + hjkl - Navigate between panes (vi-style)"
echo "  • \` + HJKL - Resize panes (vi-style)"
echo "  • \` + | - Split window horizontally"
echo "  • \` + - - Split window vertically"
echo "  • \` + c - Create new window"
echo "  • \` + n/p - Next/previous window"
echo "  • \` + r - Reload config"
