<<<<<<< HEAD
;;; early-init.el --- Doom's universal bootstrapper -*- lexical-binding: t -*-
;;; Commentary:
;;
;; This file, in summary:
;; - Determines where `user-emacs-directory' is by:
;;   - Processing `--init-directory DIR' (backported from Emacs 29),
;;   - Processing `--profile NAME' (see
;;     `https://docs.doomemacs.org/-/developers' or docs/developers.org),
;;   - Or assume that it's the directory this file lives in.
;; - Loads Doom as efficiently as possible, with only the essential startup
;;   optimizations, and prepares it for interactive or non-interactive sessions.
;; - If Doom isn't present, then we assume that Doom is being used as a
;;   bootloader and the user wants to load a non-Doom config, so we undo all our
;;   global side-effects, load `user-emacs-directory'/early-init.el, and carry
;;   on as normal (without Doom).
;; - Do all this without breaking compatibility with Chemacs.
;;
;; early-init.el was introduced in Emacs 27.1. It is loaded before init.el,
;; before Emacs initializes its UI or package.el, and before site files are
;; loaded. This is great place for startup optimizing, because only here can you
;; *prevent* things from loading, rather than turn them off after-the-fact.
;;
;; Doom uses this file as its "universal bootstrapper" for both interactive and
;; non-interactive sessions. That means: no matter what environment you want
;; Doom in, load this file first.
;;
;;; Code:

(let (file-name-handler-alist)
  ;; PERF: Garbage collection is a big contributor to startup times in both
  ;;   interactive and CLI sessions, so I defer it.
  (if noninteractive  ; in CLI sessions
      ;; PERF: GC deferral is less important in the CLI, but still helps script
      ;;   startup times. Just don't set it too high to avoid runaway memory
      ;;   usage in long-running elisp shell scripts.
      (setq gc-cons-threshold 134217728  ; 128mb
            ;; Backported from 29 (see emacs-mirror/emacs@73a384a98698)
            gc-cons-percentage 1.0)
    ;; PERF: Doom relies on `gcmh-mode' to reset this while the user is idle, so
    ;;   I effectively disable GC during startup. DON'T COPY THIS BLINDLY! If
    ;;   it's not reset later there will be stuttering, freezes, and crashes.
    (setq gc-cons-threshold most-positive-fixnum))

  ;; PERF: Don't use precious startup time to check mtimes on elisp bytecode.
  ;;   Ensuring correctness is 'doom sync's job. Although stale byte-code will
  ;;   heavily impact startup times, performance is unimportant when Emacs is in
  ;;   an error state.
  (setq load-prefer-newer noninteractive)

  ;; UX: Respect DEBUG envvar as an alternative to --debug-init, and to make
  ;;   startup more verbose sooner.
  (let ((debug (getenv-internal "DEBUG")))
    (when (stringp debug)
      (if (string-empty-p debug)
          (setenv "DEBUG" nil)
        (setq init-file-debug t
              debug-on-error t))))

  (let (;; FIX: Unset `command-line-args' in noninteractive sessions, to
        ;;   ensure upstream switches aren't misinterpreted.
        (command-line-args (unless noninteractive command-line-args))
        ;; I avoid using `command-switch-alist' to process --profile (and
        ;; --init-directory) because it is processed too late to change
        ;; `user-emacs-directory' in time.
        (profile (or (cadr (member "--profile" command-line-args))
                     (getenv-internal "DOOMPROFILE"))))
    (if (null profile)
        ;; REVIEW: Backported from Emacs 29. Remove when 28 support is dropped.
        (let ((init-dir (or (cadr (member "--init-directory" command-line-args))
                            (getenv-internal "EMACSDIR"))))
          (if (null init-dir)
              ;; FIX: If we've been loaded directly (via 'emacs -batch -l
              ;;   early-init.el') or by a doomscript (like bin/doom), and Doom
              ;;   is in a non-standard location (and/or Chemacs is used), then
              ;;   `user-emacs-directory' will be wrong.
              (when noninteractive
                (setq user-emacs-directory
                      (file-name-directory (file-truename load-file-name))))
            ;; FIX: To prevent "invalid option" errors later.
            (push (cons "--init-directory" (lambda (_) (pop argv))) command-switch-alist)
            (setq user-emacs-directory (expand-file-name init-dir))))
      ;; FIX: Discard the switch to prevent "invalid option" errors later.
      (push (cons "--profile" (lambda (_) (pop argv))) command-switch-alist)
      ;; Running 'doom sync' or 'doom profile sync --all' (re)generates a light
      ;; profile loader in $XDG_DATA_HOME/doom/profiles.X.el (or
      ;; $DOOMPROFILELOADFILE), after reading `doom-profile-load-path'. This
      ;; loader requires `$DOOMPROFILE' be set to function.
      (setenv "DOOMPROFILE" profile)
      (or (load (let ((windows? (memq system-type '(ms-dos windows-nt cygwin))))
                  (expand-file-name
                   (format (or (getenv-internal "DOOMPROFILELOADFILE")
                               (file-name-concat (if windows? "doomemacs/data" "doom")
                                                 "profiles.%d"))
                           emacs-major-version)
                   (or (if windows? (getenv-internal "LOCALAPPDATA"))
                       (getenv-internal "XDG_DATA_HOME")
                       "~/.local/share")))
                'noerror (not init-file-debug))
          (user-error "Profiles not initialized yet; run 'doom sync' first"))))

  ;; PERF: When `load'ing or `require'ing files, each permutation of
  ;;   `load-suffixes' and `load-file-rep-suffixes' (then `load-suffixes' +
  ;;   `load-file-rep-suffixes') is used to locate the file. Each permutation
  ;;   amounts to at least one file op, which is normally very fast, but can add
  ;;   up over the hundreds/thousands of files Emacs loads.
  ;;
  ;;   To reduce that burden -- and since Doom doesn't load any dynamic modules
  ;;   this early -- I remove `.so' from `load-suffixes' and pass the
  ;;   `must-suffix' arg to `load'. See the docs of `load' for details.
  (if (let ((load-suffixes '(".elc" ".el"))
            (doom (expand-file-name "lisp/doom" user-emacs-directory)))
        ;; I avoid `load's NOERROR argument because it suppresses other,
        ;; legitimate errors (like permission or IO errors), which gets
        ;; incorrectly interpreted as "this is not a Doom config".
        (if (file-exists-p (concat doom ".el"))
            ;; Load the heart of Doom Emacs.
            (load doom nil (not init-file-debug) nil 'must-suffix)
          ;; Failing that, assume we're loading a non-Doom config...
          ;; HACK: `startup--load-user-init-file' resolves $EMACSDIR from a
          ;;   lexical (and so, not-trivially-modifiable)
          ;;   `startup-init-directory', so Emacs will fail to locate the
          ;;   correct $EMACSDIR/init.el without help.
          (define-advice startup--load-user-init-file (:filter-args (args) reroute-to-profile)
            (list (lambda () (expand-file-name "init.el" user-emacs-directory))
                  nil (nth 2 args)))
          ;; (Re)set `user-init-file' for the `load' call further below, and do
          ;; so here while our `file-name-handler-alist' optimization is still
          ;; effective (benefits `expand-file-name'). BTW: Emacs resets
          ;; `user-init-file' and `early-init-file' after this file is loaded.
          (setq user-init-file (expand-file-name "early-init" user-emacs-directory))
          ;; COMPAT: I make no assumptions about the config we're going to load,
          ;;   so undo this file's global side-effects.
          (setq load-prefer-newer t)
          ;; PERF: But make an exception for `gc-cons-threshold', which I think
          ;;   all Emacs users and configs will benefit from. Still, setting it
          ;;   to `most-positive-fixnum' is dangerous if downstream does not
          ;;   reset it later to something reasonable, so I use 16mb as a best
          ;;   fit guess. It's better than Emacs' 80kb default.
          (setq gc-cons-threshold (* 16 1024 1024))
          nil))
      ;; Sets up Doom (particularly `doom-profile') for the session ahead. This
      ;; loads the profile's init file, if it's available. In interactive
      ;; session, a missing profile is an error state, in a non-interactive one,
      ;; it's not (and left to the consumer to deal with).
      (doom-initialize (not noninteractive))
    ;; If we're here, the user wants to load another config/profile (that may or
    ;; may not be a Doom config).
    (load user-init-file 'noerror (not init-file-debug) nil 'must-suffix)))

=======
;;; early-init.el --- Elpaca Example Config -*- lexical-binding: t; no-byte-compile: t; -*-

;; Copyright (C) 2024
;; SPDX-License-Identifier: MIT

;; Author: System Crafters Community

;;; Commentary:

;; Example early-init.el for using the Elpaca package manager.
;; This does *not* load crafted-early-init-config
;; (which would normally bootstrap package.el).

;;; Code:


;;; ** {{{ custom.el
;; Normally, options configured in `user-init-file' won't need to be persisted
;; to `custom-file', but by default, when using package.el for package
;; management, `package-selected-packages' will always be written to
;; `custom-file' if available. See `init-package' for details.
(customize-set-variable 'custom-file (expand-file-name "var/custom.el" user-emacs-directory))

(customize-set-variable 'crafted-emacs-home (expand-file-name (file-name-as-directory "crafted-emacs") user-emacs-directory))

;; (add-hook 'kill-emacs-query-functions 'custom-prompt-customize-unsaved-options)

;;; ** }}} custom.el

;;; ** {{{ performancxe
;;; *** redirect eln-cache
(customize-set-variable 'ceamx-eln-dir (expand-file-name (file-name-as-directory "var/eln-cache") user-emacs-directory))
(customize-set-variable 'native-comp-eln-load-path (list (expand-file-name (file-name-as-directory "var/eln-cache") user-emacs-directory)))
(push ceamx-eln-dir native-comp-eln-load-path)
(startup-redirect-eln-cache ceamx-eln-dir)
(push ceamx-eln-dir native-comp-eln-load-path)

(customize-set-variable 'native-comp-async-report-warnings-errors 'silent)
(customize-set-variable 'native-compile-prune-cache t)

;;; *** file-name-handler-alist
;; Skipping a bunch of regular expression searching in the =file-name-handler-alist= should improve start time.
(defvar default-file-name-handler-alist file-name-handler-alist)
(customize-set-variable 'file-name-handler-alist nil)

;;; *** {{{ garbage collection
;; =gc-cons-threshold= (800 KB) and =gc-cons-percentage= (0.1) control when the Emacs garbage collector can kick in.
;; Temporarily turning these off during init should decrease startup time.
;; Resetting them afterward will ensure that normal operations don't suffer from a large GC periods.
;;
;; The following is a table shows values from popular Emacs configurations.
;;
;; | Distribution | gc-cons-threshold |
;; |--------------+-------------------|
;; | Default      |            800000 |
;; | Doom         |          16777216 |
;; | Spacemacs    |         100000000 |

(defvar default-gc-cons-percentage)
(defvar default-gc-cons-threshold)
(customize-set-variable 'default-gc-cons-percentage gc-cons-percentage)
(customize-set-variable 'default-gc-cons-threshold  16777216)
(customize-set-variable 'garbage-collection-messages nil)
(setq gc-cons-percentage 1)
(setq gc-cons-threshold most-positive-fixnum)

(defun +gc-after-focus-change ()
  "Run GC when frame loses focus."
  (run-with-idle-timer 5 nil
    (lambda () (unless (frame-focus-state) (garbage-collect)))))

(defun +reset-init-values ()
  (run-with-idle-timer 1 nil
    (lambda ()
      (setq file-name-handler-alist default-file-name-handler-alist)
      (setq gc-cons-percentage default-gc-cons-percentage)  ;; 0.1)
      (setq gc-cons-threshold default-gc-cons-threshold)    ;; 100000000)
      (message "gc-cons-threshold & file-name-handler-alist restored")
      (when (boundp 'after-focus-change-function)
          (add-function :after after-focus-change-function #'+gc-after-focus-change)))))

(with-eval-after-load 'elpaca
  (add-hook 'elpaca-after-init-hook '+reset-init-values))
(setenv "LSP_USE_PLISTS" "true")

;; Read JSON streams in 1MiB chunks instead of the default 4kB.
;;
;; Language server responses tend to be in the 800kB to 3MB range,
;; according to the lsp-mode documentation (linked above).
;;
;; This is a general LSP concern, not specific to any particular implementation.
(when (functionp 'json-serialize)
    (customize-set-variable 'read-process-output-max (* 1024 1024)))

;;; }}} *** garbage collection
;;; }}} ** performancxe

;;; {{{ *** elpaca
;; In Emacs 27+, package initialization occurs before `user-init-file' is
;; loaded, but after `early-init-file'

;; (customize-set-variable 'package-enable-at-startup nil)

(unless after-init-time
  (when (featurep 'package)
      (unload-feature 'package)))

;;; }}} *** elpaca

;;; {{{ *+ quieter
(customize-set-variable 'byte-compile-warnings '(not obsolete))
(customize-set-variable 'inhibit-default-init nil)
(customize-set-variable 'inhibit-startup-echo-area-message (user-login-name))
(customize-set-variable 'warning-suppress-log-types '((comp) (bytecomp)))
;;; }}} ** quieter

;;; ** {{{ debugging
;; Running this form will launch the debugger after loading a package.
;; This is useful for finding out when a dependency is requiring a package (perhaps earlier than you want).
;; Use by tangling this block and launching Emacs with =emacs --debug-init=.
;; #+begin_src emacs-lisp :var file="" :results silent :tangle no
;; (let ((file ""))
;;   (unless (string-empty-p file)
;;       (eval-after-load file
;;         '(debug))))
;;
;; ;; Similarly, this variable will hit the debugger when a message matches its regexp.
;; (custom-set-variables '(debug-on-message ""))
;;
;; ;; Adding a variable watcher can be a useful way to track down initialization and mutation of a variable.
;; (add-variable-watcher 'org-capture-after-finalize-hook
;;                         (lambda (symbol newval operation where)
;;                           (debug)
;;                           (message "%s set to %s" symbol newval)))
;;
;; (customize-set-variable 'debug-on-error t)
;;; ** }}} debugging

;;; {{{ ** UI
;;; Turning off these visual elements before UI initialization should speed up init.
;; (push '(menu-bar-lines . 0) default-frame-alist)
;; (push '(tool-bar-lines . 0) default-frame-alist)
;; (push '(vertical-scroll-bars) default-frame-alist)

;;; Prevent instructions on how to close an emacsclient frame.
;;(custom-set-variables '(server-client-instructions nil))

;;; Implicitly resizing the Emacs frame adds to init time.
;;; Fonts larger than the system default can cause frame resizing, which adds to startup time.
(customize-set-variable 'frame-inhibit-implied-resize t)

;;; + Set default and backup fonts
(push '(font . "OpenDyslexic Nerd Font") default-frame-alist)
(set-face-font 'default "OpenDyslexic Nerd Font")
(set-face-font 'fixed-pitch "OpenDyslexicM Nerd Font")
(set-face-font 'variable-pitch "OpenDyslexic Nerd Font Propo")
(copy-face 'default 'fixed-pitch)


;; Allow answering yes/no questions with y/n.
(defalias 'yes-or-no-p 'y-or-n-p)
(customize-set-variable 'use-short-answers t)       ;; affects `yes-or-no-p'
(customize-set-variable 'read-answer-short t)       ;; affects `read-answer' (completion)

;; Avoid expensive frame resizing.
(customize-set-variable 'frame-inhibit-implied-resize t)

;; Allow resizing the frame to the maximum available space on the desktop.
(customize-set-variable 'frame-resize-pixelwise t)

;;; + Ignore X resources.
(advice-add #'x-apply-session-resources :override #'ignore)
;; Prevent X11 from taking control of visual behavior and appearance.
(customize-set-variable 'inhibit-x-resources t)

;;; + Taken from:
;;; [[https://github.com/vsemyonoff/emacsrc/blob/14649a5bafea99cc7e13e7d048e9d15aed7926ce/early-init.el]]

;;; + This helps with a bug I was hitting when using =desktop-save-mode='s =desktop-read=.
(customize-set-variable 'desktop-restore-forces-onscreen nil)
;;; }}} ** UI

;; {{{ ** profiling
;; This function displays how long Emacs took to start.
;; It's a rough way of knowing when/if I need to optimize my init file.
(add-hook 'elpaca-after-init-hook
          #'(lambda ()
              (message
                "Emacs loaded in %s with %d garbage collections."
                (format "%.2f seconds"
                        (float-time
                          (time-subtract (current-time) before-init-time)))
                gcs-done)))

;; We can also enable the profiler to view a report after init.
(profiler-start 'cpu+mem)
(add-hook 'elpaca-after-init-hook #'(lambda () (profiler-stop)))  ;; (profiler-report)))

;; ELP is useful for seeing which functions in a package are "hot".
;; #+begin_src emacs-lisp :var file="elpaca" :lexical t :tangle no
;; (require 'elp)
;; (let ((file "elpaca"))
;;   (with-eval-after-load file
;;     (elp-instrument-package file))
;;   (add-hook 'elpaca-after-init-hook
;;             #'(lambda () (elp-results) (elp-restore-package (intern file)))))
;; }}} ** profiling

;;; {{{ ** General theme code

(defun prot-emacs-re-enable-frame-theme (_frame)
  "Re-enable active theme, if any, upon FRAME creation.
Add this to `after-make-frame-functions' so that new frames do
not retain the generic background set by the function
`prot-emacs-avoid-initial-flash-of-light'."
  (when-let ((theme (car custom-enabled-themes)))
      (enable-theme theme)))

;; NOTE 2023-02-05: The reason the following works is because (i) the
;; `mode-line-format' is specified again and (ii) the
;; `prot-emacs-theme-gsettings-dark-p' will load a dark theme.
(defun prot-emacs-avoid-initial-flash-of-light ()
  "Avoid flash of light when starting Emacs, if needed.
New frames are instructed to call `prot-emacs-re-enable-frame-theme'."
  (when t
      (setq mode-line-format nil)
      (set-face-attribute 'default nil :background "#000000" :foreground "#ffffff")
      (set-face-attribute 'mode-line nil :background "#000000" :foreground "#ffffff" :box 'unspecified)
      (add-hook 'after-make-frame-functions #'prot-emacs-re-enable-frame-theme)))

(prot-emacs-avoid-initial-flash-of-light)
;;; }}} ** General theme code

(defvar ceamx-default-frame-name "home — [s-a-c-macos-elpaca]"
  "Name for the default Emacs frame.")

(defun ceamx-after-init-default-frame-name-h ()
  "Set the name for the default frame.\n Simple wrapper for a call to `set-frame-name', providing\n  `ceamx-default-frame-name' as the NAME argument.\n\n Intended for use as a callback on the `ceamx-after-init-hook'."
  (set-frame-name ceamx-default-frame-name))

(add-hook 'elpaca-after-init-hook #'ceamx-after-init-default-frame-name-h)

(add-hook 'elpaca-after-init-hook #'(lambda () (setq debug-on-error t)))


;;; _
(provide 'early-init)
>>>>>>> origin/develop
;;; early-init.el ends here
