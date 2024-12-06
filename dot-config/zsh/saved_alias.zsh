alias -- -='cd -'
alias ..='cd ..'
alias ...='cd ../..'
alias -g ....=../../..
alias -g .....=../../../..
alias -g ......=../../../../..
alias 1='cd -1'
alias 2='cd -2'
alias 3='cd -3'
alias 4='cd -4'
alias 5='cd -5'
alias 6='cd -6'
alias 7='cd -7'
alias 8='cd -8'
alias 9='cd -9'
alias :q=exit
alias -g @NDL='~/Downloads/*(.om[1])'
alias DELETE='lwp-request -m '\''DELETE'\'
alias GET='lwp-request -m '\''GET'\'
alias HEAD='lwp-request -m '\''HEAD'\'
alias OPTIONS='lwp-request -m '\''OPTIONS'\'
alias POST='lwp-request -m '\''POST'\'
alias PUT='lwp-request -m '\''PUT'\'
alias TRACE='lwp-request -m '\''TRACE'\'
alias _='sudo '
alias airport=/System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport
alias annotate='git annotate'
alias artisan='php artisan'
alias asroot='sudo $(fc -ln -1)'
alias ba='brew autoremove'
alias bci='brew info --cask'
alias bcin='brew install --cask'
alias bcl='brew list --cask'
alias bcn='brew cleanup'
alias bco='brew outdated --cask'
alias bcrin='brew reinstall --cask'
alias bcubc='brew upgrade --cask && brew cleanup'
alias bcubo='brew update && brew outdated --cask'
alias bcup='brew upgrade --cask'
alias bfu='brew upgrade --formula'
alias bi='brew install'
alias bl='brew list'
alias blame='git blame'
alias bo='brew outdated'
alias bob='php artisan bob::build'
alias brewp='brew pin'
alias brewsp='brew list --pinned'
alias bsl='brew services list'
alias bsoff='brew services stop'
alias bsoffa='bsoff --all'
alias bson='brew services start'
alias bsona='bson --all'
alias bsr='brew services run'
alias bsra='bsr --all'
alias bu='brew update'
alias bubo='brew update && brew outdated'
alias bubu='bubo && bup'
alias bubug='bubo && bugbc'
alias bugbc='brew upgrade --greedy && brew cleanup'
alias bup='brew upgrade'
alias buz='brew uninstall --zap'
alias c=composer
alias cadd='code -a'
alias ccat=colorize_cat
alias ccp='composer create-project'
alias cd=__enhancd::cd
alias cdiff='code -d'
alias cdo='composer dump-autoload -o'
alias cdu='composer dump-autoload'
alias cget='curl -s https://getcomposer.org/installer | php'
alias cgr='composer global require'
alias cgrm='composer global remove'
alias cgu='composer global update'
alias chgext=change-extension
alias ci='composer install'
alias cleanxmlclip=clean-xml-clip
alias cless=colorize_less
alias cnew='code -n'
alias co='composer outdated'
alias cod='composer outdated --direct'
alias code-install='code --install-extension'
alias code-uninstall='code --uninstall-extension'
alias cr='composer require'
alias crm='composer remove'
alias cs='composer show'
alias csu='composer self-update'
alias cu='composer update'
alias cuh='composer update --working-dir=$(composer config -g home)'
alias d=desk
alias d.='desk .'
alias d..='desk ..'
alias da='dotnet add'
alias dat='docker attach'
alias date_locale='date +%c'
alias db='dotnet build'
alias dbu='docker build'
alias dc='deno compile'
alias dca='deno cache'
alias dco='docker commit'
alias dde='docker export'
alias ddi='docker diff'
alias dfmt='deno fmt'
alias dh='deno help'
alias dhi='docker history'
alias dicepass='perl -MCrypt::XkcdPassword -e '\''print Crypt::XkcdPassword->make_password($_)'\'
alias dim='docker images'
alias dimp='docker import'
alias din='docker info'
alias dins='docker insert'
alias dinsp='docker inspect'
alias disablehistory='function zshaddhistory() {    return 1 }'
alias dk='docker kill'
alias dli='deno lint'
alias dlogin='docker login'
alias dlogs='docker logs'
alias dmesg='sudo dmesg'
alias dn='dotnet new'
alias dng='dotnet nuget'
alias dp='dotnet pack'
alias dport='docker port'
alias dps='docker ps'
alias dpull='docker pull'
alias dpush='docker push'
alias dr='dotnet run'
alias drA='deno run -A'
alias dre='docker restart'
alias drm='docker rm'
alias drmi='docker rmi'
alias drn='deno run'
alias dru='deno run --unstable'
alias drun='docker run'
alias drw='deno run --watch'
alias ds='dotnet sln'
alias dse='docker search'
alias dstart='docker start'
alias dstop='docker stop'
alias dt='dotnet test'
alias dtag='docker tag'
alias dtop='docker top'
alias dts='deno test'
alias dup='deno upgrade'
alias dversion='docker version'
alias dw='dotnet watch'
alias dwait='docker wait'
alias dwr='dotnet watch run'
alias dwt='dotnet watch test'
alias e=emacs
alias edit='/Users/s-a-c/.local/share/bob/nvim-bin/nvim $(eval ${$(fc -l -1)[2,-1]} -l)'
alias eeval='/Users/s-a-c/.config/zsh/.zgenom/ohmyzsh/ohmyzsh/___/plugins/emacs/emacsclient.sh --eval'
alias eframe='emacsclient --alternate-editor="" --create-frame'
alias egrep='grep -E'
alias eject='diskutil eject'
alias emacs='/Users/s-a-c/.config/zsh/.zgenom/ohmyzsh/ohmyzsh/___/plugins/emacs/emacsclient.sh --no-wait'
alias enablehistory='unset -f zshaddhistory'
alias external_ip='curl -s icanhazip.com'
alias fcd=fzf-change-directory
alias fgrep='grep -F'
alias fkill=fzf-kill
alias flush-osx-cache=flu.sh
alias flushdns='dscacheutil -flushcache'
alias flushds='dscacheutil -flushcache'
alias fsh-alias=fast-theme
alias g=git
alias ga='git add'
alias gaa='git add --all'
alias gadd='git add'
alias gam='git am'
alias gama='git am --abort'
alias gamc='git am --continue'
alias gams='git am --skip'
alias gamscp='git am --show-current-patch'
alias gap='git apply'
alias gapa='git add --patch'
alias gapt='git apply --3way'
alias gau='git add --update'
alias gav='git add --verbose'
alias gb='git branch'
alias gbD='git branch --delete --force'
alias gba='git branch --all'
alias gbd='git branch --delete'
alias gbg='LANG=C git branch -vv | grep ": gone\]"'
alias gbgD='LANG=C git branch --no-color -vv | grep ": gone\]" | cut -c 3- | awk '\''{print $1}'\'' | xargs git branch -D'
alias gbgd='LANG=C git branch --no-color -vv | grep ": gone\]" | cut -c 3- | awk '\''{print $1}'\'' | xargs git branch -d'
alias gbl='git blame -w'
alias gblame='git blame'
alias gbm='git branch --move'
alias gbnm='git branch --no-merged'
alias gbr='git branch --remote'
alias gbs='git bisect'
alias gbsb='git bisect bad'
alias gbsg='git bisect good'
alias gbsn='git bisect new'
alias gbso='git bisect old'
alias gbsr='git bisect reset'
alias gbss='git bisect start'
alias gc='git commit --verbose'
alias 'gc!'='git commit --verbose --amend'
alias gcB='git checkout -B'
alias gca='git commit --verbose --all'
alias 'gca!'='git commit --verbose --all --amend'
alias gcam='git commit --all --message'
alias 'gcan!'='git commit --verbose --all --no-edit --amend'
alias 'gcann!'='git commit --verbose --all --date=now --no-edit --amend'
alias 'gcans!'='git commit --verbose --all --signoff --no-edit --amend'
alias gcas='git commit --all --signoff'
alias gcasm='git commit --all --signoff --message'
alias gcb='git checkout -b'
alias gcd='git checkout $(git_develop_branch)'
alias gcf='git config --list'
alias gci='git ci -v'
alias gcl='git clone --recurse-submodules'
alias gclean='git clean --interactive -d'
alias gclf='git clone --recursive --shallow-submodules --filter=blob:none --also-filter-submodules'
alias gcm='git checkout $(git_main_branch)'
alias gcmsg='git commit --message'
alias gcn='git commit --verbose --no-edit'
alias 'gcn!'='git commit --verbose --no-edit --amend'
alias gco='git checkout'
alias gcor='git checkout --recurse-submodules'
alias gcount='git shortlog --summary --numbered'
alias gcp='git cherry-pick'
alias gcpa='git cherry-pick --abort'
alias gcpc='git cherry-pick --continue'
alias gcs='git commit --gpg-sign'
alias gcsm='git commit --signoff --message'
alias gcss='git commit --gpg-sign --signoff'
alias gcssm='git commit --gpg-sign --signoff --message'
alias gd='git diff'
alias gdca='git diff --cached'
alias gdct='git describe --tags $(git rev-list --tags --max-count=1)'
alias gdcw='git diff --cached --word-diff'
alias gdiff='git diff'
alias gds='git diff --staged'
alias gdt='git diff-tree --no-commit-id --name-only -r'
alias gdup='git diff @{upstream}'
alias gdw='git diff --word-diff'
alias gemb='gem build *.gemspec'
alias gemp='gem push *.gem'
alias gerp=grep
alias get-file-modification-time=get_file_modification_time
alias get_nr_jobs=get-nr-jobs
alias gf='git fetch'
alias gfa='git fetch --all --tags --prune --jobs=10'
alias gfg='git ls-files | grep'
alias gfo='git fetch origin'
alias gg='git gui citool'
alias gga='git gui citool --amend'
alias ggpull='git pull origin "$(git_current_branch)"'
alias ggpur=ggu
alias ggpush='git push origin "$(git_current_branch)"'
alias ggsup='git branch --set-upstream-to=origin/$(git_current_branch)'
alias ghh='git help'
alias gignore='git update-index --assume-unchanged'
alias gignored='git ls-files -v | grep "^[[:lower:]]"'
alias git-cdroot='cd $(git rev-parse --show-toplevel) && echo "$_"'
alias git-grab=git-incoming-commits
alias git-ignored='git ls-files --others --i --exclude-standard'
alias git-svn-dcommit-push='git svn dcommit && git push github $(git_main_branch):svntrunk'
alias gitadd='git add'
alias gitci='git ci -v'
alias gitdiff='git diff'
alias gitignored='git ls-files --others --i --exclude-standard'
alias gitlgg='git log --pretty=format:'\''%Cred%h%Creset -%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset'\'
alias gitlog='git log'
alias gitloll='git log --graph --decorate --pretty=oneline --abbrev-commit'
alias gitmerge='git merge'
alias gitpull='git pull'
alias gitpus='git push'
alias gitpush='git push'
alias gitrebase='git rebase'
alias gitroot='cd $(git rev-parse --show-toplevel) && echo "$_"'
alias gitst='git status'
alias gk='\gitk --all --branches &!'
alias gke='\gitk --all $(git log --walk-reflogs --pretty=%h) &!'
alias gl='git pull'
alias glg='git log --stat'
alias glgg='git log --graph'
alias glgga='git log --graph --decorate --all'
alias glgm='git log --graph --max-count=10'
alias glgp='git log --stat --patch'
alias glo='git log --oneline --decorate'
alias glod='git log --graph --pretty="%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ad) %C(bold blue)<%an>%Creset"'
alias glods='git log --graph --pretty="%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ad) %C(bold blue)<%an>%Creset" --date=short'
alias glog='git log --oneline --decorate --graph'
alias gloga='git log --oneline --decorate --graph --all'
alias glol='git log --graph --pretty="%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ar) %C(bold blue)<%an>%Creset"'
alias glola='git log --graph --pretty="%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ar) %C(bold blue)<%an>%Creset" --all'
alias glols='git log --graph --pretty="%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ar) %C(bold blue)<%an>%Creset" --stat'
alias glp=_git_log_prettily
alias gluc='git pull upstream $(git_current_branch)'
alias glum='git pull upstream $(git_main_branch)'
alias gm='git merge'
alias gma='git merge --abort'
alias gmc='git merge --continue'
alias gmff='git merge --ff-only'
alias gmom='git merge origin/$(git_main_branch)'
alias gms='git merge --squash'
alias gmtl='git mergetool --no-prompt'
alias gmtlvim='git mergetool --no-prompt --tool=vimdiff'
alias gmum='git merge upstream/$(git_main_branch)'
alias gob='go build'
alias goc='go clean'
alias god='go doc'
alias goe='go env'
alias gof='go fmt'
alias gofa='go fmt ./...'
alias gofx='go fix'
alias gog='go get'
alias goga='go get ./...'
alias goi='go install'
alias gol='go list'
alias gom='go mod'
alias gomt='go mod tidy'
alias gopa='cd $GOPATH'
alias gopb='cd $GOPATH/bin'
alias gops='cd $GOPATH/src'
alias gor='go run'
alias got='go test'
alias gota='go test ./...'
alias goto='go tool'
alias gotoc='go tool compile'
alias gotod='go tool dist'
alias gotofx='go tool fix'
alias gov='go vet'
alias gove='go version'
alias gow='go work'
alias gp='git push'
alias gpaste='pbpaste | perl -pe '\''s/\r\n|\r/\n/g'\'
alias gpd='git push --dry-run'
alias gpf='git push --force-with-lease --force-if-includes'
alias 'gpf!'='git push --force'
alias gpoat='git push origin --all && git push origin --tags'
alias gpod='git push origin --delete'
alias gpr='git pull --rebase'
alias gpra='git pull --rebase --autostash'
alias gprav='git pull --rebase --autostash -v'
alias gpristine='git reset --hard && git clean --force -dfx'
alias gprom='git pull --rebase origin $(git_main_branch)'
alias gpromi='git pull --rebase=interactive origin $(git_main_branch)'
alias gprum='git pull --rebase upstream $(git_main_branch)'
alias gprumi='git pull --rebase=interactive upstream $(git_main_branch)'
alias gprv='git pull --rebase -v'
alias gpsup='git push --set-upstream origin $(git_current_branch)'
alias gpsupf='git push --set-upstream origin $(git_current_branch) --force-with-lease --force-if-includes'
alias gpu='git push upstream'
alias gpull='git pull'
alias gpush='git push'
alias gpv='git push --verbose'
alias gr='git remote'
alias gra='git remote add'
alias grb='git rebase'
alias grba='git rebase --abort'
alias grbc='git rebase --continue'
alias grbd='git rebase $(git_develop_branch)'
alias grbi='git rebase --interactive'
alias grbm='git rebase $(git_main_branch)'
alias grbo='git rebase --onto'
alias grbom='git rebase origin/$(git_main_branch)'
alias grbs='git rebase --skip'
alias grbum='git rebase upstream/$(git_main_branch)'
alias grebase='git rebase -i'
alias grep='GREP_COLORS="1;37;41" LANG=C grep --color=auto'
alias grep-i='grep -i'
alias grepi='grep -i'
alias grepm='grep --exclude-dir={node_modules,bower_components,dist,.bzr,.cvs,.git,.hg,.svn,.tmp} --color=always'
alias grev='git revert'
alias greva='git revert --abort'
alias grevc='git revert --continue'
alias grf='git reflog'
alias grh='git reset'
alias grhh='git reset --hard'
alias grhk='git reset --keep'
alias grhs='git reset --soft'
alias grm='git rm'
alias grmc='git rm --cached'
alias grmv='git remote rename'
alias groh='git reset origin/$(git_current_branch) --hard'
alias grrm='git remote remove'
alias grs='git restore'
alias grset='git remote set-url'
alias grss='git restore --source'
alias grst='git restore --staged'
alias grt='cd "$(git rev-parse --show-toplevel || echo .)"'
alias gru='git reset --'
alias grup='git remote update'
alias grv='git remote --verbose'
alias gsb='git status --short --branch'
alias gsd='git svn dcommit'
alias gsh='git show'
alias gsi='git submodule init'
alias gsps='git show --pretty=short --show-signature'
alias gsr='git svn rebase'
alias gss='git status --short'
alias gst='git status'
alias gsta='git stash push'
alias gstaa='git stash apply'
alias gstall='git stash --all'
alias gstc='git stash clear'
alias gstd='git stash drop'
alias gstl='git stash list'
alias gstp='git stash pop'
alias gsts='git stash show --patch'
alias gstu='gsta --include-untracked'
alias gsu='git submodule update'
alias gsw='git switch'
alias gswc='git switch --create'
alias gswd='git switch $(git_develop_branch)'
alias gswm='git switch $(git_main_branch)'
alias gta='git tag --annotate'
alias gtl='gtl(){ git tag --sort=-v:refname -n --list "${1}*" }; noglob gtl'
alias gts='git tag --sign'
alias gtv='git tag | sort -V'
alias gunignore='git update-index --no-assume-unchanged'
alias gunwip='git rev-list --max-count=1 --format="%s" HEAD | grep -q "\--wip--" && git reset HEAD~1'
alias gup=$'\n    print -Pu2 "%F{yellow}[oh-my-zsh] \'%F{red}gup%F{yellow}\' is a deprecated alias, using \'%F{green}gpr%F{yellow}\' instead.%f"\n    gpr'
alias gupa=$'\n    print -Pu2 "%F{yellow}[oh-my-zsh] \'%F{red}gupa%F{yellow}\' is a deprecated alias, using \'%F{green}gpra%F{yellow}\' instead.%f"\n    gpra'
alias gupav=$'\n    print -Pu2 "%F{yellow}[oh-my-zsh] \'%F{red}gupav%F{yellow}\' is a deprecated alias, using \'%F{green}gprav%F{yellow}\' instead.%f"\n    gprav'
alias gupom=$'\n    print -Pu2 "%F{yellow}[oh-my-zsh] \'%F{red}gupom%F{yellow}\' is a deprecated alias, using \'%F{green}gprom%F{yellow}\' instead.%f"\n    gprom'
alias gupomi=$'\n    print -Pu2 "%F{yellow}[oh-my-zsh] \'%F{red}gupomi%F{yellow}\' is a deprecated alias, using \'%F{green}gpromi%F{yellow}\' instead.%f"\n    gpromi'
alias gupv=$'\n    print -Pu2 "%F{yellow}[oh-my-zsh] \'%F{red}gupv%F{yellow}\' is a deprecated alias, using \'%F{green}gprv%F{yellow}\' instead.%f"\n    gprv'
alias gwch='git whatchanged -p --abbrev-commit --pretty=medium'
alias gwip='git add -A; git rm $(git ls-files --deleted) 2> /dev/null; git commit --no-verify --no-gpg-sign --message "--wip-- [skip ci]"'
alias gwipe='git reset --hard && git clean --force -df'
alias gwt='git worktree'
alias gwta='git worktree add'
alias gwtls='git worktree list'
alias gwtmv='git worktree move'
alias gwtrm='git worktree remove'
alias hd='hexdump -C'
alias hidefiles='defaults write com.apple.finder AppleShowAllFiles -bool false && killall Finder'
alias history=omz_history
alias historysummary='history | awk '\''{a[$2]++} END{for(i in a){printf "%5d\t%s\n",a[i],i}}'\'' | sort -rn | head'
alias hlog='git log --all --date-order --graph --date=short --format="%C(green)%H%Creset %C(yellow)%an%Creset %C(blue bold)%ad%Creset %C(red bold)%d%Creset%s"'
alias httpdump='sudo tcpdump -i en1 -n -s 0 -w - | grep -a -o -E "Host\: .*|GET \/.*"'
alias ips='ifconfig -a | perl -nle'\''/(\d+\.\d+\.\d+\.\d+)/ && print '\'
alias isodate='date +%Y-%m-%dT%H:%M:%S%z'
alias isodate_basic='date -u +%Y%m%dT%H%M%SZ'
alias isodate_utc='date -u +%Y-%m-%dT%H:%M:%SZ'
alias kickdns='dscacheutil -flushcache'
alias killSS=kill-screensaver
alias killScreenSaver=kill-screensaver
alias knfie=knife
alias knife='nocorrect knife'
alias l='eza -al --icons --git --time-style=long-iso --group-directories-first --color-scale'
alias lD='eza -ghlD --group-directories-first --git --icons=auto --hyperlink'
alias lDD='eza -ghlDa --group-directories-first --git --icons=auto --hyperlink'
alias lS='eza -ghl -ssize --group-directories-first --git --icons=auto --hyperlink'
alias lT='eza -ghl -snewest --group-directories-first --git --icons=auto --hyperlink'
alias la='gls -A --color'
alias latest-perl='curl -s https://www.perl.org/get.html | perl -wlne '\''if (/perl\-([\d\.]+)\.tar\.gz/) { print $1; exit;}'\'
alias ldot='eza -ghld --group-directories-first --git --icons=auto --hyperlink .*'
alias less=bat
alias ll='gls -l --color'
alias ls='eza --group-directories-first'
alias lsa='ls -lah'
alias lsd='eza -ghd --group-directories-first --git --icons=auto --hyperlink'
alias lsdl='eza -ghdl --group-directories-first --git --icons=auto --hyperlink'
alias lss='lsd --group-dirs first'
alias mac2unix='tr '\''\015'\'' '\''\012'\'
alias maek=make
alias md='mkdir -p'
alias md5sum=/sbin/md5
alias mkdir-p='mkdir -p'
alias mkdirp='mkdir -p'
alias mtr_url=mtr-url
alias my_ips='ifconfig -a | perl -nle'\''/(\d+\.\d+\.\d+\.\d+)/ && print '\'
alias myip='dig +short myip.opendns.com @resolver1.opendns.com'
alias mywireless=wifi-name
alias naliases=n-aliases
alias ncd=n-cd
alias nenv=n-env
alias nfunctions=n-functions
alias nh-scp=scp-no-hostchecks
alias nh-ssh=ssh-no-hostchecks
alias nh_scp=scp-no-hostchecks
alias nh_ssh=ssh-no-hostchecks
alias nhelp=n-help
alias nhistory=n-history
alias nhscp=scp-no-hostchecks
alias nhssh=ssh-no-hostchecks
alias nkill=n-kill
alias noptions=n-options
alias npanelize=n-panelize
alias npmD='npm i -D '
alias npmE='PATH="$(npm bin)":"$PATH"'
alias npmF='npm i -f'
alias npmI='npm init'
alias npmL='npm list'
alias npmL0='npm ls --depth=0'
alias npmO='npm outdated'
alias npmP='npm publish'
alias npmR='npm run'
alias npmS='npm i -S '
alias npmSe='npm search'
alias npmU='npm update'
alias npmV='npm -v'
alias npmg='npm i -g '
alias npmi='npm info'
alias npmrb='npm run build'
alias npmrd='npm run dev'
alias npmst='npm start'
alias npmt='npm test'
alias nvim-Kickstart='NVIM_APPNAME=nvim-Kickstart nvim'
alias nvim-LazyIde='NVIM_APPNAME=nvim-LazyIde nvim'
alias nvim-LazyVim='NVIM_APPNAME=nvim-LazyVim nvim'
alias nvim-Lazyman='NVIM_APPNAME=nvim-Lazyman nvim'
alias nvim-default='NVIM_APPNAME=nvim nvim'
alias pacac='php artisan cache:clear'
alias pacoc='php artisan config:clear'
alias pads='php artisan db:seed'
alias pam='php artisan migrate'
alias pamc='php artisan make:controller'
alias pamcl='php artisan make:class'
alias pame='php artisan make:event'
alias pamen='php artisan make:enum'
alias pamf='php artisan migrate:fresh'
alias pamfa='php artisan make:factory'
alias pamfs='php artisan migrate:fresh --seed'
alias pami='php artisan make:interface'
alias pamj='php artisan make:job'
alias paml='php artisan make:listener'
alias pamm='php artisan make:model'
alias pamn='php artisan make:notification'
alias pamp='php artisan make:policy'
alias pampp='php artisan make:provider'
alias pamr='php artisan migrate:rollback'
alias pams='php artisan make:seeder'
alias pamt='php artisan make:test'
alias pamtr='php artisan make:trait'
alias paopc='php artisan optimize:clear'
alias paqf='php artisan queue:failed'
alias paqft='php artisan queue:failed-table'
alias paql='php artisan queue:listen'
alias paqr='php artisan queue:retry'
alias paqt='php artisan queue:table'
alias paqw='php artisan queue:work'
alias paroc='php artisan route:clear'
alias pas='php artisan serve'
alias pats='php artisan test'
alias pavic='php artisan view:clear'
alias pbi='perlbrew install'
alias pbl='perlbrew list'
alias pbo='perlbrew off'
alias pbs='perlbrew switch'
alias pbu='perlbrew use'
alias pd=perldoc
alias perl-grep=pgrep
alias perlgrep=pgrep
alias pip='noglob pip3'
alias pipgi='pip freeze | grep'
alias pipi='pip install'
alias pipir='pip install -r requirements.txt'
alias piplo='pip list -o'
alias pipreq='pip freeze > requirements.txt'
alias pipu='pip install --upgrade'
alias pipun='pip uninstall'
alias pl-grep=pgrep
alias ple='perl -wlne'
alias procs_for_path=procs-for-path
alias psax='ps ax'
alias pswax='ps wax'
alias psxa='ps ax'
alias py=python3
alias pyfind='find . -name "*.py"'
alias pygrep='grep -nr --include="*.py"'
alias pyserver='python3 -m http.server'
alias python_module_path='echo '\''import sys; t=__import__(sys.argv[1],fromlist=["."]); print(t.__file__)'\''  | python - '
alias ql='qlmanage -p'
alias raek=rake
alias rd=rmdir
alias reattach='screen -r'
alias reveal='open --reveal'
alias rsync-copy='rsync -avz --progress -h'
alias rsync-move='rsync -avz --progress -h --remove-source-files'
alias rsync-synchronize='rsync -avzu --delete --progress -h'
alias rsync-update='rsync -avzu --progress -h'
alias rubies=chruby
alias run-help=man
alias scp-no-hostchecks='scp -o UserKnownHostsFile=/dev/null -o GlobalKnownHostsFile=/dev/null -o StrictHostKeyChecking=no'
alias scp_no_hostchecks='scp -o UserKnownHostsFile=/dev/null -o GlobalKnownHostsFile=/dev/null -o StrictHostKeyChecking=no'
alias scpi='scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o GlobalKnownHostsFile=/dev/null'
alias sha1sum=/opt/homebrew/bin/shasum
alias showfiles='defaults write com.apple.finder AppleShowAllFiles -bool true && killall Finder'
alias sign='gpg --detach-sign --armor'
alias snake_case='tr [A-Z\ ] [a-z_]'
alias sniff='sudo ngrep -d '\''en1'\'' -t '\''^(GET|POST) '\'' '\''tcp and port 80'\'
alias spotlighter='mdfind -onlyin `pwd`'
alias ssh='ssh -A'
alias ssh-A='ssh -A'
alias ssh-addme=sshaddme
alias ssh-force-password='ssh -o PreferredAuthentications=password -o PubkeyAuthentication=no'
alias ssh-force-password-no-hostcheck='ssh -o PreferredAuthentications=password -o PubkeyAuthentication=no -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o GlobalKnownHostsFile=/dev/null'
alias ssh-no-hostchecks='ssh -A -o UserKnownHostsFile=/dev/null -o GlobalKnownHostsFile=/dev/null -o StrictHostKeyChecking=no'
alias ssh-unkeyed=/usr/bin/ssh
alias sshA='ssh -A'
alias ssh_no_hostchecks='ssh -A -o UserKnownHostsFile=/dev/null -o GlobalKnownHostsFile=/dev/null -o StrictHostKeyChecking=no'
alias ssh_unkeyed=/usr/bin/ssh
alias sshi='ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o GlobalKnownHostsFile=/dev/null'
alias sshnohostchecks='ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o GlobalKnownHostsFile=/dev/null'
alias stripcolors='sed -r "s/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[mGK]//g"'
alias tar-tvf='tar tvf'
alias tar-tvzf='tar tvzf'
alias tar-xvf='tar xvf'
alias tar-xvzf='tar xvzf'
alias tartvf='tar tvf'
alias tartvzf='tar tvzf'
alias tarxvf='tar xvf'
alias tarxvjf='tar xvjf'
alias tarxvzf='tar xvzf'
alias tds=_tmux_directory_session
alias te='/Users/s-a-c/.config/zsh/.zgenom/ohmyzsh/ohmyzsh/___/plugins/emacs/emacsclient.sh -nw'
alias test-broadband='wget -O /dev/null http://speedtest.wdc01.softlayer.com/downloads/test500.zip'
alias tksv='tmux kill-server'
alias tl='tmux list-sessions'
alias tldrf='tldr --list | fzf --preview "tldr {1} --color=always" --preview-window=right:70% | xargs tldr --color=always'
alias tmux=_zsh_tmux_plugin_run
alias tmuxconf='$EDITOR $ZSH_TMUX_CONFIG'
alias top='TERM=vt100 top'
alias tree='lsd --tree'
alias unix2mac='tr '\''\012'\'' '\''\015'\'
alias unixstamp='date +%s'
alias updatedb='sudo /usr/libexec/locate.updatedb'
alias vba='vagrant box add'
alias vbl='vagrant box list'
alias vbo='vagrant box outdated'
alias vbr='vagrant box remove'
alias vbu='vagrant box update'
alias vd='vagrant destroy'
alias vdf='vagrant destroy -f'
alias vgi='vagrant init'
alias vgs='vagrant global-status'
alias vh='vagrant halt'
alias vi=/usr/bin/vim
alias vim=/usr/bin/vim
alias vp='vagrant push'
alias vpli='vagrant plugin install'
alias vpll='vagrant plugin list'
alias vplu='vagrant plugin update'
alias vplun='vagrant plugin uninstall'
alias vpr='vagrant provision'
alias vr='vagrant reload'
alias vrdp='vagrant rdp'
alias vre='vagrant resume'
alias vrp='vagrant reload --provision'
alias vs-code=code
alias vscode=code
alias vsh='vagrant share'
alias vssh='vagrant ssh'
alias vsshc='vagrant ssh-config'
alias vssp='vagrant suspend'
alias vst='vagrant status'
alias vup='vagrant up'
alias wcat='wget -q -O -'
alias wget='wget -c'
alias wget-images='wget -nd -r -l 2 -A jpg,jpeg,png,gif,bmp'
alias which-command=whence
alias xcb=xcodebuild
alias xcdd='rm -rf ~/Library/Developer/Xcode/DerivedData/*'
alias xcp='xcode-select --print-path'
alias xcsel='sudo xcode-select --switch'
alias zh='fc -l -d -D'
alias zombies=zombie
alias zz=exit
