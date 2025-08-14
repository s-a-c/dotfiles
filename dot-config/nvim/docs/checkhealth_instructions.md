# How to Capture Neovim Checkhealth Output

## Method 1: Using `:redir` command (recommended)
```vim
:redir > checkhealth_output.txt
:checkhealth
:redir END
:wq
```

## Method 2: Using `:write` command
```vim
:checkhealth
:write checkhealth_output.txt
:q
```

## Method 3: One-liner approach
```bash
nvim -c "redir > checkhealth_output.txt | checkhealth | redir END | wq"
```

## Step-by-step instructions:

1. Open Neovim in your nvim config directory:
   ```bash
   cd /Users/s-a-c/dotfiles/dot-config/nvim
   nvim
   ```

2. Once in Neovim, run these commands in sequence:
   ```vim
   :redir > checkhealth_output.txt
   :checkhealth
   :redir END
   :wq
   ```

The `:redir` command redirects all command output to the specified file, `:checkhealth` runs the health checks, `:redir END` stops the redirection, and `:wq` saves and quits.

This will create a file called `checkhealth_output.txt` in your current directory with the complete checkhealth output.
