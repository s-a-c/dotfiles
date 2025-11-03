# LM Studio CLI Configuration
# Integration with LM Studio command-line interface

# Add LM Studio binary to PATH if it exists
if [[ -d ~/.lmstudio/bin ]]; then
  export PATH="$PATH:$HOME/.lmstudio/bin"
fi
