zstyle ':completion:*' accept-exact '*(N)'
zstyle :omz:plugins:ssh-agent agent-forwarding yes
zstyle :omz:plugins:ssh-agent autoload yes
zstyle :omz:plugins:nvm autoload yes
zstyle ':completion:*' cache-path /Users/s-a-c/.cache/zsh
zstyle :omz:plugins:ssh-agent helper ''
zstyle :omz:plugins:ssh-agent identities id_ed25519
zstyle :omz:plugins:ssh-agent lazy yes
zstyle :omz:plugins:nvm lazy yes
zstyle :omz:plugins:nvm lazy-cmd node npm npx yarn pnpm eslint prettier typescript tsc vue-cli create-react-app next gatsby nuxt jest vitest cypress webpack vite rollup serverless sls vercel netlify
zstyle :omz:plugins:ssh-agent lifetime 0
zstyle -e ':completion:*:default' list-colors 'reply=("${PREFIX:+=(#bi)($PREFIX:t)*==34=34}:${(s.:.)LS_COLORS}")'
zstyle :omz:plugins:ssh-agent quiet yes
zstyle ':completion:*' rehash true
zstyle :omz:plugins:nvm silent-autoload yes
zstyle :omz:plugins:ssh-agent ssh-add-args --apple-use-keychain
zstyle ':completion:*' use-cache on
