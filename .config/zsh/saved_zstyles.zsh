zstyle :omz:plugins:ssh-agent agent-forwarding yes
zstyle ':completion:*:options' auto-description %d
zstyle :omz:plugins:nvm autoload yes
zstyle :omz:plugins:ssh-agent autoload yes
zstyle ':completion:*' cache-path /Users/s-a-c/.cache/zsh
zstyle ':completion:*:*:*:*:processes' command 'ps -u s-a-c -o pid,user,comm -w -w'
zstyle ':completion:*' completer _complete _match _approximate
zstyle ':completion:*:options' description yes
zstyle :omz:plugins:eza dirs-first yes
zstyle ':completion:*:corrections' format ' %F{green}-- %d (errors: %e) --%f'
zstyle ':completion:*:descriptions' format ' %F{yellow}-- %d --%f'
zstyle ':completion:*:messages' format ' %F{purple} -- %d --%f'
zstyle ':completion:*:warnings' format ' %F{red}-- no matches found --%f'
zstyle ':completion:*' format ' %F{yellow}-- %d --%f'
zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'ls --color $realpath'
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'
zstyle :omz:plugins:eza git-status yes
zstyle ':completion:*:matches' group yes
zstyle ':completion:*' group-name ''
zstyle :omz:plugins:eza header yes
zstyle ':completion:*:hosts' hosts github.com
zstyle :omz:plugins:eza hyperlink yes
zstyle :omz:plugins:eza icons yes
zstyle :omz:plugins:ssh-agent identities /Users/s-a-c/.ssh/id_ed25519
zstyle ':completion:*:*:*:users' ignored-patterns adm amanda apache at avahi avahi-autoipd beaglidx bin cacti canna clamav daemon dbus distcache dnsmasq dovecot fax ftp games gdm gkrellmd gopher hacluster haldaemon halt hsqldb ident junkbust kdm ldap lp mail mailman mailnull man messagebus mldonkey mysql nagios named netdump news nfsnobody nobody nscd ntp nut nx obsrun openvpn operator pcap polkitd postfix postgres privoxy pulse pvm quagga radvd rpc rpcuser rpm rtkit scard shutdown squid sshd statd svn sync tftp usbmux uucp vcsa wwwrun xfs '_*'
zstyle ':completion:*:functions' ignored-patterns '(_*|pre(cmd|exec))'
zstyle :omz:plugins:nvm lazy yes
zstyle :omz:plugins:ssh-agent lazy yes
zstyle :omz:plugins:nvm lazy-cmd nvm node npm pnpm yarn corepack eslint prettier typescript
zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#) ([0-9a-z-]#)*=01;34=0=01'
zstyle ':completion:*' list-colors '*~=0;38;2;88;91;112' 'bd=0;38;2;116;199;236;48;2;49;50;68' 'ca=0' 'cd=0;38;2;245;194;231;48;2;49;50;68' 'di=0;38;2;137;180;250' 'do=0;38;2;17;17;27;48;2;245;194;231' 'ex=1;38;2;243;139;168' 'fi=0' 'ln=0;38;2;245;194;231' 'mh=0' 'mi=0;38;2;17;17;27;48;2;243;139;168' 'no=0' 'or=0;38;2;17;17;27;48;2;243;139;168' 'ow=0' 'pi=0;38;2;17;17;27;48;2;137;180;250' 'rs=0' 'sg=0' 'so=0;38;2;17;17;27;48;2;245;194;231' 'st=0' 'su=0' 'tw=0' '*.1=0;38;2;249;226;175' '*.a=1;38;2;243;139;168' '*.c=0;38;2;166;227;161' '*.d=0;38;2;166;227;161' '*.h=0;38;2;166;227;161' '*.m=0;38;2;166;227;161' '*.o=0;38;2;88;91;112' '*.p=0;38;2;166;227;161' '*.r=0;38;2;166;227;161' '*.t=0;38;2;166;227;161' '*.v=0;38;2;166;227;161' '*.z=4;38;2;116;199;236' '*.7z=4;38;2;116;199;236' '*.ai=0;38;2;242;205;205' '*.as=0;38;2;166;227;161' '*.bc=0;38;2;88;91;112' '*.bz=4;38;2;116;199;236' '*.cc=0;38;2;166;227;161' '*.cp=0;38;2;166;227;161' '*.cr=0;38;2;166;227;161' '*.cs=0;38;2;166;227;161' '*.db=4;38;2;116;199;236' '*.di=0;38;2;166;227;161' '*.el=0;38;2;166;227;161' '*.ex=0;38;2;166;227;161' '*.fs=0;38;2;166;227;161' '*.go=0;38;2;166;227;161' '*.gv=0;38;2;166;227;161' '*.gz=4;38;2;116;199;236' '*.ha=0;38;2;166;227;161' '*.hh=0;38;2;166;227;161' '*.hi=0;38;2;88;91;112' '*.hs=0;38;2;166;227;161' '*.jl=0;38;2;166;227;161' '*.js=0;38;2;166;227;161' '*.ko=1;38;2;243;139;168' '*.kt=0;38;2;166;227;161' '*.la=0;38;2;88;91;112' '*.ll=0;38;2;166;227;161' '*.lo=0;38;2;88;91;112' '*.ma=0;38;2;242;205;205' '*.mb=0;38;2;242;205;205' '*.md=0;38;2;249;226;175' '*.mk=0;38;2;148;226;213' '*.ml=0;38;2;166;227;161' '*.mn=0;38;2;166;227;161' '*.nb=0;38;2;166;227;161' '*.nu=0;38;2;166;227;161' '*.pl=0;38;2;166;227;161' '*.pm=0;38;2;166;227;161' '*.pp=0;38;2;166;227;161' '*.ps=0;38;2;243;139;168' '*.py=0;38;2;166;227;161' '*.rb=0;38;2;166;227;161' '*.rm=0;38;2;242;205;205' '*.rs=0;38;2;166;227;161' '*.sh=0;38;2;166;227;161' '*.so=1;38;2;243;139;168' '*.td=0;38;2;166;227;161' '*.ts=0;38;2;166;227;161' '*.ui=0;38;2;249;226;175' '*.vb=0;38;2;166;227;161' '*.wv=0;38;2;242;205;205' '*.xz=4;38;2;116;199;236' '*FAQ=0;38;2;30;30;46;48;2;249;226;175' '*.3ds=0;38;2;242;205;205' '*.3fr=0;38;2;242;205;205' '*.3mf=0;38;2;242;205;205' '*.adb=0;38;2;166;227;161' '*.ads=0;38;2;166;227;161' '*.aif=0;38;2;242;205;205' '*.amf=0;38;2;242;205;205' '*.ape=0;38;2;242;205;205' '*.apk=4;38;2;116;199;236' '*.ari=0;38;2;242;205;205' '*.arj=4;38;2;116;199;236' '*.arw=0;38;2;242;205;205' '*.asa=0;38;2;166;227;161' '*.asm=0;38;2;166;227;161' '*.aux=0;38;2;88;91;112' '*.avi=0;38;2;242;205;205' '*.awk=0;38;2;166;227;161' '*.bag=4;38;2;116;199;236' '*.bak=0;38;2;88;91;112' '*.bat=1;38;2;243;139;168' '*.bay=0;38;2;242;205;205' '*.bbl=0;38;2;88;91;112' '*.bcf=0;38;2;88;91;112' '*.bib=0;38;2;249;226;175' '*.bin=4;38;2;116;199;236' '*.blg=0;38;2;88;91;112' '*.bmp=0;38;2;242;205;205' '*.bsh=0;38;2;166;227;161' '*.bst=0;38;2;249;226;175' '*.bz2=4;38;2;116;199;236' '*.c++=0;38;2;166;227;161' '*.cap=0;38;2;242;205;205' '*.cfg=0;38;2;249;226;175' '*.cgi=0;38;2;166;227;161' '*.clj=0;38;2;166;227;161' '*.com=1;38;2;243;139;168' '*.cpp=0;38;2;166;227;161' '*.cr2=0;38;2;242;205;205' '*.cr3=0;38;2;242;205;205' '*.crw=0;38;2;242;205;205' '*.css=0;38;2;166;227;161' '*.csv=0;38;2;249;226;175' '*.csx=0;38;2;166;227;161' '*.cxx=0;38;2;166;227;161' '*.dae=0;38;2;242;205;205' '*.dcr=0;38;2;242;205;205' '*.dcs=0;38;2;242;205;205' '*.deb=4;38;2;116;199;236' '*.def=0;38;2;166;227;161' '*.dll=1;38;2;243;139;168' '*.dmg=4;38;2;116;199;236' '*.dng=0;38;2;242;205;205' '*.doc=0;38;2;243;139;168' '*.dot=0;38;2;166;227;161' '*.dox=0;38;2;148;226;213' '*.dpr=0;38;2;166;227;161' '*.drf=0;38;2;242;205;205' '*.dxf=0;38;2;242;205;205' '*.eip=0;38;2;242;205;205' '*.elc=0;38;2;166;227;161' '*.elm=0;38;2;166;227;161' '*.epp=0;38;2;166;227;161' '*.eps=0;38;2;242;205;205' '*.erf=0;38;2;242;205;205' '*.erl=0;38;2;166;227;161' '*.exe=1;38;2;243;139;168' '*.exr=0;38;2;242;205;205' '*.exs=0;38;2;166;227;161' '*.fbx=0;38;2;242;205;205' '*.fff=0;38;2;242;205;205' '*.fls=0;38;2;88;91;112' '*.flv=0;38;2;242;205;205' '*.fnt=0;38;2;242;205;205' '*.fon=0;38;2;242;205;205' '*.fsi=0;38;2;166;227;161' '*.fsx=0;38;2;166;227;161' '*.gif=0;38;2;242;205;205' '*.git=0;38;2;88;91;112' '*.gpr=0;38;2;242;205;205' '*.gvy=0;38;2;166;227;161' '*.h++=0;38;2;166;227;161' '*.hda=0;38;2;242;205;205' '*.hip=0;38;2;242;205;205' '*.hpp=0;38;2;166;227;161' '*.htc=0;38;2;166;227;161' '*.htm=0;38;2;249;226;175' '*.hxx=0;38;2;166;227;161' '*.ico=0;38;2;242;205;205' '*.ics=0;38;2;243;139;168' '*.idx=0;38;2;88;91;112' '*.igs=0;38;2;242;205;205' '*.iiq=0;38;2;242;205;205' '*.ilg=0;38;2;88;91;112' '*.img=4;38;2;116;199;236' '*.inc=0;38;2;166;227;161' '*.ind=0;38;2;88;91;112' '*.ini=0;38;2;249;226;175' '*.inl=0;38;2;166;227;161' '*.ino=0;38;2;166;227;161' '*.ipp=0;38;2;166;227;161' '*.iso=4;38;2;116;199;236' '*.jar=4;38;2;116;199;236' '*.jpg=0;38;2;242;205;205' '*.jsx=0;38;2;166;227;161' '*.jxl=0;38;2;242;205;205' '*.k25=0;38;2;242;205;205' '*.kdc=0;38;2;242;205;205' '*.kex=0;38;2;243;139;168' '*.kra=0;38;2;242;205;205' '*.kts=0;38;2;166;227;161' '*.log=0;38;2;88;91;112' '*.ltx=0;38;2;166;227;161' '*.lua=0;38;2;166;227;161' '*.m3u=0;38;2;242;205;205' '*.m4a=0;38;2;242;205;205' '*.m4v=0;38;2;242;205;205' '*.mdc=0;38;2;242;205;205' '*.mef=0;38;2;242;205;205' '*.mid=0;38;2;242;205;205' '*.mir=0;38;2;166;227;161' '*.mkv=0;38;2;242;205;205' '*.mli=0;38;2;166;227;161' '*.mos=0;38;2;242;205;205' '*.mov=0;38;2;242;205;205' '*.mp3=0;38;2;242;205;205' '*.mp4=0;38;2;242;205;205' '*.mpg=0;38;2;242;205;205' '*.mrw=0;38;2;242;205;205' '*.msi=4;38;2;116;199;236' '*.mtl=0;38;2;242;205;205' '*.nef=0;38;2;242;205;205' '*.nim=0;38;2;166;227;161' '*.nix=0;38;2;249;226;175' '*.nrw=0;38;2;242;205;205' '*.obj=0;38;2;242;205;205' '*.obm=0;38;2;242;205;205' '*.odp=0;38;2;243;139;168' '*.ods=0;38;2;243;139;168' '*.odt=0;38;2;243;139;168' '*.ogg=0;38;2;242;205;205' '*.ogv=0;38;2;242;205;205' '*.orf=0;38;2;242;205;205' '*.org=0;38;2;249;226;175' '*.otf=0;38;2;242;205;205' '*.otl=0;38;2;242;205;205' '*.out=0;38;2;88;91;112' '*.pas=0;38;2;166;227;161' '*.pbm=0;38;2;242;205;205' '*.pcx=0;38;2;242;205;205' '*.pdf=0;38;2;243;139;168' '*.pef=0;38;2;242;205;205' '*.pgm=0;38;2;242;205;205' '*.php=0;38;2;166;227;161' '*.pid=0;38;2;88;91;112' '*.pkg=4;38;2;116;199;236' '*.png=0;38;2;242;205;205' '*.pod=0;38;2;166;227;161' '*.ppm=0;38;2;242;205;205' '*.pps=0;38;2;243;139;168' '*.ppt=0;38;2;243;139;168' '*.pro=0;38;2;148;226;213' '*.ps1=0;38;2;166;227;161' '*.psd=0;38;2;242;205;205' '*.ptx=0;38;2;242;205;205' '*.pxn=0;38;2;242;205;205' '*.pyc=0;38;2;88;91;112' '*.pyd=0;38;2;88;91;112' '*.pyo=0;38;2;88;91;112' '*.qoi=0;38;2;242;205;205' '*.r3d=0;38;2;242;205;205' '*.raf=0;38;2;242;205;205' '*.rar=4;38;2;116;199;236' '*.raw=0;38;2;242;205;205' '*.rpm=4;38;2;116;199;236' '*.rst=0;38;2;249;226;175' '*.rtf=0;38;2;243;139;168' '*.rw2=0;38;2;242;205;205' '*.rwl=0;38;2;242;205;205' '*.rwz=0;38;2;242;205;205' '*.sbt=0;38;2;166;227;161' '*.sql=0;38;2;166;227;161' '*.sr2=0;38;2;242;205;205' '*.srf=0;38;2;242;205;205' '*.srw=0;38;2;242;205;205' '*.stl=0;38;2;242;205;205' '*.stp=0;38;2;242;205;205' '*.sty=0;38;2;88;91;112' '*.svg=0;38;2;242;205;205' '*.swf=0;38;2;242;205;205' '*.swp=0;38;2;88;91;112' '*.sxi=0;38;2;243;139;168' '*.sxw=0;38;2;243;139;168' '*.tar=4;38;2;116;199;236' '*.tbz=4;38;2;116;199;236' '*.tcl=0;38;2;166;227;161' '*.tex=0;38;2;166;227;161' '*.tga=0;38;2;242;205;205' '*.tgz=4;38;2;116;199;236' '*.tif=0;38;2;242;205;205' '*.tml=0;38;2;249;226;175' '*.tmp=0;38;2;88;91;112' '*.toc=0;38;2;88;91;112' '*.tsx=0;38;2;166;227;161' '*.ttf=0;38;2;242;205;205' '*.txt=0;38;2;249;226;175' '*.typ=0;38;2;249;226;175' '*.usd=0;38;2;242;205;205' '*.vcd=4;38;2;116;199;236' '*.vim=0;38;2;166;227;161' '*.vob=0;38;2;242;205;205' '*.vsh=0;38;2;166;227;161' '*.wav=0;38;2;242;205;205' '*.wma=0;38;2;242;205;205' '*.wmv=0;38;2;242;205;205' '*.wrl=0;38;2;242;205;205' '*.x3d=0;38;2;242;205;205' '*.x3f=0;38;2;242;205;205' '*.xlr=0;38;2;243;139;168' '*.xls=0;38;2;243;139;168' '*.xml=0;38;2;249;226;175' '*.xmp=0;38;2;249;226;175' '*.xpm=0;38;2;242;205;205' '*.xvf=0;38;2;242;205;205' '*.yml=0;38;2;249;226;175' '*.zig=0;38;2;166;227;161' '*.zip=4;38;2;116;199;236' '*.zsh=0;38;2;166;227;161' '*.zst=4;38;2;116;199;236' '*TODO=1' '*hgrc=0;38;2;148;226;213' '*.avif=0;38;2;242;205;205' '*.bash=0;38;2;166;227;161' '*.braw=0;38;2;242;205;205' '*.conf=0;38;2;249;226;175' '*.dart=0;38;2;166;227;161' '*.data=0;38;2;242;205;205' '*.diff=0;38;2;166;227;161' '*.docx=0;38;2;243;139;168' '*.epub=0;38;2;243;139;168' '*.fish=0;38;2;166;227;161' '*.flac=0;38;2;242;205;205' '*.h264=0;38;2;242;205;205' '*.hack=0;38;2;166;227;161' '*.heif=0;38;2;242;205;205' '*.hgrc=0;38;2;148;226;213' '*.html=0;38;2;249;226;175' '*.iges=0;38;2;242;205;205' '*.info=0;38;2;249;226;175' '*.java=0;38;2;166;227;161' '*.jpeg=0;38;2;242;205;205' '*.json=0;38;2;249;226;175' '*.less=0;38;2;166;227;161' '*.lisp=0;38;2;166;227;161' '*.lock=0;38;2;88;91;112' '*.make=0;38;2;148;226;213' '*.mojo=0;38;2;166;227;161' '*.mpeg=0;38;2;242;205;205' '*.nims=0;38;2;166;227;161' '*.opus=0;38;2;242;205;205' '*.orig=0;38;2;88;91;112' '*.pptx=0;38;2;243;139;168' '*.prql=0;38;2;166;227;161' '*.psd1=0;38;2;166;227;161' '*.psm1=0;38;2;166;227;161' '*.purs=0;38;2;166;227;161' '*.raku=0;38;2;166;227;161' '*.rlib=0;38;2;88;91;112' '*.sass=0;38;2;166;227;161' '*.scad=0;38;2;166;227;161' '*.scss=0;38;2;166;227;161' '*.step=0;38;2;242;205;205' '*.tbz2=4;38;2;116;199;236' '*.tiff=0;38;2;242;205;205' '*.toml=0;38;2;249;226;175' '*.usda=0;38;2;242;205;205' '*.usdc=0;38;2;242;205;205' '*.usdz=0;38;2;242;205;205' '*.webm=0;38;2;242;205;205' '*.webp=0;38;2;242;205;205' '*.woff=0;38;2;242;205;205' '*.xbps=4;38;2;116;199;236' '*.xlsx=0;38;2;243;139;168' '*.yaml=0;38;2;249;226;175' '*stdin=0;38;2;88;91;112' '*v.mod=0;38;2;148;226;213' '*.blend=0;38;2;242;205;205' '*.cabal=0;38;2;166;227;161' '*.cache=0;38;2;88;91;112' '*.class=0;38;2;88;91;112' '*.cmake=0;38;2;148;226;213' '*.ctags=0;38;2;88;91;112' '*.dylib=1;38;2;243;139;168' '*.dyn_o=0;38;2;88;91;112' '*.gcode=0;38;2;166;227;161' '*.ipynb=0;38;2;166;227;161' '*.mdown=0;38;2;249;226;175' '*.patch=0;38;2;166;227;161' '*.rmeta=0;38;2;88;91;112' '*.scala=0;38;2;166;227;161' '*.shtml=0;38;2;249;226;175' '*.swift=0;38;2;166;227;161' '*.toast=4;38;2;116;199;236' '*.woff2=0;38;2;242;205;205' '*.xhtml=0;38;2;249;226;175' '*Icon\r=0;38;2;88;91;112' '*LEGACY=0;38;2;30;30;46;48;2;249;226;175' '*NOTICE=0;38;2;30;30;46;48;2;249;226;175' '*README=0;38;2;30;30;46;48;2;249;226;175' '*go.mod=0;38;2;148;226;213' '*go.sum=0;38;2;88;91;112' '*passwd=0;38;2;249;226;175' '*shadow=0;38;2;249;226;175' '*stderr=0;38;2;88;91;112' '*stdout=0;38;2;88;91;112' '*.bashrc=0;38;2;166;227;161' '*.config=0;38;2;249;226;175' '*.dyn_hi=0;38;2;88;91;112' '*.flake8=0;38;2;148;226;213' '*.gradle=0;38;2;166;227;161' '*.groovy=0;38;2;166;227;161' '*.ignore=0;38;2;148;226;213' '*.matlab=0;38;2;166;227;161' '*.nimble=0;38;2;166;227;161' '*COPYING=0;38;2;147;153;178' '*INSTALL=0;38;2;30;30;46;48;2;249;226;175' '*LICENCE=0;38;2;147;153;178' '*LICENSE=0;38;2;147;153;178' '*TODO.md=1' '*VERSION=0;38;2;30;30;46;48;2;249;226;175' '*.alembic=0;38;2;242;205;205' '*.desktop=0;38;2;249;226;175' '*.gemspec=0;38;2;148;226;213' '*.mailmap=0;38;2;148;226;213' '*Doxyfile=0;38;2;148;226;213' '*Makefile=0;38;2;148;226;213' '*TODO.txt=1' '*setup.py=0;38;2;148;226;213' '*.DS_Store=0;38;2;88;91;112' '*.cmake.in=0;38;2;148;226;213' '*.fdignore=0;38;2;148;226;213' '*.kdevelop=0;38;2;148;226;213' '*.markdown=0;38;2;249;226;175' '*.rgignore=0;38;2;148;226;213' '*.tfignore=0;38;2;148;226;213' '*CHANGELOG=0;38;2;30;30;46;48;2;249;226;175' '*COPYRIGHT=0;38;2;147;153;178' '*README.md=0;38;2;30;30;46;48;2;249;226;175' '*bun.lockb=0;38;2;88;91;112' '*configure=0;38;2;148;226;213' '*.gitconfig=0;38;2;148;226;213' '*.gitignore=0;38;2;148;226;213' '*.localized=0;38;2;88;91;112' '*.scons_opt=0;38;2;88;91;112' '*.timestamp=0;38;2;88;91;112' '*CODEOWNERS=0;38;2;148;226;213' '*Dockerfile=0;38;2;249;226;175' '*INSTALL.md=0;38;2;30;30;46;48;2;249;226;175' '*README.txt=0;38;2;30;30;46;48;2;249;226;175' '*SConscript=0;38;2;148;226;213' '*SConstruct=0;38;2;148;226;213' '*.cirrus.yml=0;38;2;166;227;161' '*.gitmodules=0;38;2;148;226;213' '*.synctex.gz=0;38;2;88;91;112' '*.travis.yml=0;38;2;166;227;161' '*INSTALL.txt=0;38;2;30;30;46;48;2;249;226;175' '*LICENSE-MIT=0;38;2;147;153;178' '*MANIFEST.in=0;38;2;148;226;213' '*Makefile.am=0;38;2;148;226;213' '*Makefile.in=0;38;2;88;91;112' '*.applescript=0;38;2;166;227;161' '*.fdb_latexmk=0;38;2;88;91;112' '*.webmanifest=0;38;2;249;226;175' '*CHANGELOG.md=0;38;2;30;30;46;48;2;249;226;175' '*CONTRIBUTING=0;38;2;30;30;46;48;2;249;226;175' '*CONTRIBUTORS=0;38;2;30;30;46;48;2;249;226;175' '*appveyor.yml=0;38;2;166;227;161' '*configure.ac=0;38;2;148;226;213' '*.bash_profile=0;38;2;166;227;161' '*.clang-format=0;38;2;148;226;213' '*.editorconfig=0;38;2;148;226;213' '*CHANGELOG.txt=0;38;2;30;30;46;48;2;249;226;175' '*.gitattributes=0;38;2;148;226;213' '*.gitlab-ci.yml=0;38;2;166;227;161' '*CMakeCache.txt=0;38;2;88;91;112' '*CMakeLists.txt=0;38;2;148;226;213' '*LICENSE-APACHE=0;38;2;147;153;178' '*pyproject.toml=0;38;2;148;226;213' '*CODE_OF_CONDUCT=0;38;2;30;30;46;48;2;249;226;175' '*CONTRIBUTING.md=0;38;2;30;30;46;48;2;249;226;175' '*CONTRIBUTORS.md=0;38;2;30;30;46;48;2;249;226;175' '*.sconsign.dblite=0;38;2;88;91;112' '*CONTRIBUTING.txt=0;38;2;30;30;46;48;2;249;226;175' '*CONTRIBUTORS.txt=0;38;2;30;30;46;48;2;249;226;175' '*requirements.txt=0;38;2;148;226;213' '*package-lock.json=0;38;2;88;91;112' '*CODE_OF_CONDUCT.md=0;38;2;30;30;46;48;2;249;226;175' '*.CFUserTextEncoding=0;38;2;88;91;112' '*CODE_OF_CONDUCT.txt=0;38;2;30;30;46;48;2;249;226;175' '*azure-pipelines.yml=0;38;2;166;227;161'
zstyle ':completion:*:default' list-prompt '%S%M matches%s'
zstyle :completion::complete:n-kill::bits matcher 'r:|=** l:|=*'
zstyle ':completion:*' matcher-list 'm:{[:lower:][:upper:]}={[:upper:][:lower:]}' 'r:|=*' 'l:|=* r:|=*'
zstyle -e ':completion:*:approximate:*' max-errors 'reply=($((($#PREFIX+$#SUFFIX)/3>7?7:($#PREFIX+$#SUFFIX)/3))numeric)'
zstyle ':completion:*:*:*:*:*' menu select
zstyle ':completion:*' menu select
zstyle ':completion:*:match:*' original only
zstyle :omz:plugins:ssh-agent quiet yes
zstyle ':completion:*' rehash true
zstyle :omz:plugins:nvm silent-autoload yes
zstyle '*' single-ignored show
zstyle ':completion:*' special-dirs true
zstyle :omz:plugins:ssh-agent ssh-add-args --apple-load-keychain --apple-use-keychain
zstyle ':completion:*:cd:*' tag-order local-directories directory-stack path-directories
zstyle :plugin:fast-syntax-highlighting theme default
zstyle ':completion:*' use-cache yes
zstyle ':completion:*:*:git:*' user-commands 'age:A git-blame viewer, written using PyGTK written by Kristoffer Gronlund ' 'big-file:List disk size of files in ref' 'branch-diff:Diff between the default branch and a branch' 'branch-name:Prints the current branch name to stdout for use in automation' 'change-author:Rewrite commits, updating author/email' 'changes:List authors/emails with commit count' 'checkout-tag:Check out a git tag' 'churn:List files in ref with change/commit count' 'copy-branch-name:Copy the current branch name to the clipboard (pbcopy)' 'credit:A very slightly quicker way to credit an author on the latest commit' 'current-branch:Print the name of the current branch, helpful for automation' 'cut-branch:Create a new named branch pointed at HEAD and reset the current branch to the head of its tracking branch' 'delete-local-merged:Delete all local branches that have been merged into HEAD' 'divergence:List local/remote (incoming/outgoing) changes for current branch' 'find-dirty:Recurse current directory, listing "dirty" git clones' 'flush:Recompactify your repo to be as small as possible' 'grab:Add github remote, by username and repo' 'ignored:List files currently being ignored by .gitignore' 'improved-merge:Sophisticated git merge with integrated CI check and automatic cleanup upon completion' 'incoming:Fetch remote tracking branch, and list incoming commits' 'ls-object-refs:Find references to <object> SHA1 in refs, commits, and trees. All of them' maildiff: 'Simple git command to email diff in color to reviewer/co-worker & optionally attach patch file.' 'maxpack:Repack with maximum compression' 'nuke:Nukes a branch locally and on the origin remote' 'object-deflate:Deflate an loose object file and write to standard output' 'outgoing:Fetch remote tracking branch, and list outgoing commits' 'pie-ify:Apply perl pie, on the fly' 'promote:Promotes a local topic branch to a remote tracking branch of the same name, by pushing and then setting up the git config' 'pruneall:Prune branches from specified remotes, or all remotes when <remote> not specified' 'prune-branches:Simple script that cleans up unnecessary branches' 'publish:Pushes/publishes current branch to specified remote' 'purge-from-history:Script to permanently delete files/folders from your git repository' 'rank-contributors:A simple script to trace through the logs and rank contributors by the total size of the diffs they'\''re responsible for' 'rebase-authors:Adds authorship info to interactive git rebase output' 'rel:Shows the relationship between the current branch and <ref>' 'root-directory:Print the root of the git checkout you'\''re in' 'run-command-on-revisions:Runs a given command over a range of Git revisions' 'shamend:Amends your staged changes as a fixup to the specified older commit in the current branch' 'show-overwritten:Aggregates git blame information about original owners of lines changed or removed in the '\''<base>...<head>'\'' diff' 'sp:'\''Simple push'\'', commits and pushes. Use -a flag to add' 'submodule-rm:Remove submodules from current repo' 'thanks:List authors with commit count' 'track:Sets up your branch to track a remote branch' 'trail:Show all branching points in Git history' 'undo-push:Undo your last push to branch ($1) of origin' 'unpushed:Show the diff of everything you haven'\''t pushed yet' 'unpushed-stat:Show the diffstat of everything you haven'\''t pushed yet' 'unreleased:Shows git commits since the last tagged version' 'up-old:Like git-pull but show a short and sexy log of changes immediately after merging (git-up) or rebasing (git-reup)' 'upstream-sync:Sync to upstream/yourforkname and rebase into your local fork, then push' 'when-merged:Find when a commit was merged into one or more branches' 'where:Shows where a particular commit falls between releases' 'winner:Determines "winner" by commit count, and number of lines' 'wordiness:List commit message word and line counts per contributor' 'wtf:Displays the state of your repository in a readable, easy-to-scan format' 'alias:define, search and show aliases' 'abort:abort current revert, merge, rebase, or cherry-pick process' 'archive-file:export the current head of the git repository to an archive' 'authors:generate authors report' 'browse:open repo website in browser' 'browse-ci:open repo CI page in browser' 'bug:create bug branch' 'bulk:run bulk commands' 'brv:list branches sorted by their last commit date' 'changelog:generate a changelog report' 'chore:create chore branch' 'clear-soft:soft clean up a repository' 'clear:rigorously clean up a repository' 'coauthor:add a co-author to the last commit' 'commits-since:show commit logs since some date' 'contrib:show user contributions' 'count:show commit count' 'create-branch:create branches' 'delete-branch:delete branches' 'delete-merged-branches:delete merged branches' 'delete-squashed-branches:delete squashed branches' 'delete-submodule:delete submodules' 'delete-tag:delete tags' 'delta:lists changed files' 'effort:show effort statistics on file(s)' 'extras:awesome git utilities' 'feature:create/merge feature branch' 'force-clone:overwrite local repositories with clone' 'fork:fork a repo on GitHub' 'fresh-branch:create fresh branches' 'gh-pages:create the GitHub pages branch' 'graft:merge and destroy a given branch' 'guilt:calculate change between two revisions' 'ignore-io:get sample gitignore file' 'ignore:add .gitignore patterns' 'info:returns information on current repository' 'local-commits:list local commits' 'lock:lock a file excluded from version control' 'locked:ls files that have been locked' 'magic:commits everything with a generated message' 'merge-into:merge one branch into another' 'merge-repo:merge two repo histories' 'missing:show commits missing from another branch' 'mr:checks out a merge request locally' 'obliterate:rewrite past commits to remove some files' 'paste:send patches to pastebin sites' 'pr:checks out a pull request locally' 'psykorebase:rebase a branch with a merge commit' 'pull-request:create pull request to GitHub project' 'reauthor:replace the author and/or committer identities in commits and tags' 'rebase-patch:rebases a patch' 'refactor:create refactor branch' 'release:commit, tag and push changes to the repository' 'rename-branch:rename a branch' 'rename-tag:rename a tag' 'rename-remote:rename a remote' 'repl:git read-eval-print-loop' 'reset-file:reset one file' 'root:show path of root' 'scp:copy files to ssh compatible `git-remote`' 'sed:replace patterns in git-controlled files' 'setup:set up a git repository' 'show-merged-branches:show merged branches' 'show-tree:show branch tree of commit history' 'show-unmerged-branches:show unmerged branches' 'squash:import changes from a branch' 'stamp:stamp the last commit message' 'standup:recall the commit history' 'summary:show repository summary' 'sync:sync local branch with remote branch' 'touch:touch and add file to the index' 'undo:remove latest commits' 'unlock:unlock a file excluded from version control' 'utimes:change files modification time to their last commit date'
zstyle ':completion:*' verbose yes
