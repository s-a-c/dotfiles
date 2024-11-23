;;; init.el --- Crafted Emacs Elpaca Example -*- lexical-binding: t; no-byte-compile: t; -*-

;; Copyright (C) 2024
;; SPDX-License-Identifier: MIT

;; Author: s-a-c

;;; Commentary:

;; Example init.el for using the Elpaca package manager.

;;; Code:


;;; {{{ * Initial phase

;; If a `custom-modules' directory exists in the
;; `user-emacs-directory', include it on the load-path.
(let ((custom-modules (expand-file-name "custom-modules" user-emacs-directory)))
  (when (file-directory-p custom-modules)
    (message "adding custom-modules to load-path: %s" custom-modules)
    (add-to-list 'load-path custom-modules)))

(require 'ews-my)

(require 'opam-init)

(defun +my/list-features ()
  "List all requirable features: https://stackoverflow.com/questions/18173799/list-all-requirable-features."
  (interactive)
  (dolist (dirname load-path)
    (shell-command (concat "grep --no-filename --text '\(provide \\|\(autoload ' " dirname "/*.{el,elc}") "tmp")
    (switch-to-buffer "tmp")
    (append-to-buffer "+features" (point-min) (point-max)))
  ;; Remove duplicates from finding provided functions in both .el and .elc files
  (switch-to-buffer "+features")
  (shell-command-on-region (point-min) (point-max) "sort -u" nil t nil nil))


;;; {{{ ** packaging
;;; {{{ *** package.el
(customize-set-variable 'package-archives '(("elpa-gnu" . "https://elpa.gnu.org/packages/") ("elpa-gnu-devel" . "https://elpa.gnu.org/devel/") ("elpa-nongnu" . "https://elpa.nongnu.org/nongnu/") ("elpa-nongnu-devel" . "https://elpa.nongnu.org/nongnu-devel/") ("melpa-stable" . "https://stable.melpa.org/packages/") ("melpa" . "https://melpa.org/packages/")))

(customize-set-variable 'package-archive-priorities '(("elpa-gnu" . 90) ("melpa-stable" . 70) ("melpa" . 50) ("elpa-nongnu" . 30)))

;; Initialise installed packages at this early stage, by using the
;; available cache.    I had tried a setup with this set to nil in the
;; early-init.el, but (i) it ended up being slower and (ii) various
;; package commands, like `describe-package', did not have an index of
;; packages to work with, requiring a `package-refresh-contents'.
;; (custom-set-variables '(package-enable-at-startup t))
;;; }}} *** package.el


;;; {{{ *** elpaca
;; In Emacs 27+, package initialization occurs before `user-init-file' is
;; loaded, but after `early-init-file'
;; (customize-set-variable 'package-enable-at-startup nil)
(defvar package-selected-packages '())

;; Do not allow loading from the package cache (same reason).
;; (customize-set-variable 'package-quickstart nil)
;; (customize-set-variable 'package-install-upgrade-built-in t)
;; (customize-set-variable 'package-vc-register-as-project nil)

;;; {{{ **** source https://github.com/progfolio/elpaca/blob/master/doc/init.el
;; Example Elpaca configuration -*- lexical-binding: t; -*-

(defvar elpaca-installer-version 0.7)
(defvar elpaca-directory (expand-file-name "var/elpaca/" user-emacs-directory))
(defvar elpaca-builds-directory (expand-file-name "builds/" elpaca-directory))
(defvar elpaca-repos-directory (expand-file-name "repos/" elpaca-directory))
(defvar elpaca-order '(elpaca :repo "https://github.com/progfolio/elpaca.git"
                              :ref nil :depth 1
                              :files (:defaults "elpaca-test.el" (:exclude "extensions"))
                              :build (:not elpaca--activate-package)))
(let* ((repo  (expand-file-name "elpaca/" elpaca-repos-directory))
       (build (expand-file-name "elpaca/" elpaca-builds-directory))
       (order (cdr elpaca-order))
       (default-directory repo))
  (add-to-list 'load-path (if (file-exists-p build) build repo))
  (unless (file-exists-p repo)
    (make-directory repo t)
    (when (< emacs-major-version 28) (require 'subr-x))
    (condition-case-unless-debug err
        (if-let ((buffer (pop-to-buffer-same-window "*elpaca-bootstrap*"))
                 ((zerop (apply #'call-process `("git" nil ,buffer t "clone"
                                                 ,@(when-let ((depth (plist-get order :depth)))
                                                     (list (format "--depth=%d" depth) "--no-single-branch"))
                                                 ,(plist-get order :repo) ,repo))))
                 ((zerop (call-process "git" nil buffer t "checkout"
                                       (or (plist-get order :ref) "--"))))
                 (emacs (concat invocation-directory invocation-name))
                 ((zerop (call-process emacs nil buffer nil "-Q" "-L" "." "--batch"
                                       "--eval" "(byte-recompile-directory \".\" 0 'force)")))
                 ((require 'elpaca))
                 ((elpaca-generate-autoloads "elpaca" repo)))
            (progn (message "%s" (buffer-string)) (kill-buffer buffer))
          (error "%s" (with-current-buffer buffer (buffer-string))))
      ((error) (warn "%s" err) (delete-directory repo 'recursive))))
  (unless (require 'elpaca-autoloads nil t)
    (require 'elpaca)
    (elpaca-generate-autoloads "elpaca" repo)
    (load "./elpaca-autoloads")))
(add-hook 'after-init-hook                  #'elpaca-process-queues)
(elpaca `(,@elpaca-order))

;; Uncomment for systems which cannot create symlinks:
;; (elpaca-no-symlink-mode)

;; Install a package via the elpaca macro
;; See the "recipes" section of the manual for more details.

;; (elpaca example-package)

(customize-set-variable 'package-native-compile t)
(customize-set-variable 'use-package-always-defer t)
(customize-set-variable 'use-package-always-ensure t)
(customize-set-variable 'use-package-hook-name-suffix nil)

(elpaca use-package)

;; Install use-package support
(elpaca elpaca-use-package
  ;; Enable use-package :ensure support for Elpaca.
  (elpaca-use-package-mode))

;; Block until current queue processed.
(elpaca-wait)

;; ;;When installing a package which modifies a form used at the top-level
;; ;;(e.g. a package which adds a use-package key word),
;; ;;use `elpaca-wait' to block until that package has been installed/configured.
;; ;;For example:
;; ;;(use-package general :ensure t :demand t)
;; ;;(elpaca-wait)
;;
;; ;; Expands to: (elpaca evil (use-package evil :demand t))
;; (use-package evil :ensure t :demand t)
;;
;; ;;Turns off elpaca-use-package-mode current declaration
;; ;;Note this will cause the declaration to be interpreted immediately (not deferred).
;; ;;Useful for configuring built-in emacs features.
;; (use-package emacs :ensure nil :config (customize-set-variable 'ring-bell-function #'ignore))
;;
;; ;; Don't install anything. Defer execution of BODY
;; (elpaca nil (message "deferred"))

;;; }}} **** source https://github.com/progfolio/elpaca/blob/master/doc/init.el


;;;; Improve `use-package' debuggability if necessary

(customize-set-variable 'use-package-expand-minimally nil)
(customize-set-variable 'use-package-verbose t)
(customize-set-variable 'use-package-compute-statistics t)
(when (bound-and-true-p init-file-debug)
    ;; (require 'use-package)
    (customize-set-variable 'use-package-expand-minimally nil)
    (customize-set-variable 'use-package-verbose t)
    (customize-set-variable 'use-package-compute-statistics t))


(add-hook 'elpaca-after-init-hook           #'recentf-mode)


;;; {{{ **** blackout
;;;; Initialize miscellaneous packages adding `use-package' keywords

;; NOTE: `blackout' is still useful even without `use-package'
(elpaca blackout
  (add-to-list 'package-selected-packages 'blackout)
  (require 'blackout))
;;; }}} **** blackout

;;; {{{ **** delight
(elpaca delight
  (add-to-list 'package-selected-packages 'delight))
;;; }}} **** delight

;;; {{{ **** diminish
(elpaca diminish
  (add-to-list 'package-selected-packages 'diminish))
;;; }}} **** diminidh

;;; {{{ **** gcmh
;;;; Run garbage collection on idle

;; <https://gitlab.com/koral/gcmh>
;; <https://akrl.sdf.org/>

;; During normal use, the GC threshold will be set to a high value.
;; When idle, GC will be triggered with a low threshold.

(elpaca gcmh
(use-package gcmh
  :init (add-to-list 'package-selected-packages 'gcmh)
  :custom
    (gcmh-high-cons-threshold (* 16 1024 1024))
  :blackout
  :commands (gcmh-mode)
  :config
    (add-hook 'elpaca-after-init-hook       #'gcmh-mode)))
;;; }}} **** gcmh

;;; {{{ **** hydra
(elpaca hydra
(use-package hydra
  :init (add-to-list 'package-selected-packages 'hydra)
  :config
    (defhydra hydra-buffer-menu (:color pink :hint nil)
    "
^Mark^             ^Unmark^           ^Actions^          ^Search
^^^^^^^^-----------------------------------------------------------------
_m_: mark          _u_: unmark        _x_: execute       _R_: re-isearch
_s_: save          _U_: unmark up     _b_: bury          _I_: isearch
_d_: delete        ^ ^                _g_: refresh       _O_: multi-occur
_D_: delete up     ^ ^                _T_: files only: % -28`Buffer-menu-files-only
_~_: modified
"
      ("D" Buffer-menu-delete-backwards)
      ("I" Buffer-menu-isearch-buffers :color blue)
      ("O" Buffer-menu-multi-occur :color blue)
      ("R" Buffer-menu-isearch-buffers-regexp :color blue)
      ("T" Buffer-menu-toggle-files-only)
      ("U" Buffer-menu-backup-unmark)
      ("b" Buffer-menu-bury)
      ("c" nil "cancel")
      ("d" Buffer-menu-delete)
      ("g" revert-buffer)
      ("m" Buffer-menu-mark)
      ("o" Buffer-menu-other-window "other-window" :color blue)
      ("q" quit-window "quit" :color blue)
      ("s" Buffer-menu-save)
      ("u" Buffer-menu-unmark)
      ("v" Buffer-menu-select "select" :color blue)
      ("x" Buffer-menu-execute)
      ("~" Buffer-menu-not-modified))
    (keymap-set buffer-menu-mode-map "." 'hydra-buffer-menu/body)))

;;; {{{ ***** major-mode-hydra
(use-package major-mode-hydra
  :after hydra
  :init (add-to-list 'package-selected-packages 'major-mode-hydra)
  ;; :bind (
  ;;   ("M-SPC"            . major-mode-hydra))
  :config
    (major-mode-hydra-define emacs-lisp-mode nil
      ( "Doc" (
          ("d" describe-foo-at-point "thing-at-pt")
          ("f" describe-function "function")
          ("i" info-lookup-symbol "info lookup")
          ("v" describe-variable "variable"))
        "Eval" (
          ("b" eval-buffer "buffer")
          ("e" eval-defun "defun")
          ("r" eval-region "region"))
        "REPL" (
          ("I" ielm "ielm"))
        "Test" (
          ("F" (ert :failed) "failed")
          ("T" (ert t) "all")
          ("t" ert "prompt")))))
;;; }}} ***** major-mode-hydra

;;; {{{ ***** use-package-hydra
(use-package use-package-hydra
  :init (add-to-list 'package-selected-packages 'use-package-hydra))
;;; }}} ***** use-package-hydra
;;; }}} **** hydra

;;; **** keychain
;; [[https://www.funtoo.org/Keychain][Keychain]] is a gpg/ssh agent that allows me to cache my credentials.
;; This package gets the correct environment variables so elpaca can use the ssh protocol.
;; We need this loaded for SSH protocol
(elpaca keychain-environment
  (require 'keychain-environment)
  (keychain-refresh-environment))

;;; **** melpulls
;; An Elpaca menu for MELPA submissions.
(elpaca '(melpulls :host github :repo "progfolio/melpulls")
  (add-to-list 'elpaca-menu-functions #'melpulls))

;;; **** mode-line-bell
;;; [[https://melpa.org/#/mode-line-bell][mode-line-bell]] - Flash the mode line instead of ringing the bell
(elpaca mode-line-bell
  (mode-line-bell-mode))

;;; **** no-littering
(elpaca no-littering
  (customize-set-variable 'no-littering-etc-directory (expand-file-name "etc/" user-emacs-directory))
  (customize-set-variable 'no-littering-var-directory (expand-file-name "var/" user-emacs-directory))
  (require 'no-littering))

;;; {{{ *** shrface
(elpaca shrface
(use-package shrface
  :init (add-to-list 'package-selected-packages 'shrface)
  :custom
    (shrface-href-versatile t)
  :config
    (shrface-basic)
    (shrface-trial)
    (shrface-default-keybindings)
    (with-eval-after-load 'eww
      (define-key eww-mode-map          (kbd "<tab>")   'shrface-outline-cycle)
      (define-key eww-mode-map          (kbd "S-<tab>") 'shrface-outline-cycle-buffer)
      (define-key eww-mode-map          (kbd "C-t")     'shrface-toggle-bullets)
      (define-key eww-mode-map          (kbd "C-j")     'shrface-next-headline)
      (define-key eww-mode-map          (kbd "C-k")     'shrface-previous-headline)
      (define-key eww-mode-map          (kbd "M-l")     'shrface-links-consult)
      (define-key eww-mode-map          (kbd "M-h")     'shrface-headline-consult))
    (with-eval-after-load 'mu4e
      (define-key mu4e-view-mode-map    (kbd "<tab>")   'shrface-outline-cycle)
      (define-key mu4e-view-mode-map    (kbd "S-<tab>") 'shrface-outline-cycle-buffer)
      (define-key mu4e-view-mode-map    (kbd "C-t")     'shrface-toggle-bullets)
      (define-key mu4e-view-mode-map    (kbd "C-j")     'shrface-next-headline)
      (define-key mu4e-view-mode-map    (kbd "C-k")     'shrface-previous-headline)
      (define-key mu4e-view-mode-map    (kbd "M-l")     'shrface-links-consult)
      (define-key mu4e-view-mode-map    (kbd "M-h")     'shrface-headline-consult))
    (with-eval-after-load 'nov
      (define-key nov-mode-map          (kbd "<tab>")   'shrface-outline-cycle)
      (define-key nov-mode-map          (kbd "S-<tab>") 'shrface-outline-cycle-buffer)
      (define-key nov-mode-map          (kbd "C-t")     'shrface-toggle-bullets)
      (define-key nov-mode-map          (kbd "C-j")     'shrface-next-headline)
      (define-key nov-mode-map          (kbd "C-k")     'shrface-previous-headline)
      (define-key nov-mode-map          (kbd "M-l")     'shrface-links-consult)
      (define-key nov-mode-map          (kbd "M-h")     'shrface-headline-consult))
))
;;; }}} *** shrface

;;; **** exec-path-from-shell
(use-package exec-path-from-shell
  :demand t
  :init (add-to-list 'package-selected-packages 'exec-path-from-shell)
  :config
    (exec-path-from-shell-initialize))

;;; **** use-feature
(eval-and-compile
  (defmacro use-feature (name &rest args)
    "Like `use-package' but accounting for asynchronous installation.
    NAME and ARGS are in `use-package'."
    (declare (indent defun))
    `(use-package ,name
      :ensure nil
      ,@args)))

(elpaca-wait)

;;; {{{ **** builtins for ceamx
;;;; Use latest versions of some Emacs builtins to satisfy bleeding-edge packages

;; Installing the latest development versions of `eglot' and `magit' (for
;; example) comes with the significant caveat that their dependencies often
;; track the latest versions of builtin Emacs libraries. Those can be installed
;; via GNU ELPA.
;;
;; Since core libraries like `seq' are often dependencies of many other packages
;; or otherwise loaded immediately (like `eldoc'), installation and activation
;; of the newer versions needs to happen upfront to avoid version conflicts and
;; mismatches. For example, we do not want some package loaded earlier in init
;; to think it is using the builtin version of `seq', while a package loaded
;; later in init uses a differnt version. I am not sure how realistic such a
;; scenario might be, or whether it would truly pose a problem, but the point is
;; that we should aim for consistency.
;;
;; Oftentimes, these builtins must be unloaded before loading the newer version.
;; This applies especially to core libraries like `seq' or the
;; enabled-by-default `global-eldoc-mode' provided by `eldoc', but not
;; `jsonrpc', since its functionality is specific to more niche features like
;; inter-process communication in the case of `eglot'.
;;
;; A feature must only be unloaded once, *before* loading the version installed
;; by Elpaca. Normally, that is not an issue because the init file is only
;; loaded once on session startup. But when you are re-loading the init file
;; inside a running session, you'd actually end up unloading the version that
;; Elpaca loaded. To prevent that, the unloading should happen only once --
;; during session startup -- so we check for a non-nil value of `after-init-time'.
;;
;; I don't understand why the Elpaca-installed feature/package only seems to be
;; loaded during the initial session startup? Unless the unloading happens
;; conditionally based on `after-init-time' as described above, every time the
;; init file is reloaded and `elpaca-process-queues' runs in
;; `+auto-tangle-reload-init-h', I get a bunch of errors (not warnings!) about
;; `eglot' and `org' as missing dependencies.

;;; {{{ **** seq
;;;;; Install the latest version of `seq' builtin library, carefully

;; `magit' requires a more recent version of `seq' than the version included in
;; Emacs 29.

;; Requires special care because unloading it can make other libraries freak out.
;; <https://github.com/progfolio/elpaca/issues/216#issuecomment-1868444883>

(defun +my/elpaca-unload-seq (e)
  "Unload the builtin version of `seq' and continue the `elpaca' build E."
  (and (featurep 'seq) (unload-feature 'seq t))
  (elpaca--continue-build e))

(defun +my/elpaca-seq-build-steps ()
  "Update the `elpaca' build-steps to activate the latest version of the builtin `seq' package."
  (append (butlast
            (if (file-exists-p (expand-file-name "seq" elpaca-builds-directory))
                elpaca--pre-built-steps
                elpaca-build-steps))
          (list '+my/elpaca-unload-seq 'elpaca--activate-package)))

(elpaca `(seq :build ,(+my/elpaca-seq-build-steps)))

;; (elpaca-wait)
(require 'seq)
(add-to-list 'package-selected-packages 'seq)
;;; }}} **** seq

;;; {{{ **** jsonrpc
;;;;; Install the latest version of `jsonrpc' builtin library

;; Required by (and originally extracted from) `eglot'.

(elpaca jsonrpc
  (require 'jsonrpc))

;; (elpaca-wait)
(add-to-list 'package-selected-packages 'jsonrpc)
;;; }}} **** jsonrpc

;;; {{{ **** eldoc
;;;;; Install the latest version of `eldoc' builtin library, carefully
;; Required by `eglot'.

;; `eldoc' requires a delicate workaround to avoid catastrophy.
;; <https://github.com/progfolio/elpaca/issues/236#issuecomment-1879838229>

(unless after-init-time
  (unload-feature 'eldoc t)
  (customize-set-variable 'custom-delayed-init-variables '())
  (defvar global-eldoc-mode nil))

(elpaca eldoc
  (require 'eldoc)
  (global-eldoc-mode))

;; (elpaca-wait)
(add-to-list 'package-selected-packages 'eldoc)
;;; }}} **** eldoc

;;; {{{ **** eglot
;;;;; Install the latest version of the builtin `eglot' package

(unless after-init-time
  (when (featurep 'eglot)
      (unload-feature 'eglot)))

(elpaca eglot)

;; (elpaca-wait)
(add-to-list 'package-selected-packages 'eglot)
;;; }}} **** eglot

;;; {{{ **** org
;;;;; Install the latest version of Org-Mode (`org')

(unless after-init-time
  (when (featurep 'org)
      (unload-feature 'org)))

(elpaca (org :autoloads "org-loaddefs.el"))

;; (elpaca-wait)
(add-to-list 'package-selected-packages 'org)
;;; }}} **** org
;;; }}} **** builtins for ceamx

(elpaca-wait)

;;; }}} *** elpaca

;;; }}} * Initial phase


(load (expand-file-name "etc/custom.el" user-emacs-directory) :noerror)


;;; {{{ ** cus-edit+
(use-package cus-edit+
  :ensure (cus-edit+ :host github :repo "emacsmirror/cus-edit-plus")
  :demand t
  :init (add-to-list 'package-selected-packages 'cus-edit+)
  :config
    (customize-toggle-outside-change-updates 99))
;;; }}} ** cus-edit+

;;; {{{ ** exec-path-from-shell
(use-package exec-path-from-shell
  :init (add-to-list 'package-selected-packages 'exec-path-from-shell)
  :config
    (when (or (daemonp)
        (memq window-system '(mac ns x)))
        (exec-path-from-shell-initialize)
      (exec-path-from-shell-initialize)))
;;; }}} ** exec-path-from-shell

;;; {{{ ** editing

;;; {{{ *** drag-stuff
(use-package drag-stuff
  :init (add-to-list 'package-selected-packages 'drag-stuff)
   :config
     (drag-stuff-define-keys)
     (drag-stuff-global-mode t))
;;; }}} *** rainbow-delimiters

;;; {{{ ** evil-nerd-commenter
(use-package evil-nerd-commenter
  :init (add-to-list 'package-selected-packages 'evil-nerd-commenter)
  :config
    (evilnc-default-hotkeys))
;;; }}} ** evil-nerd-commenter

;;; {{{ *** rainbow-delimiters
(use-package rainbow-delimiters
  :init (add-to-list 'package-selected-packages 'rainbow-delimiters)
   :config
     (add-hook 'prog-mode-hook                  #'rainbow-delimiters-mode))
;;; }}} *** rainbow-delimiters

;;; {{{ *** rainbow-fart
(use-package rainbow-fart
  :init (add-to-list 'package-selected-packages 'rainbow-fart)
  :config
    (add-hook 'after-init-hook                  #'rainbow-fart-mode))

;;; }}} *** rainbow-fart

;;; {{{ *** rainbow-identifiers
(use-package rainbow-identifiers
  :init (add-to-list 'package-selected-packages 'rainbow-identifiers)
  :config
    (add-hook 'prog-mode-hook                   #'rainbow-identifiers-mode))
;;; }}} *** rainbow-identifiers

;;; {{{ *** selected
(use-package selected
  :init (add-to-list 'package-selected-packages 'selected)
  :custom
    (selected-background-color "#333333")
    (selected-frame-background-mode 'dark)
    (selected-frame-foreground-mode 'light)
    (selected-minor-mode-abbreviations '(("selected" . "sel")))
  ;; :bind (
  ;;   :map selected-keymap
  ;;   (","      . 'mc/mark-previous-like-this)
  ;;   ("."      . 'mc/mark-next-like-this)
  ;;   ("["      . 'align-code)
  ;;   ("*"      . 'mc/mark-all-like-this)
  ;;   ("<"      . 'mc/unmark-next-like-this)
  ;;   (">"      . 'mc/skip-to-next-like-this)
  ;;   ("1"      . 'count-words-region)
  ;;   ("a"      . 'mc/mark-all-like-this-dwim)
  ;;   ("C-<"    . 'mc/skip-to-previous-like-this)
  ;;   ("C->"    . 'mc/unmark-previous-like-this)
  ;;   ("C-d"    . 'delete-duplicate-lines)
  ;;   ("C-s"    . 'single-lines-only)
  ;;   ("c"      . 'copy-region-as-kill)
  ;;   ("d"      . 'downcase-region)
  ;;   ("f"      . 'fill-region)
  ;;   ("F"      . 'flush-lines)
  ;;   ("k"      . 'kill-region)
  ;;   ("l"      . 'mc/edit-lines)
  ;;   ("m"      . 'apply-macro-to-region-lines)
  ;;   ("n"      . 'mc/mark-next-like-this)
  ;;   ("p"      . 'mc/mark-previous-like-this)
  ;;   ("q"      . 'selected-off)
  ;;   ("r"      . 'reverse-region)
  ;;   ("s"      . 'ispell-region)
  ;;   ("S"      . 'sort-lines)
  ;;   ("t"      . 'prefix-region)
  ;;   ("U"      . 'unfill-region)
  ;;   ("u"      . 'upcase-region)
  ;;   ("w"      . 'mc/mark-next-word-like-this)
  ;;   ("W"      . 'mc/mark-previous-word-like-this)
  ;;   ("x"      . 'exchange-point-and-mark)
  ;;   ("y"      . 'yank)
  ;;   ("Z"      . 'redo)
  ;;   ("z"      . 'undo))
  :commands
    (selected-minor-mode)
  :config
    (add-hook 'emacs-lisp-mode-hook             #'selected-minor-mode)
    (add-hook 'markdown-mode-hook               #'selected-minor-mode)
    (add-hook 'org-mode-hook                    #'selected-minor-mode)
    (selected-global-mode t))
;;; }}} *** selected

;;; {{{ *** undo-fu
(use-package undo-fu
  :init (add-to-list 'package-selected-packages 'undo-fu)
  :config
    (global-unset-key (kbd "C-z"))
    (global-set-key (kbd "C-S-z")   'undo-fu-only-redo)
    (global-set-key (kbd "C-z")     'undo-fu-only-undo))
;;; }}} *** undo-fu

;;; {{{ *** undo-fu-session
(use-package undo-fu-session
  :init (add-to-list 'package-selected-packages 'undo-fu-session)
  :custom
    (undo-fu-session-ignore-temp-files t)
    (undo-fu-session-incompatible-files '("/COMMIT_EDITMSG\\'" "/git-rebase-todo\\'"))
  :config
    (undo-fu-session-global-mode t))
;;; }}} *** undo-fu-session

;;; {{{ *** visual-fill-column
(use-package visual-fill-column
  :init (add-to-list 'package-selected-packages 'visual-fill-column)
  :custom
    (visual-fill-column-fringes-outside-margins t "If set to t, put the fringes outside the margins.\n Widening the margin would normally cause the fringes to be pushed inward, because by default, they appear between the margins and the text.\n This effect may be visually less appealing, therefore, visual-fill-column-mode places the fringes outside the margins.\n If you prefer to have the fringes inside the margins, unset this option.")
    (visual-fill-column-width nil "Column at which to wrap lines.\n If set to nil (the default), use the value of fill-column instead.")
  :config
    (advice-add 'text-scale-adjust :after #'visual-fill-column-adjust))
;;; }}} *** visual-fill-column

;;; {{{ *** visual-regexp
(use-package visual-regexp
  :init (add-to-list 'package-selected-packages 'visual-regexp)
  ;; :config
  ;;   (global-set-key (kbd "C-c m") 'vr/mc-mark)
  ;;   (global-set-key (kbd "C-c q") 'vr/query-replace)
  ;;   (global-set-key (kbd "C-c r") 'vr/replace)
  ;;   (global-set-key (kbd "C-c S") 'vr/isearch-backward)
  ;;   (global-set-key (kbd "C-c s") 'vr/isearch-forward)
  ;;   (global-set-key (kbd "C-c u") 'vr/mc-mark-all)
)
;;; }}} *** visual-regexp

;;; {{{ *** vundo
(use-package vundo
  :init (add-to-list 'package-selected-packages 'vundo)
  :custom
    (vundo-compact-display t)
  :custom-face
    (vundo-highlight    ((t (:foreground "#FFFF00"))))
    (vundo-node         ((t (:foreground "#808080"))))
    (vundo-stem         ((t (:foreground "#808080"))))
  ;; :bind ( ;; for EWS
  ;;   ("C-c w u" . vundo))
  :commands
    (vundo)
  :config
    (with-eval-after-load 'evil
      (evil-define-key 'normal 'global (kbd "C-M-u") 'vundo)))
;;; }}} *** vundo

;;; }}} ** editing

;;; {{{ ** completion

;;; {{{ *** cape
;; Add extensions
(use-package cape
  :demand t
  :init (add-to-list 'package-selected-packages 'cape)

    ;; Setup Cape for better completion-at-point support and more

    ;; Add to the global default value of `completion-at-point-functions' which is
    ;; used by `completion-at-point'.    The order of the functions matters, the
    ;; first function returning a result wins.    Note that the list of buffer-local
    ;; completion functions takes precedence over the global list.
    (add-to-list 'completion-at-point-functions #'cape-dabbrev)
    (add-to-list 'completion-at-point-functions #'cape-file)
    (add-to-list 'completion-at-point-functions #'cape-elisp-block)
    (add-to-list 'completion-at-point-functions #'cape-history)
    (add-to-list 'completion-at-point-functions #'cape-keyword)
    (add-to-list 'completion-at-point-functions #'cape-tex)
    (add-to-list 'completion-at-point-functions #'cape-sgml)
    (add-to-list 'completion-at-point-functions #'cape-rfc1345)
    (add-to-list 'completion-at-point-functions #'cape-abbrev)
    (add-to-list 'completion-at-point-functions #'cape-dict)
    (add-to-list 'completion-at-point-functions #'cape-elisp-symbol)
    (add-to-list 'completion-at-point-functions #'cape-line)

    ;; The advices are only needed on Emacs 28 and older.
    (when (< emacs-major-version 29)
        ;; Ensure that pcomplete does not write to the buffer and behaves as a
        ;; `completion-at-point-function' without side-effects.
        (advice-add 'pcomplete-completions-at-point :around #'cape-wrap-purify)

        ;; Silence the pcomplete capf. Hide errors or messages.
        ;; Important for corfu!
        (advice-add 'pcomplete-completions-at-point :around #'cape-wrap-silent))

    ;; No auto-completion or completion-on-quit in eshell
    (defun +my/completion-corfu-eshell ()
      "Special settings for when using corfu with eshell."
      (setq-local corfu-auto nil)
      (setq-local corfu-quit-at-boundary t)
      (setq-local corfu-quit-no-match t)
      (corfu-mode t))
    (add-hook 'eshell-mode-hook             #'+my/completion-corfu-eshell)

    ;; Example 5: Define a defensive Dabbrev Capf, which accepts all inputs.    If you
    ;; use Corfu and `corfu-auto=t', the first candidate won't be auto selected if
    ;; `corfu-preselect=valid', such that it cannot be accidentally committed when
    ;; pressing RET.
    (defun +my/cape-dabbrev-accept-all ()
      (cape-wrap-accept-all #'cape-dabbrev))
    (add-to-list 'completion-at-point-functions #'+my/cape-dabbrev-accept-all)
  ;; :bind (
  ;; ;; Bind dedicated completion commands
  ;; ;; Alternative prefix keys: C-c p, M-p, M-+, ...
  ;;   ("C-c p &"  . cape-sgml)
  ;;   ("C-c p :"  . cape-emoji)
  ;;   ("C-c p \\" . cape-tex)
  ;;   ("C-c p ^"  . cape-tex)
  ;;   ("C-c p _"  . cape-tex)
  ;;   ("C-c p a"  . cape-abbrev)
  ;;   ("C-c p d"  . cape-dabbrev)                         ;; or dabbrev-completion
  ;;   ("C-c p e"  . cape-elisp-block)
  ;;   ("C-c p f"  . cape-file)
  ;;   ("C-c p h"  . cape-history)
  ;;   ("C-c p k"  . cape-keyword)
  ;;   ("C-c p l"  . cape-line)
  ;;   ("C-c p p"  . completion-at-point)                  ;; capf
  ;;   ("C-c p r"  . cape-rfc1345)
  ;;   ("C-c p s"  . cape-elisp-symbol)
  ;;   ("C-c p t"  . complete-tag)                         ;; etags
  ;;   ("C-c p w"  . cape-dict))
  :config
    ;; Example 6: Define interactive Capf which can be bound to a key.    Here we wrap
    ;; the `elisp-completion-at-point' such that we can complete Elisp code
    ;; explicitly in arbitrary buffers.
    ;;(keymap-global-set "C-c p e" (cape-capf-interactive #'elisp-completion-at-point))

    ;; ;; Example 7: Ignore :keywords in Elisp completion.
    (defun +my/ignore-elisp-keywords (sym)
      (not (keywordp sym)))
    (setq-local completion-at-point-functions
                (list (cape-capf-predicate #'elisp-completion-at-point #'+my/ignore-elisp-keywords))))
;;; }}} *** cape

;;; {{{ *** consult
(use-package consult
  :demand t
  ;; Since Consult doesn't need to be required, we assume the user wants these
  ;; setting if it is installed (regardless of the installation method).
  ;; Example configuration for Consult

  ;; The :init configuration is always executed (Not lazy)
  :init (add-to-list 'package-selected-packages 'consult)

    ;; Optionally tweak the register preview window.
    ;; This adds thin lines, sorting and hides the mode line of the window.
    (advice-add #'register-preview :override #'consult-register-window)

  :custom
    (completion-in-region-function #'consult-completion-in-region)
    ;; Optionally configure the narrowing key.
    ;; Both < and C-+ work reasonably well.
    (consult-narrow-key "<")    ;; "C-+"
    ;; Optionally configure the register formatting. This improves the register
    ;; preview for `consult-register', `consult-register-load',
    ;; `consult-register-store' and the Emacs built-ins.
    (register-preview-delay 0.5)
    (register-preview-function #'consult-register-format)
    ;; Use Consult to select xref locations with preview
    (xref-show-xrefs-function #'consult-xref)
    (xref-show-definitions-function #'consult-xref)

  ;; ;; Replace bindings. Lazily loaded due by `use-package'.
  ;; :bind (;; C-c bindings in `mode-specific-map'
  ;;   ("C-c M-x"  . consult-mode-command)
  ;;   ("C-c h"    . consult-history)
  ;;   ("C-c i"    . consult-info)
  ;;   ("C-c k"    . consult-kmacro)
  ;;   ("C-c m"    . consult-man)
  ;;   ([remap Info-search] . consult-info)
  ;;   ;; C-x bindings in `ctl-x-map'
  ;;   ("C-x 4 b"  . consult-buffer-other-window)         ;; orig. switch-to-buffer-other-window
  ;;   ("C-x 5 b"  . consult-buffer-other-frame)           ;; orig. switch-to-buffer-other-frame
  ;;   ("C-x M-:"  . consult-complex-command)              ;; orig. repeat-complex-command
  ;;   ("C-x b"    . consult-buffer)                       ;; orig. switch-to-buffer
  ;;   ("C-x p b"  . consult-project-buffer)               ;; orig. project-switch-to-buffer
  ;;   ("C-x r b"  . consult-bookmark)                     ;; orig. bookmark-jump
  ;;   ("C-x t b"  . consult-buffer-other-tab)             ;; orig. switch-to-buffer-other-tab
  ;;   ;; Custom M-# bindings for fast register access
  ;;   ("C-M-#"    . consult-register)
  ;;   ("M-#"      . consult-register-load)
  ;;   ("M-'"      . consult-register-store)               ;; orig. abbrev-prefix-mark (unrelated)
  ;;   ;; Other custom bindings
  ;;   ("M-y"      . consult-yank-pop)                     ;; orig. yank-pop
  ;;   ;; M-g bindings in `goto-map'
  ;;   ("M-g I"    . consult-imenu-multi)
  ;;   ("M-g M-g"  . consult-goto-line)                    ;; orig. goto-line
  ;;   ("M-g e"    . consult-compile-error)
  ;;   ("M-g f"    . consult-flycheck)                     ;; Default: consult-flymake
  ;;   ("M-g g"    . consult-goto-line)                    ;; orig. goto-line
  ;;   ("M-g i"    . consult-imenu)
  ;;   ("M-g k"    . consult-global-mark)
  ;;   ("M-g m"    . consult-mark)
  ;;   ("M-g o"    . consult-outline)                      ;; Alternative: consult-org-heading
  ;;   ;; M-s bindings in `search-map'
  ;;   ("M-s G"    . consult-git-grep)
  ;;   ("M-s L"    . consult-line-multi)
  ;;   ("M-s c"    . consult-locate)
  ;;   ("M-s d"    . consult-find)                         ;; Alternative: consult-fd
  ;;   ("M-s g"    . consult-grep)
  ;;   ("M-s k"    . consult-keep-lines)
  ;;   ("M-s l"    . consult-line)
  ;;   ("M-s r"    . consult-ripgrep)
  ;;   ("M-s u"    . consult-focus-lines)
  ;;   ;; Isearch integration
  ;;   ("M-s e"    . consult-isearch-history)
  ;;   :map isearch-mode-map
  ;;   ("M-e"      . consult-isearch-history)              ;; orig. isearch-edit-string
  ;;   ("M-s L"    . consult-line-multi)                   ;; needed by consult-line to detect isearch
  ;;   ("M-s e"    . consult-isearch-history)              ;; orig. isearch-edit-string
  ;;   ("M-s l"    . consult-line)                         ;; needed by consult-line to detect isearch
  ;;   ;; Minibuffer history
  ;;   :map minibuffer-local-map
  ;;   ("M-r"      . consult-history)                      ;; orig. previous-matching-history-element
  ;;   ("M-s"      . consult-history))                     ;; orig. next-matching-history-element

  ;; Configure other variables and modes in the :config section,
  ;; after lazily loading the package.
  :config
    ;; Optionally configure preview. The default value
    ;; is 'any, such that any key triggers the preview.
    ;; (setq consult-preview-key 'any)
    ;; (setq consult-preview-key "M-.")
    ;; (setq consult-preview-key '("S-<down>" "S-<up>"))
    ;; For some commands and buffer sources it is useful to configure the
    ;; :preview-key on a per-command basis using the `consult-customize' macro.
    (consult-customize
      consult-theme :preview-key '(:debounce 0.2 any)
      consult-ripgrep consult-git-grep consult-grep
      consult-bookmark consult-recent-file consult-xref
      consult--source-bookmark consult--source-file-register
      consult--source-recent-file consult--source-project-recent-file
      ;; :preview-key "M-."
      :preview-key '(:debounce 0.4 any))

    ;; Optionally make narrowing help available in the minibuffer.
    ;; You may want to use `embark-prefix-help-command' or which-key instead.
    (define-key consult-narrow-map (vconcat consult-narrow-key "?") #'consult-narrow-help)

    ;; By default `consult-project-function' uses `project-root' from project.el.
    ;; Optionally configure a different project root function.
    ;;;; 1. project.el (the default)
    ;; (setq consult-project-function #'consult--default-project--function)
    ;;;; 2. vc.el (vc-root-dir)
    ;; (setq consult-project-function (lambda (_) (vc-root-dir)))
    ;;;; 3. locate-dominating-file
    ;; (setq consult-project-function (lambda (_) (locate-dominating-file "." ".git")))
    ;;;; 4. projectile.el (projectile-project-root)
    ;; (autoload 'projectile-project-root "projectile")
    ;; (setq consult-project-function (lambda (_) (projectile-project-root)))
    ;;;; 5. No project support
    ;; (setq consult-project-function nil)

    ;; Enable automatic preview at point in the *Completions* buffer. This is
    ;; relevant when you use the default completion UI.
    (add-hook 'completion-list-mode-hook    #'consult-preview-at-point-mode))

(use-package consult-dir
  :after (consult vertico)
  :init (add-to-list 'package-selected-packages 'consult-dir)
  ;; :bind (
  ;;   ("C-x C-d"      . consult-dir)
  ;;   :map vertico-map
  ;;   ("C-x C-d"      . consult-dir)
  ;;   ("C-x C-j"      . consult-dir-jump-file))
  :config
    (add-to-list 'consult-dir-sources 'consult-dir--source-tramp-ssh t))

(use-package consult-flycheck
  :after (consult)
  :init (add-to-list 'package-selected-packages 'consult-flycheck))

(use-package consult-flyspell
  :after (consult)
  :init (add-to-list 'package-selected-packages 'consult-flyspell)
  :custom
    ;; default settings
    (consult-flyspell-always-check-buffer nil)
    (consult-flyspell-select-function nil)
    (consult-flyspell-set-point-after-word t))

(use-package consult-project-extra
  :after (consult)
  :init (add-to-list 'package-selected-packages 'consult-project-extra)
  ;; :bind (
  ;;   ("C-c p f"  . consult-project-extra-find)
  ;;   ("C-c p o"  . consult-project-extra-find-other-window))
)

;;; {{{ *** consult-web
(use-package consult-web
  :ensure (consult-web :type git :host github :repo "armindarvish/consult-web" :branch "main" :files (:defaults "sources/*.el"))
  :after consult
  :init (add-to-list 'package-selected-packages 'consult-web)
  :custom
    ;; General settings that apply to all sources
    (consult-web-default-count 5) ;;; set default count
    (consult-web-default-page 0) ;;; set the default page (default is 0 for the first page)
    (consult-web-highlight-matches t) ;;; highlight matches in minibuffer
    (consult-web-preview-key "C-o") ;;; set the preview key to C-o
    (consult-web-show-preview t) ;;; show previews

    ;;; optionally change the consult-web debounce, throttle and delay.
    ;;; Adjust these (e.g. increase to avoid hiting a source (e.g. an API) too frequently)
    (consult-web-dynamic-input-debounce 0.8)
    (consult-web-dynamic-input-throttle 1.6)
    (consult-web-dynamic-refresh-delay 0.8)

    ;;; set multiple sources for consult-web-multi command. Change these lists as needed for different interactive commands. Keep in mind that each source has to be a key in `consult-web-sources-alist'.
    (consult-web-dynamic-omni-sources (list "Known Project" "File" "Bookmark" "Buffer" "Reference Roam Nodes" "Zettel Roam Nodes" "Line Multi" "elfeed" "Brave" "Wikipedia" "gptel" "Youtube")) ;;consult-web-dynamic-omni
    (consult-web-dynamic-sources '("gptel" "Brave" "StackOverFlow" )) ;; consult-web-dynamic
    (consult-web-multi-sources '("Brave" "Wikipedia" "chatGPT" "Google")) ;; consult-web-multi
    (consult-web-omni-sources (list "elfeed" "Brave" "Wikipedia" "gptel" "YouTube" 'consult-buffer-sources 'consult-notes-all-sources)) ;;consult-web-omni
    (consult-web-scholar-sources '("PubMed")) ;; consult-web-scholar

    ;; Per source customization
    ;;; Pick you favorite autosuggest command.
    (consult-web-default-autosuggest-command #'consult-web-dynamic-brave-autosuggest) ;;or any other autosuggest source you define

    ;;; Set API KEYs. It is recommended to use a function that returns the string for better security.
    (consult-web-brave-api-key "YOUR-BRAVE-API-KEY-OR-FUNCTION")
    (consult-web-google-customsearch-cx "YOUR-GOOGLE-CX-NUMBER-OR-FUNCTION")
    (consult-web-google-customsearch-key "YOUR-GOOGLE-API-KEY-OR-FUNCTION")
    (consult-web-openai-api-key "YOUR-OPENAI-API-KEY-OR-FUNCTION")
    (consult-web-pubmed-api-key "YOUR-PUBMED-API-KEY-OR-FUNCTION")
    (consult-web-stackexchange-api-key "YOUR-STACKEXCHANGE-API-KEY-OR-FUNCTION")

  :config
    ;; Add sources and configure them
    ;;; load the example sources provided by default
    (require 'consult-web-sources)
    ;;; add more keys as needed here.
)
;;; }}} *** consult-web
;;; }}} *** consult

;;; {{{ *** corfu
(use-package corfu
  ;; :disabled
  :demand t

  ;; Recommended: Enable Corfu globally.    This is recommended since Dabbrev can
  ;; be used globally (M-/).    See also the customization variable
  ;; `global-corfu-modes' to exclude certain modes.
  :init (add-to-list 'package-selected-packages 'corfu)

    (global-corfu-mode t)
  ;; Optional customizations
  :custom
    (corfu-auto t)                                      ;; Enable auto completion
    ;; You will probably want to tweak this variable, it determines how
    ;; quickly the completion prompt provides LSP suggestions when
    ;; typing. Be careful if you set it to 0 in a large project!
    (corfu-auto-delay 0.25)
    (corfu-auto-prefix 2)                               ;; Complete with less prefix keys
    (corfu-cycle t)                                     ;; Enable cycling for `corfu-next/previous'
    (corfu-on-exact-match nil)                          ;; Configure handling of exact matches
    (corfu-preselect 'prompt)                           ;; Preselect the prompt
    (corfu-preview-current nil)                         ;; Disable current candidate preview
    (corfu-quit-at-boundary nil)                        ;; Never quit at completion boundary
    (corfu-quit-no-match nil)                           ;; Never quit, even if there is no match
    (corfu-scroll-margin 5)                             ;; Use scroll margin
    (corfu-separator ?\s)                               ;; Orderless field separator
  :config
    (unless (display-graphic-p)
        (when (require 'corfu-terminal nil :noerror)
            (corfu-terminal-mode t)))
    (when (require 'corfu-popupinfo nil :noerror)
        (corfu-popupinfo-mode t)
        (eldoc-add-command #'corfu-insert)
        (keymap-set corfu-map "M-d" #'corfu-popupinfo-toggle)
        (keymap-set corfu-map "M-n" #'corfu-popupinfo-scroll-up)
        (keymap-set corfu-map "M-p" #'corfu-popupinfo-scroll-down))

    (defun +my/corfu-enable-in-minibuffer ()
        "Enable Corfu in the minibuffer."
        (when (local-variable-p 'completion-at-point-functions)
            (setq-local corfu-auto nil)             ;; Enable/disable auto completion
            (setq-local corfu-echo-delay nil)       ;; Disable automatic echo and popup
            (setq-local corfu-popupinfo-delay nil)
            (corfu-mode t)))
    (add-hook 'minibuffer-setup-hook            #'+my/corfu-enable-in-minibuffer)

    ;; Enable Corfu only for certain modes.
    ;; (add-hook 'eshell-mode-hook         'corfu-mode)
    ;; (add-hook 'prog-mode-hook           'corfu-mode)
    ;; (add-hook 'shell-mode-hook          'corfu-mode)

    (corfu-mode t))

;; A few more useful configurations...
(use-feature emacs
  :custom
    ;; TAB cycle if there are only few candidates
    (completion-cycle-threshold 3)
    ;; Emacs 28 and newer: Hide commands in M-x which do not apply to the current
    ;; mode.    Corfu commands are hidden, since they are not used via M-x. This
    ;; setting is useful beyond Corfu.
    (read-extended-command-predicate #'command-completion-default-include-p)
    ;; Enable indentation+completion using the TAB key.
    ;; `completion-at-point' is often bound to M-TAB.
    (tab-always-indent 'complete)
    ;; Emacs 30 and newer: Disable Ispell completion function. As an alternative,
    ;; try `cape-dict'.
    (text-mode-ispell-word-completion nil)
  ;; :bind (
  ;;   ("C-M-/"    . dabbrev-expand)
  ;;   ("M-/"      . dabbrev-completion))
  :config
    (when (require 'dabbrev nil :noerror)
        (add-to-list 'dabbrev-ignored-buffer-regexps "\\` ")    ;; < Emacs 29.1
        ;; Since 29.1, use `dabbrev-ignored-buffer-regexps' on older.
        (add-to-list 'dabbrev-ignored-buffer-modes 'doc-view-mode)
        (add-to-list 'dabbrev-ignored-buffer-modes 'pdf-view-mode)))
;;; }}} *** corfu

;;; {{{ *** embark
(use-package embark
  :init (add-to-list 'package-selected-packages 'embark)
  :custom
    (eldoc-documentation-strategy   #'eldoc-documentation-compose-eagerly)
    ;; Optionally replace the key help with a completing-read interface
    (prefix-help-command #'embark-prefix-help-command)
  ;; :bind (
  ;;   ("C-;"                      . embark-dwim)        ;; good alternative: M-.
  ;;   ("C-."                      . embark-act)         ;; pick some comfortable binding
  ;;   ("C-h B"                    . embark-bindings)    ;; alternative for `describe-bindings'
  ;;   ([remap describe-bindings]  . embark-bindings))
  :config
    ;; Hide the mode line of the Embark live/completions buffers
    (add-to-list 'display-buffer-alist
                    '("\\`\\*Embark Collect \\(Live\\|Completions\\)\\*"
                      nil
                      (window-parameters (mode-line-format . none))))
    ;; Show the Embark target at point via Eldoc. You may adjust the
    ;; Eldoc strategy, if you want to see the documentation from
    ;; multiple providers. Beware that using this can be a little
    ;; jarring since the message shown in the minibuffer can be more
    ;; than one line, causing the modeline to move up and down:
    (add-hook 'eldoc-documentation-functions    #'embark-eldoc-first-target))

;; Consult users will also want the embark-consult package.
(use-package embark-consult
  ;; only need to install it, embark loads it after consult if found
  :init (add-to-list 'package-selected-packages 'embark-consult)
  :config
    (add-hook 'embark-collect-mode-hook         #'consult-preview-at-point-mode))
;;; }}} *** embark

;;; {{{ *** marginalia
;; Enable rich annotations using the Marginalia package
(use-package marginalia
  :demand t
  ;; The :init section is always executed.
  :init (add-to-list 'package-selected-packages 'marginalia)
    ;; Marginalia must be activated in the :init section of use-package such that
    ;; the mode gets enabled right away. Note that this forces loading the
    ;; package.
    (marginalia-mode t)
  :custom
    (marginalia-annotators '(marginalia-annotators-heavy marginalia-annotators-light nil))
  ;; :bind (
  ;;   ;; Bind `marginalia-cycle' locally in the minibuffer.    To make the binding
  ;;   ;; available in the *Completions* buffer, add it to the
  ;;   ;; `completion-list-mode-map'.
  ;;   :map completion-list-mode-map
  ;;     ("M-A"  . marginalia-cycle)
  ;;   :map minibuffer-local-map
  ;;     ("M-A"  . marginalia-cycle))
)
;;; }}} *** marginalia

;;; {{{ *** orderless
;; Optionally use the `orderless' completion style.
(use-package orderless
  :demand t
  :init (add-to-list 'package-selected-packages 'orderless)

    (defun +my/orderless--consult-suffix ()
      "Regexp which matches the end of string with Consult tofu support."
      (if (and (boundp 'consult--tofu-char) (boundp 'consult--tofu-range))
          (format "[%c-%c]*$"
                  consult--tofu-char
                  (+ consult--tofu-char consult--tofu-range -1))
          "$"))

    (defun +my/orderless-consult-dispatch (word _index _total)
      "Recognizes the following patterns:\n  * .ext (file extension)\n  * regexp$ (regexp matching at end)"
      (cond
        ;; Ensure that $ works with Consult commands, which add disambiguation suffixes
        ((string-suffix-p "$" word)
          `(orderless-regexp  . ,(concat (substring word 0 -1) (+my/orderless--consult-suffix))))
        ;; File extensions
        ((and (string-match-p "\\`\\.." word)
                (or minibuffer-completing-file-name
                    (derived-mode-p 'eshell-mode)))
          `(orderless-regexp  . ,(concat "\\." (substring word 1) (+my/orderless--consult-suffix))))))

  :config
    ;; Define orderless style with initialism by default
    (orderless-define-completion-style
        +orderless-with-initialism
        (orderless-matching-styles '(orderless-initialism orderless-literal orderless-regexp)))

    ;; You may want to combine the `orderless` style with `substring` and/or `basic`.
    ;; There are many details to consider, but the following configurations all work well.
    ;; Personally I (@minad) use option 3 currently. Also note that you may want to configure
    ;; special styles for special completion categories, e.g., partial-completion for files.
    ;;
    ;; 1. (customize-set-variable 'completion-styles '(orderless))
    ;; This configuration results in a very coherent completion experience,
    ;; since orderless is used always and exclusively. But it may not work
    ;; in all scenarios. Prefix expansion with TAB is not possible.
    ;;
    ;; 2. (customize-set-variable 'completion-styles '(substring orderless))
    ;; By trying substring before orderless, TAB expansion is possible.
    ;; The downside is that you can observe the switch from substring to orderless
    ;; during completion, less coherent.
    ;;
    ;; 3. (customize-set-variable 'completion-styles '(orderless basic))
    ;; Certain dynamic completion tables (completion-table-dynamic)
    ;; do not work properly with orderless. One can add basic as a fallback.
    ;; Basic will only be used when orderless fails, which happens only for
    ;; these special tables.
    ;;
    ;; 4. (customize-set-variable 'completion-styles '(substring orderless basic))
    ;; Combine substring, orderless and basic.

    (customize-set-variable 'completion-styles '(substring orderless initials flex basic))
    (customize-set-variable 'completion-category-defaults nil)
    ;;; Enable partial-completion for files.
    ;;; Either give orderless precedence or partial-completion.
    ;;; Note that completion-category-overrides is not really an override,
    ;;; but rather prepended to the default completion-styles.
    ;; completion-category-overrides '((file (styles orderless partial-completion))) ;; orderless is tried first
    (customize-set-variable 'completion-category-overrides '(
        ;; partial-completion is tried first
        (file (styles partial-completion))
        ;; enable initialism by default for symbols
        (command (styles +orderless-with-initialism))
        (symbol (styles +orderless-with-initialism))
        (variable (styles +orderless-with-initialism))))
    ;; allow escaping space with backslash!
    (customize-set-variable 'orderless-component-separator #'orderless-escapable-split-on-space)
    (customize-set-variable 'orderless-style-dispatchers (list #'+my/orderless-consult-dispatch #'orderless-affix-dispatch)))
;;; }}} *** orderless

;;; {{{ *** vertico
;; Enable vertico
(use-package vertico
  :demand t
  :init (add-to-list 'package-selected-packages 'vertico)

    ;; Turn off the built-in fido-vertical-mode and icomplete-vertical-mode,
    ;; because they interfere with this module.
    (fido-mode -1)
    (fido-vertical-mode -1)
    (icomplete-mode -1)
    (icomplete-vertical-mode -1)
    ;; Start vertico
    (vertico-mode t)
  :custom
    (vertico-count 20)              ;; Show more candidates
    (vertico-cycle t)               ;; Optionally enable cycling for `vertico-next' and `vertico-previous'.
    (vertico-resize t)              ;; Grow and shrink the Vertico minibuffer
    (vertico-scroll-margin 0)       ;; Different scroll margin
    (vertico-sort-function 'vertico-sort-history-alpha)
  ;; :bind (
  ;;   ("C-j"          . vertico-exit)
  ;;   ("C-M-d"        . vertico-scroll-down)
  ;;   ("C-M-h"        . vertico-previous)
  ;;   ("C-M-j"        . vertico-exit)
  ;;   ("C-M-l"        . vertico-next)
  ;;   ("C-M-RET"      . vertico-insert)
  ;;   ("C-M-u"        . vertico-scroll-up)
  ;;   ("C-RET"        . vertico-insert))
  :config
    (require 'vertico-directory)
    (vertico-mode t))

;; A few more useful configurations...
(use-feature emacs
  :init
    ;; Add prompt indicator to `completing-read-multiple'.
    ;; We display [CRM<separator>], e.g., [CRM,] if the separator is a comma.
    (defun +my/crm-indicator (args)
      (cons
        (format "[CRM%s] %s"
          (replace-regexp-in-string
            "\\`\\[.*?]\\*\\|\\[.*?]\\*\\'" ""
            crm-separator)
          (car args))
        (cdr args)))
    (advice-add #'completing-read-multiple :filter-args
      #'+my/crm-indicator)
    ;; Persist history over Emacs restarts. Vertico sorts by history position.
    (savehist-mode t)
  :custom
    ;; Enable recursive minibuffers
    (enable-recursive-minibuffers t)
    ;; Do not allow the cursor in the minibuffer prompt
    (minibuffer-prompt-properties '(read-only t cursor-intangible t face minibuffer-prompt))
    ;; Emacs 28: Hide commands in M-x which do not work in the current mode.
    ;; Vertico commands are hidden in normal buffers.
    (read-extended-command-predicate #'command-completion-default-include-p)
  :config
    (add-hook 'minibuffer-setup-hook            #'cursor-intangible-mode))
;;; }}} *** vertico

;;; }}} ** completion

;;; {{{ ** anzu
(use-package anzu
  :init (add-to-list 'package-selected-packages 'anzu)
  :config (global-anzu-mode t))
;;; }}} ** anzu

;;; {{{ ** autotetris-mode
(use-package autotetris-mode
  :init (add-to-list 'package-selected-packages 'autotetris-mode))
;;; }}} ** autotetris-mode

;;; {{{ ** backup-each-save
(use-package backup-each-save
  :init (add-to-list 'package-selected-packages 'backup-each-save)
  :config
    (add-hook 'after-save-hook      #'backup-each-save))
;;; }}} ** backup-each-save

;;; {{{ ** circe
(use-package circe
  :init (add-to-list 'package-selected-packages 'circe)
  :custom
    ;; Connecting to IRC
    ;; To connect to IRC, simply use M-x circe RET Libera Chat RET RET. This will connect you to Libera. You can join us on #emacs-circe by using /join #emacs-circe in the server buffer.

    ;; A more elaborate setup would require you to edit your init file and add something like the following:
    (circe-network-options
      '(("Libera Chat"
        :tls t
        :nick "my-nick"
        :sasl-username "hugmys0ul"
        :sasl-password "s0ul-circe"
        :channels ("#emacs-circe")))))
;;; }}} ** circe

;;; {{{ ** dumb-jump
(use-package dumb-jump
  :after (hydra)
  :init (add-to-list 'package-selected-packages 'dumb-jump)
  ;; :bind (
  ;;   ;; not a great key as a mnemonic, but easy to press quickly
  ;;   :map dumb-jump-mode-map
  ;;   ("C-M-y"        . #'dumb-jump-hydra/body))
  :config
    ;; add hydra to facilitate remembering the keys and actions for dumb-jump
    (defhydra dumb-jump-hydra (:color blue :columns 3)
      "Dumb Jump"
      ("b" dumb-jump-back "Back")
      ("e" dumb-jump-go-prefer-external "Go external")
      ("i" dumb-jump-go-prompt "Prompt")
      ("j" dumb-jump-go "Go")
      ("l" dumb-jump-quick-look "Quick look")
      ("o" dumb-jump-go-other-window "Other window")
      ("x" dumb-jump-go-prefer-external-other-window "Go external other window"))

    (add-hook 'xref-backend-functions           #'dumb-jump-xref-activate))
;;; }}} ** dumb-jump

;;; {{{ ** edebug-inline-result
;; [[https://melpa.org/#/edebug-inline-result][edebug-inline-result]] - Show Edebug result inline
;;
;; [[https://repo.or.cz/edebug-inline-result.git]]
(use-package edebug-inline-result
  :init (add-to-list 'package-selected-packages 'edebug-inline-result)
  :custom
    (edebug-inline-result-backend 'posframe)
  :config
    (add-hook 'edebug-mode-hook             #'edebug-inline-result-mode))
;;; }}} ** edebug-inline-result

;;; {{{ ** elfeed packages
;;; {{{ *** elfeed
(use-package elfeed
  :init (add-to-list 'package-selected-packages 'elfeed)
    (defvar +my/elfeed-feed-file (no-littering-expand-etc-file-name "elfeed/rss-feeds.org") "no-littering `+my/elfeed-feed-file'")
  :custom
    (elfeed-curl-max-connections 10)
    (elfeed-db-directory (no-littering-expand-var-file-name "elfeed") "no-littering `elfeed-db-directory'")
    (elfeed-enclosure-default-dir (no-littering-expand-var-file-name "elfeed/enclosure") "no-littering `elfeed-enclosure-default-dir'")
    (elfeed-feeds
      (with-current-buffer (find-file-noselect +my/elfeed-feed-file)
        (save-excursion
          (save-restriction
            (org-fold-show-all)
            (goto-char (point-min))
            (let ((found nil))
              (org-element-map (org-element-parse-buffer) 'link
                (lambda (node)
                  (when-let ( (props (cadr node))
                              (standards (plist-get props :standard-properties))
                              (tags (org-get-tags (aref standards 0)))
                              ((member "elfeed" tags))
                              ((not (member "ignore" tags))))
                      (push
                        (cons (plist-get props :raw-link)
                              (delq 'elfeed (mapcar #'intern tags)))
                        found)))
                nil nil t)
              (nreverse found))))))
    (elfeed-search-clipboard-type 'CLIPBOARD)
    (elfeed-search-date-format '("%F %R" 16 :left))
    (elfeed-search-filter "@2-weeks-ago +unread")
    (elfeed-search-title-max-width 100)
    (elfeed-search-title-min-width 30)
    (elfeed-search-trailing-width 25)
    (elfeed-show-entry-switch 'display-buffer)
    (elfeed-show-truncate-long-urls t)
    (elfeed-show-unique-buffers t)
    (elfeed-sort-order 'descending)
    (elfeed-use-curl nil)
  ;; :bind
  ;;   ("C-c w e"  . elfeed)
  :commands (elfeed)
  :hook (
    ;; Make sure to also check the section on shr and eww for how I handle
    ;; `shr-width' there.
    (elfeed-show-mode-hook  . (lambda () (setq-local shr-width (current-fill-column)))))
  :config
    (elfeed-web-start)
    (defun +my/elfeed-play-in-mpv ()
      "Play selected videos in a shared mpv instance in chronological order."
      (interactive)
      (mapc (lambda (entry)
              (emp-open-url (elfeed-entry-link entry))
              (message "Playing %S in MPV" (elfeed-entry-title entry)))
            (nreverse (elfeed-search-selected)))
      (elfeed-search-untag-all-unread))

    (defun +my/elfeed-download ()
      "Download selected videos."
      (interactive)
      (let ((default-directory (expand-file-name "~/nc/Videos/youtube")))
        (dolist (entry (nreverse (elfeed-search-selected)))
          (let ((title (elfeed-entry-title entry)))
            (message "Attempting to download %S" (elfeed-entry-title entry))
            (make-process
              :name "elfeed-download"
              :buffer "elfeed-download"
              :command (list "youtube-dl" (elfeed-entry-link entry))
              :sentinel (lambda (process _event)
                          (when (= 0 (process-exit-status process))
                              (message "Successfully downloaded %S" title))))))
        (elfeed-search-untag-all-unread)))

    ;; So, however you’ve got URLs for YouTube channels, put them into elfeed.
    ;; To fetch the feeds, open elfeed with M-x elfeed and run M-x elfeed-search-fetch in the search buffer.
    ;; And as usual, take a look at the package documentation for more information.
    ;;
    ;; To help with navigating through the long list of entries, I’ve made the following function to narrow the search buffer to the feed of the entry under cursor:
    (defun +my/elfeed-search-filter-source (entry)
      "Filter elfeed search buffer by the feed under cursor."
      (interactive (list (elfeed-search-selected :ignore-region)))
      (when (elfeed-entry-p entry)
          (elfeed-search-set-filter
            (concat
              "@6-months-ago "
              "+unread "
              "="
              (replace-regexp-in-string
                (rx "?" (* not-newline) eos)
                ""
                (elfeed-feed-url (elfeed-entry-feed entry)))))))

    ;;; ======
    ;; So I mostly alternate between M-x +my/elfeed-search-filter-source and M-x elfeed-search-clear-filter. I tag the entries which I want to watch later with +later, and add the ones I want to watch right now to the playlist.
    ;; Integrating with EMMS
    ;; Finally, here’s the solution I came up with to add an entry from elfeed to the EMMS playlist. First, we’ve got to get a URL:
    (defun +my/get-youtube-url (link)
      (let ((watch-id
              (cadr
                (assoc "watch?v"
                      (url-parse-query-string
                        (substring
                          (url-filename
                            (url-generic-parse-url link))
                          1))))))
        (concat "https://www.youtube.com/watch?v=" watch-id)))
    ;; This function is intended to work with both Invidious and YouTube RSS feeds. Of course, it will require some adaptation if you want to watch channels from something like PeerTube or Odysee.
    ;; The easiest way to put the URL to the playlist is to define a new source for EMMS:
    (with-eval-after-load 'emms
      (define-emms-source elfeed (entry)
        (let ((track (emms-track
                        'url (+my/get-youtube-url (elfeed-entry-link entry)))))
          (emms-track-set track 'info-title (elfeed-entry-title entry))
          (emms-playlist-insert-track track))))
    ;; Because define-emms-source is an EMMS macro, the code block above has to be evaluated with EMMS loaded. E.g. you can wrap it into (with-eval-after-load 'emms ...) or put in the :config section.
    ;;
    ;; The macro defines a bunch of functions to work with the source, which we can use in another function:
    (defun +my/elfeed-add-emms-youtube ()
      (interactive)
      (emms-add-elfeed elfeed-show-entry)
      (elfeed-tag elfeed-show-entry 'watched)
      (elfeed-show-refresh))
    ;; Now, calling M-x +my/elfeed-add-emms-youtube in the *elfeed-show* buffer will add the correct URL to the playlist and tag the entry with +watched. I’ve bound the function to gm.
    ;;; ======

    ;;(advice-add #'elfeed-insert-html :around
    ;;  (lambda (fun &rest r)
    ;;    (let ((shr-use-fonts nil))
    ;;      (apply fun r)))))
)
;;; }}} *** elfeed

;;; {{{ *** elfeed-dashboard
(use-package elfeed-dashboard
  :init (add-to-list 'package-selected-packages 'elfeed-dashboard)
  :custom
    (elfeed-dashboard-file (no-littering-expand-etc-file-name "elfeed/elfeed-dashboard.org") "no-littering `elfeed-dashboard-file'")
  :config
    ;; update feed counts on elfeed-quit
    (advice-add 'elfeed-search-quit-window :after #'elfeed-dashboard-update-links))
;;; }}} *** elfeed-dashboard

;;; {{{ *** elfeed-goodies
(use-package elfeed-goodies
  :after (elfeed)
  :init (add-to-list 'package-selected-packages 'elfeed-goodies)
  :config
    (elfeed-goodies/setup))
;;; }}} *** elfeed-goodies

;;; {{{ *** elfeed-org
(use-package elfeed-org
  :after (elfeed)
  :init (add-to-list 'package-selected-packages 'elfeed-org)
  :custom
    (rmh-elfeed-org-files (list (no-littering-expand-etc-file-name "elfeed/elfeed.org")) "no-littering `rmh-elfeed-org-files'")
  :config
    (elfeed-org))
;;; }}} *** elfeed-org

;;; {{{ *** elfeed-score
(use-package elfeed-score
  :init (add-to-list 'package-selected-packages 'elfeed-score)
  ;; :bind (
  ;;   :map elfeed-search-mode-map
  ;;   ("="       . elfeed-score-map))
  :config
    (elfeed-score-enable))
;;; }}} *** elfeed-score

;;; {{{ *** elfeed-summary
(use-package elfeed-summary
  :init (add-to-list 'package-selected-packages 'elfeed-summary))
;;; }}} *** elfeed-summary

;;; {{{ *** elfeed-tube
(use-package elfeed-tube
  :after (elfeed)
  :init (add-to-list 'package-selected-packages 'elfeed-tube)
  :custom
    (elfeed-tube-auto-fetch-p t)
    (elfeed-tube-auto-save-p nil)
  ;; :bind (
  ;;   :map elfeed-search-mode-map
  ;;   ("F"                    . elfeed-tube-fetch)
  ;;   ([remap save-buffer]    . elfeed-tube-save)
  ;;   :map elfeed-show-mode-map
  ;;   ("F"                    . elfeed-tube-fetch)
  ;;   ([remap save-buffer]    . elfeed-tube-save))
  :config
    (elfeed-tube-setup))
;;; }}} *** elfeed-tube

;;; {{{ *** elfeed-tube-mpv
(use-package elfeed-tube-mpv
  :init (add-to-list 'package-selected-packages 'elfeed-tube-mpv)
  ;; :bind (
  ;;   :map elfeed-show-mode-map
  ;;   ("C-c C-f"              . elfeed-tube-mpv-follow-mode)
  ;;   ("C-c C-w"              . elfeed-tube-mpv-where))
)
;;; }}} *** elfeed-tube-mpv

;;; {{{ *** elfeed-webkit
(use-package elfeed-webkit
  :init (add-to-list 'package-selected-packages 'elfeed-webkit)
  :custom
    (elfeed-webkit-auto-enable-tags '(webkit comics))
  ;; :bind (
  ;;   :map elfeed-show-mode-map
  ;;   ("%"    . elfeed-webkit-toggle))
  :config
    (elfeed-webkit-auto-toggle-by-tag))
;;; }}} *** elfeed-webkit
;;; }}} ** elfeed packages

;;; {{{ ** emms
(use-package emms
  :init (add-to-list 'package-selected-packages 'emms)
  :custom
    (emms-browser-covers #'emms-browser-cache-thumbnail-async)
    ;; emms-info
    (emms-info-functions '(emms-info-libtag))
    ;; emms-librefm
    (emms-librefm-scrobbler-username "hugmys0ul")
    (emms-librefm-scrobbler-password "etyoxmo1")
    ;; emms-setup
    (emms-mode-line-format "「%s」")  ;; fancy
    (emms-player-list '(emms-player-mpv))
    (emms-source-file-default-directory "~/Music")
  :config
    (require 'emms-setup)
    (require 'emms-mpris)
    (emms-all)
    (emms-default-players)
    (emms-mpris-enable)
    (emms-history-load)
    (require 'emms-info)
    (require 'emms-info-libtag)
    (require 'emms-librefm-scrobbler)
    (customize-set-variable 'emms-librefm-scrobbler-username "hugmys0ul")
    (customize-set-variable 'emms-librefm-scrobbler-password "etyoxmo1")
    (emms-librefm-scrobbler-enable)

    ;; Hydra
    (defun +my/tick-symbol (x)
        "Return a tick if X is true-ish."
        (if x "x" " "))

    (defun +my/emms-player-status ()
      "Return the state of the EMMS player: `not-active', `playing', `paused' or `dunno'.\n\n Modeled after `emms-player-pause'."
      (cond
        ((not emms-player-playing-p)
          ;; here we should return 'not-active.    The fact is that
          ;; when i change song, there is a short amount of time
          ;; where we are ``not active'', and the hydra is rendered
          ;; always during that short amount of time.    So we cheat a
          ;; little.
          'playing)
        (emms-player-paused-p
          (let ((resume (emms-player-get emms-player-playing-p 'resume))
                (pause (emms-player-get emms-player-playing-p 'pause)))
            (cond
              (pause  'playing)
              (resume 'paused)
              (t      'dunno))))
        (t
          (let ((pause (emms-player-get emms-player-playing-p 'pause)))
            (if pause 'playing 'dunno)))))

    (defun +my/emms-toggle-time-display ()
      "Toggle the display of time information in the modeline"
      (interactive "")
      (if emms-playing-time-display-p
          (emms-playing-time-disable-display)
        (emms-playing-time-enable-display)))

    (defhydra hydra-emms
      (:hint nil)
      "
%(+my/emms-player-status) %(emms-track-description (emms-playlist-current-selected-track))

^Volume^     ^Controls^       ^Playback^              ^Misc^
^^^^^^^^----------------------------------------------------------------
_+_: inc     _n_: next        _r_: repeat one [% s(+my/tick-symbol emms-repeat-track)]     _t_oggle modeline
_-_: dec     _p_: prev        _R_: repeat all [% s(+my/tick-symbol emms-repeat-playlist)]     _T_oggle only time
^ ^          _<_: seek bw     _#_: shuffle            _s_elect
^ ^          _>_: seek fw     _%_: sort               _g_oto EMMS buffer
^ ^        _SPC_: play/pause
^ ^        _DEL_: restart
"
      ("#"                  emms-shuffle)
      ("%"                  emms-sort)
      ("+"                  emms-volume-raise)
      ("-"                  emms-volume-lower)
      ("<"                  emms-seek-backward)
      ("<XF86AudioPrev>"    emms-previous)
      ("<XF86AudioNext>"    emms-next)
      ("<XF86AudioPlay>"    emms-pause)
      ("<backspace>"        (emms-player-seek-to 0))
      (">"                  emms-seek-forward)
      ("DEL"                (emms-player-seek-to 0))
      ("R"                  emms-toggle-repeat-playlist)
      ("SPC"                emms-pause)
      ("T"                  +my/emms-toggle-time-display)
      ("b"                  emms-browser)
      ("e"                  emms)
      ("g"                  (progn (emms) (with-current-emms-playlist (emms-playlist-mode-center-current))))
      ("l"                  emms-play-playlist)
      ("n"                  emms-next)
      ("p"                  emms-previous)
      ("q"                  nil :exit t)
      ("r"                  emms-toggle-repeat-track)
      ;; ("s"                  +my/selectrum-emms)
      ("t"                  (progn (+my/emms-toggle-time-display) (emms-mode-line-toggle)))))

(use-package emms-info-mediainfo
  :init (add-to-list 'package-selected-packages 'emms-info-mediainfo)
  :config
    (add-to-list 'emms-info-functions #'emms-info-mediainfo))

(use-package emms-mode-line-cycle
  :init (add-to-list 'package-selected-packages 'emms-mode-line-cycle)
  :custom
    (emms-mode-line-active-p t)
    (emms-mode-line-cycle t)
    (emms-mode-line-cycle-additional-space-num 4)
    (emms-mode-line-cycle-any-width-p t)
    (emms-mode-line-cycle-current-title-function
      (lambda ()
        (let ((track (emms-playlist-current-selected-track)))
          (cl-case (emms-track-type track)
            ((streamlist)
              (let ((stream-name
                      (emms-stream-name (emms-track-get track 'metadata))))
                (if stream-name stream-name (emms-track-description track))))
            ((url)
              (emms-track-description track))
            (t
              (file-name-nondirectory
                (emms-track-description track)))))))
    (emms-mode-line-cycle-max-width 15)
    (emms-mode-line-cycle-use-icon-p t)
    (emms-mode-line-cycle-velocity 2)
    (emms-mode-line-format " [%s]")
    (emms-mode-line-titlebar-function
      (lambda ()
        '(:eval
          (when emms-player-playing-p
              (format " %s %s"
                (format emms-mode-line-format (emms-mode-line-cycle-get-title))
                emms-playing-time-string)))))
    (emms-playing-time-p t)
  :config
    ;; `emms-mode-line-cycle' can be used with emms-mode-line-icon.
    (require 'emms-mode-line-icon))

(use-package emms-player-spotify
  :init (add-to-list 'package-selected-packages 'emms-player-spotify)
  :custom
    (emms-player-spotify-adblock t)
    (emms-player-spotify-launch-cmd "flatpak run com.spotify.Client")
  :config
    (add-to-list 'emms-player-list emms-player-spotify))

(use-package emms-soundcloud
    ;; Usage
    ;; After you've configured EMMS, load this file and give a Soundcloud set URL to the relevant EMMS source commands.
    ;; Example usage:
    ;; M-x emms-play-soundcloud-set RET http://soundcloud.com/devolverdigital/sets/hotline-miami-official RET
  :init (add-to-list 'package-selected-packages 'emms-soundcloud))

(use-package org-emms
  :after (org emms)
  :init (add-to-list 'package-selected-packages 'org-emms))
;;; }}} ** emms

;;; {{{ ** epub
(use-package esxml
  :init (add-to-list 'package-selected-packages 'esxml))

(use-package nov
  :after (esxml)
  :init (add-to-list 'package-selected-packages 'nov)
  :custom
    (nov-shr-rendering-functions '((img . nov-render-img) (title . nov-render-title)))
    (nov-shr-rendering-functions (append nov-shr-rendering-functions shr-external-rendering-functions))
    (nov-text-width t)
    (visual-fill-column-center-text t)
  :config
    (require 'shrface)
    (add-hook 'nov-mode-hook                    'shrface-mode)
    (add-hook 'nov-mode-hook                    'visual-fill-column-mode)
    (add-hook 'nov-mode-hook                    'visual-line-mode)
    (add-to-list 'auto-mode-alist '("\\.epub\\'" . nov-mode)))
;;; }}} ** epub

;;; {{{ ** ide

;;; {{{ *** combobulate
(use-package combobulate
  :ensure (combobulate :host github :repo "mickeynp/combobulate")
  ;; :load-path
  ;;   ;; Amend this to the directory where you keep Combobulate's source code.
  ;;   ("path-to-git-checkout-of-combobulate")
  :custom
    ;; You can customize Combobulate's key prefix here.
    ;; Note that you may have to restart Emacs for this to take effect!
    (combobulate-key-prefix "C-c o")
  :hook (
    (css-ts-mode-hook         . combobulate-mode)
    (html-ts-mode-hook        . combobulate-mode)
    (js-ts-mode-hook          . combobulate-mode)
    (json-ts-mode-hook        . combobulate-mode)
    (python-ts-mode-hook      . combobulate-mode)
    (tsx-ts-mode-hook         . combobulate-mode)
    (typescript-ts-mode-hook  . combobulate-mode)
    (yaml-ts-mode-hook        . combobulate-mode)))
;;; }}} *** combobulate

;;; {{{ *** editorconfig
;; turn on editorconfig if it is available
(use-package editorconfig
  :init (add-to-list 'package-selected-packages 'editorconfig)
    (add-hook 'prog-mode-hook                   #'editorconfig-mode))
;;; }}} *** editorconfig

;;; {{{ *** eglot
(use-package eglot
  :init (add-to-list 'package-selected-packages 'eglot)
  :custom
    ;; Shutdown server when last managed buffer is killed
    (eglot-autoshutdown t)
  :config
    (defun +my/ide--add-eglot-hooks (mode-list)
      "Add `eglot-ensure' to modes in MODE-LIST.\n\nThe mode must be loaded, i.e. found with `fboundp'.\nA mode which is not loaded will not have a hook added,\nin which case add it manually with something like this:\n\n`(add-hook 'some-mode-hook #'eglot-ensure)'"
      (dolist (mode-def mode-list)
        (let ((mode (if (listp mode-def) (car mode-def) mode-def)))
          (cond
            ((listp mode) (+my/ide--add-eglot-hooks mode))
            (t
              (when (and (fboundp mode)
                      (not (eq 'clojure-mode mode))  ; prefer cider
                      (not (eq 'lisp-mode mode))     ; prefer sly/slime
                      (not (eq 'scheme-mode mode)))  ; prefer geiser
                  (let ((hook-name (format "%s-hook" (symbol-name mode))))
                    (message "adding eglot to %s" hook-name)
                    (add-hook (intern hook-name) #'eglot-ensure))))))))

    (defun +my/ide--lsp-bin-exists-p (mode-def)
      "Return non-nil if LSP binary of MODE-DEF is found via `executable-find'."
      (let ((lsp-program (cdr mode-def)))
        ;; `lsp-program' is either a list of strings or a function object
        ;; calling `eglot-alternatives'.
        (if (functionp lsp-program)
            (condition-case nil
                (car (funcall lsp-program))
              ;; When an error occurs it's because Eglot checked for a
              ;; binary and didn't find one among alternativeseglot.
              (error nil))
          (executable-find (car lsp-program)))))

    (defun +my/ide-eglot-auto-ensure-all ()
      "Add `eglot-ensure' to major modes that offer LSP support. \n\nMajor modes are only selected if the major mode's associated\n LSP binary is detected on the system."
      (when (require 'eglot nil :noerror)
          (+my/ide--add-eglot-hooks
            (seq-filter
              #'+my/ide--lsp-bin-exists-p
              eglot-server-programs))))

    ;; Automatically register `eglot-ensure' hooks for relevant major
    ;; modes (notably `rust-ts-mode').
    (+my/ide-eglot-auto-ensure-all))

(use-package eglot-signature-eldoc-talkative
:after (eglot)
  :init (add-to-list 'package-selected-packages 'eglot-signature-eldoc-talkative)
  :config
    (advice-add #'eglot-signature-eldoc-function :override
      #'eglot-signature-eldoc-talkative))

(use-package eglot-tempel
  :after (eglot tempel)
  :init (add-to-list 'package-selected-packages 'eglot-tempel))

(use-package consult-eglot
  :after (consult eglot)
  :init (add-to-list 'package-selected-packages 'consult-eglot))

(use-package consult-eglot-embark
  :after (consult-eglot embark)
  :init (add-to-list 'package-selected-packages 'consult-eglot-embark)
  :config
    (consult-eglot-embark-mode t))
;;; }}} *** eglot

;;; {{{ *** elisp-demos
;; also add some examples
(use-package elisp-demos
  :init (add-to-list 'package-selected-packages 'elisp-demos)
  :config
    (advice-add 'helpful-update :after #'elisp-demos-advice-helpful-update))
;;; }}} *** elisp-demos

;;; {{{ *** exercism
(use-package exercism
  :demand t
  :init (add-to-list 'package-selected-packages 'exercism)
  :custom
    (exercism-workspace-directory "~/projects/Exercism")
    (exercism-api-url "https://api.exercism.io/v1")
    (exercism-api-key "c17599fa-0f88-4674-88f8-ce082d70ac80")
    (exercism-track "elisp")
    (exercism-username "StandAloneComplex")
  :commands
    (exercism exercism-download exercism-submit))
;;; }}} *** exercism

;;; {{{ *** flycheck
(use-package flycheck
  :init (add-to-list 'package-selected-packages 'flycheck)
  :custom
    (flycheck-emacs-lisp-load-path 'inherit "necessary with alternatives to package.el")
  :commands
    (flycheck-mode)
  :config
    (global-flycheck-mode t))

(use-package flycheck-eglot
  :after (flycheck eglot)
  :init (add-to-list 'package-selected-packages 'flycheck-eglot)
  :custom (flycheck-eglot-exclusive nil)
  :config
    (global-flycheck-eglot-mode t))

(use-package flycheck-package
  :after (flychceck)
  :init (add-to-list 'package-selected-packages 'flycheck-package)
  :config
    (flycheck-package-setup)
    (add-to-list 'display-buffer-alist
                  '("\\*Flycheck errors\\*"  display-buffer-below-selected (window-height . 0.15))))
;;; }}} *** flycheck

;;; {{{ *** flymake
(use-package flymake
  :after (eglot)
  :init (add-to-list 'package-selected-packages 'flymake)
  ;; :bind (
  ;;   ;; Suggested additional keybindings
  ;;   :map prog-mode-map
  ;;     ("C-c e n"        . #'flymake-goto-next-error)
  ;;     ("C-c e p"        . #'flymake-goto-prev-error))
  :config
    (add-to-list 'display-buffer-alist
                  '("\\`\\*Flymake diagnostics.*?\\*\\'"
                    display-buffer-in-side-window
                    (window-parameters (window-height 0.10))
                    (side . bottom)))
    (defun +my/flymake-elpaca-bytecomp-load-path ()
      "Augment `elisp-flymake-byte-compile-load-path' to support Elpaca."
      (setq-local elisp-flymake-byte-compile-load-path
                  `("./" ,@(mapcar #'file-name-as-directory
                            (nthcdr 2 (directory-files (expand-file-name "builds" elpaca-directory) 'full))))))
    (add-hook 'flymake-mode-hook                #'+my/flymake-elpaca-bytecomp-load-path)

    (add-hook 'flymake-mode-hook                #'(lambda ()
                                                  (or (ignore-errors flymake-show-project-diagnostics)
                                                      (flymake-show-buffer-diagnostics))))

    (flymake-mode t))
;;; }}} *** flymake

;;; {{{ *** dart & flutter
(use-package dart-mode
  :init (add-to-list 'package-selected-packages 'dart-mode)
  :custom
    (dart-format-on-save t)
    ;; (dart-sdk-path "/opt/homebrew/flutter/bin/cache/dart-sdk")
  :mode
    ("\\.dart\\'" . dart-mode)
  :config
    (add-hook 'dart-mode-hook                   #'(lambda ()
                                                    (setq-local flycheck-checker 'dartanalyzer)
                                                    (flycheck-mode t)))
    (add-hook 'dart-mode-hook                   #'lsp)
    (add-hook 'dart-mode-hook                   #'flymake-mode))

(use-package flutter
  :after (dart-mode)
  :init (add-to-list 'package-selected-packages 'flutter)
  :custom
    ;; (flutter-sdk-path "/usr/local/flutter")
    (flutter-command "flutter")
    (flutter-test-command "flutter test")
    (flutter-run-command "flutter run")
    (flutter-hot-reload-command "flutter hot reload")
    (flutter-hot-restart-command "flutter hot restart")
    (flutter-debug-command "flutter run --debug")
    (flutter-release-command "flutter run --release")
    (flutter-screenshot-command "flutter screenshot")
    (flutter-screenshot-scale 1.0)
    (flutter-screenshot-observatory-port 8888)
    ;; (flutter-screenshot-observatory-address "")
  :bind (
    :map dart-mode-map
      ("C-M-x"    . flutter-run-or-hot-reload)
      ("C-c C-f"  . flutter-run-or-hot-reload)
      ("C-c C-r"  . flutter-run-or-hot-restart)
      ("C-c C-s"  . flutter-screenshot))
      ("C-c C-t"  . flutter-test)
  :mode
    ("\\.dart\\'" . flutter-mode)
  :config
    (add-hook 'dart-mode-hook                   #'flutter-test-mode)
    (add-hook 'dart-mode-hook                   #'flutter-run-mode))
;;; }}} *** dart & flutter

;;; {{{ *** elixir
;;; {{{ **** elixir-mode
(use-package elixir-mode
  :after (elixir-ts-mode)
  :init (add-to-list 'package-selected-packages 'elixir-mode)
  :custom
    (elixir-format-command "/run/current-system/sw/bin/mix")
  :hook (
    (elixir-mode-hook                   . eglot-ensure)
    (elixir-mode-hook                   . (lambda ()
                                            (push '("->" . ?\u2192) prettify-symbols-alist)
                                            (push '("!=" . ?\u2260) prettify-symbols-alist)
                                            (push '("<-" . ?\u2190) prettify-symbols-alist)
                                            (push '("<-" . ?\u2190) prettify-symbols-alist)
                                            (push '("<=" . ?\u2264) prettify-symbols-alist)
                                            (push '("==" . ?\u2A75) prettify-symbols-alist)
                                            (push '("=~" . ?\u2245) prettify-symbols-alist)
                                            (push '(">=" . ?\u2265) prettify-symbols-alist)
                                            (push '("|>" . ?\u25B7) prettify-symbols-alist)))
    (before-save-hook                   . elixir-format))
  :mode (
    ("\\.elixir\\'"                     . elixir-mode)
    ("\\.elixir2\\'"                    . elixir-mode)
    ("\\.exs?\\'"                       . elixir-mode))
  :config
;; Create a buffer-local hook to run elixir-format on save, only when we enable elixir-mode.
    (add-hook 'elixir-mode-hook         (lambda () (add-hook 'before-save-hook 'elixir-format nil t)))
    (add-hook 'elixir-mode-hook         #'prettify-symbols-mode)
    (add-hook 'elixir-mode-hook         #'rainbow-delimiters-mode)
    (add-hook 'elixir-mode-hook         #'rainbow-identifiers-mode)
    (add-hook 'elixir-mode-hook         #'rainbow-mode)
    (add-hook 'elixir-mode-hook         #'smartparens-mode)
    (add-hook 'elixir-mode-hook         #'subword-mode)
    (add-hook 'elixir-mode-hook         #'yas-minor-mode)
    (add-hook 'elixir-mode-hook         #'flycheck-mode)
    (add-hook 'elixir-mode-hook         #'flymake-mode))
;;; }}} **** elixir-mode

;;; {{{ **** elixir-ts-mode
(use-package elixir-ts-mode
  :init (add-to-list 'package-selected-packages 'elixir-ts-mode)
  :custom
    (elixir-ts-mode-elixir-path "/run/current-system/sw/bin/elixir")
    (elixir-ts-mode-elixirc-path "/run/current-system/sw/bin/elixirc")
    (elixir-ts-mode-mix-path "/run/current-system/sw/bin/mix")
  :hook (
    (elixir-ts-mode-hook                . eglot-ensure)
    (elixir-ts-mode-hook                . (lambda ()
                                            (push '("->" . ?\u2192) prettify-symbols-alist)
                                            (push '("!=" . ?\u2260) prettify-symbols-alist)
                                            (push '("<-" . ?\u2190) prettify-symbols-alist)
                                            (push '("<-" . ?\u2190) prettify-symbols-alist)
                                            (push '("<=" . ?\u2264) prettify-symbols-alist)
                                            (push '("==" . ?\u2A75) prettify-symbols-alist)
                                            (push '("=~" . ?\u2245) prettify-symbols-alist)
                                            (push '(">=" . ?\u2265) prettify-symbols-alist)
                                            (push '("|>" . ?\u25B7) prettify-symbols-alist)))
    (before-save-hook                   . elixir-format))
  :mode (
    ("\\.elixir\\'"                     . elixir-ts-mode)
    ("\\.elixir2\\'"                    . elixir-ts-mode)
    ("\\.exs?\\'"                       . elixir-ts-mode))
  :config
    ;; Make sure to edit the path appropriately, use the .bat script instead for Windows
    ;; (add-to-list 'eglot-server-programs '(elixir-mode "/run/current-system/sw/bin/elixir-ls"))

    (add-hook 'elixir-ts-mode-hook        #'prettify-symbols-mode)
    (add-hook 'elixir-ts-mode-hook        #'rainbow-delimiters-mode)
    (add-hook 'elixir-ts-mode-hook        #'rainbow-identifiers-mode)
    (add-hook 'elixir-ts-mode-hook        #'rainbow-mode)
    (add-hook 'elixir-ts-mode-hook        #'smartparens-mode)
    (add-hook 'elixir-ts-mode-hook        #'subword-mode)
    (add-hook 'elixir-ts-mode-hook        #'yas-minor-mode)
    (add-hook 'elixir-ts-mode-hook        #'flycheck-mode)
    (add-hook 'elixir-ts-mode-hook        #'flymake-mode))
;;; }}} **** elixir-ts-mode

;;; {{{ **** exunit
(use-package exunit
  :init (add-to-list 'package-selected-packages 'exunit)
  :custom
    (exunit-key-command-prefix (kbd "C-c ,"))
  :config
    (add-hook 'elixir-mode-hook #'exunit-mode))
;;; }}} **** exunit

;;; {{{ **** mix
(use-package mix
  :init (add-to-list 'package-selected-packages 'mix)
  :custom
    (mix-command "/run/current-system/sw/bin/mix")
  :config
    (add-hook 'elixir-mode-hook                 #'mix-minor-mode))
;;; }}} **** mix
;;; }}} *** elixir

;;; {{{ *** erlang
(use-package erlang
  :init (add-to-list 'package-selected-packages 'erlang)
  :custom
    (erlang-root-dir "~/.local/share/asdf/installs/erlang/27.0")
  :hook (
    (erlang-mode-hook . (lambda ()
                          (setq-local flycheck-checker 'erlang)
                          (flycheck-mode t)))
    (erlang-mode-hook . (lambda ()
                          (setq-local flymake-command '("erlc" "-Wall" "-o" "/tmp" "-I" "." "-pa" "." "-pa" "~/.local/share/asdf/installs/erlang/27.0/lib/tools-4.0/emacs" source-inplace))))
    (erlang-mode-hook . (lambda ()
                          (setq-local flymake-err-line-patterns
                                      '(("^\\(.+\\):\\([0-9]+\\): \\(.+\\)$" 1 2 nil 3))))))
  :mode (
    ("\\.app\\'"      . erlang-mode)
    ("\\.appup\\'"    . erlang-mode)
    ("\\.beam\\'"     . erlang-mode)
    ("\\.config\\'"   . erlang-mode)
    ("\\.erl\\'"      . erlang-mode)
    ("\\.erlang\\'"   . erlang-mode)
    ("\\.es\\'"       . erlang-mode)
    ("\\.escript\\'"  . erlang-mode)
    ("\\.hrl\\'"      . erlang-mode)
    ("\\.rel\\'"      . erlang-mode)
    ("\\.script\\'"   . erlang-mode)
    ("\\.xrl\\'"      . erlang-mode)
    ("\\.yaws\\'"     . erlang-mode)
    ("\\.yrl\\'"      . erlang-mode)))

;;; {{{ **** edts
(use-package edts
  :init (add-to-list 'package-selected-packages 'edts)
  :custom
    (edts-erlang-root-dir "~/.local/share/asdf/installs/erlang/27.0")
    (edts-erlang-cookie-file (no-littering-expand-var-file-name "erlang/.erlang-cookie") "no-littering `edts-erlang-cookie-file'")
  :hook (
    (erlang-mode-hook                   . edts-mode))
  :config
    (add-hook 'after-init-hook '+my/edts-after-init-hook)
    (defun +my/edts-after-init-hook ()
      (require 'edts-start)))
;;; }}} **** edts

;;; {{{ **** flycheck-elixir
(use-package flycheck-elixir
  :after (flycheck elixir-ts-mode)
  :init (add-to-list 'package-selected-packages 'flycheck-elixir)
  :config
    (flycheck-elixir-setup))
;;; }}} **** flycheck-elixir

;;; {{{ **** flycheck-credo
(use-package flycheck-credo
  :after (flycheck elixir-ts-mode)
  :init (add-to-list 'package-selected-packages 'flycheck-credo)
  :config
    (flycheck-credo-setup))
;;; }}} **** flycheck-credo

;;; {{{ **** flycheck-dialyzer
(use-package flycheck-dialyzer
  :after (flycheck erlang)
  :init (add-to-list 'package-selected-packages 'flycheck-dialyzer)
  :config
    (flycheck-dialyzer-setup))
;;; }}} **** flycheck-dialyzer

;;; {{{ **** gleam
(use-package gleam-ts-mode
  :ensure (:host github :repo "gleam-lang/gleam-mode")
  :init (add-to-list 'package-selected-packages 'gleam-mode)
  :custom
    (gleam-format-on-save t)
    (gleam-ts-mode-elixir-path "/run/current-system/sw/bin/elixir")
    (gleam-ts-mode-elixirc-path "/run/current-system/sw/bin/elixirc")
    (gleam-ts-mode-mix-path "/run/current-system/sw/bin/mix")
  :bind (
    :map gleam-ts-mode-map
      ("C-c C-f"    . gleam-ts-format))
  :mode (
    ("\\.gleam"                         . gleam-ts-mode))
  :config
    (add-hook 'gleam-ts-mode-hook        #'eglot-ensure)
    (add-hook 'gleam-ts-mode-hook        #'flycheck-mode)
    (add-hook 'gleam-ts-mode-hook        #'flymake-mode)
    (add-hook 'gleam-ts-mode-hook        #'prettify-symbols-mode)
    (add-hook 'gleam-ts-mode-hook        #'rainbow-delimiters-mode)
    (add-hook 'gleam-ts-mode-hook        #'rainbow-identifiers-mode)
    (add-hook 'gleam-ts-mode-hook        #'rainbow-mode)
    (add-hook 'gleam-ts-mode-hook        #'smartparens-mode)
    (add-hook 'gleam-ts-mode-hook        #'subword-mode)
    (add-hook 'gleam-ts-mode-hook        #'yas-minor-mode)
    (add-hook 'gleam-ts-mode-hook       (lamda ()
                                          (add-hook 'before-save-hook 'gleam-format nil t)))
    (add-hook 'gleam-ts-mode-hook       (lamda ()
                                          (push '("->" . ?\u2192) prettify-symbols-alist)
                                          (push '("!=" . ?\u2260) prettify-symbols-alist)
                                          (push '("<-" . ?\u2190) prettify-symbols-alist)
                                          (push '("<-" . ?\u2190) prettify-symbols-alist)
                                          (push '("<=" . ?\u2264) prettify-symbols-alist)
                                          (push '("==" . ?\u2A75) prettify-symbols-alist)
                                          (push '("=~" . ?\u2245) prettify-symbols-alist)
                                          (push '(">=" . ?\u2265) prettify-symbols-alist)
                                          (push '("|>" . ?\u25B7) prettify-symbols-alist))))
;;; }}} **** gleam
;;; }}} *** erlang

;;; {{{ *** git
;;; {{{ **** git-timemachine
(use-package git-timemachine
  :init (add-to-list 'package-selected-packages 'git-timemachine))
;;; }}} **** git-timemachine

;;; {{{ **** magit
(use-package magit
  :ensure (magit :fetcher github :repo "magit/magit")
  :if (executable-find "git")
  :after (transient)
  :init (add-to-list 'package-selected-packages 'magit)

    (progn
      ;; magit extensions
      ;; Close popup when commiting -- this stops the commit window hanging around
      ;; From: http://git.io/rPBE0Q
      (defadvice git-commit-abort (after delete-window activate)
        (delete-window))
      (defadvice git-commit-commit (after delete-window activate)
        (delete-window))
      ;; make magit status go full-screen but remember previous window settings
      ;; from: http://whattheemacsd.com/setup-magit.el-01.html
      (defadvice magit-status (around magit-fullscreen activate)
        (window-configuration-to-register :m)
        ad-do-it
        (delete-other-windows))
      ;; force a new line to be inserted into a commit window,
      ;; which stops the invalid style showing up.
      ;; From: http://git.io/rPBE0Q
      (defun +my/magit-commit-mode-init ()
        (when (looking-at "\n")
            (open-line 1))))
  :custom
    ;; magit settings
    ;; don't put "origin-" in front of new branch names by default
    (magit-default-tracking-name-function 'magit-default-tracking-name-branch-only)
    (magit-diff-refine-hunk t)                              ;; highlight word/letter changes in hunk diffs
    (magit-process-popup-time 10)                           ;; pop the process buffer after a while
    (magit-rewrite-inclusive 'ask)                          ;; ask to include a revision when rewriting
    (magit-save-some-buffers nil)                           ;; ask to save buffers
    (magit-status-buffer-switch-function 'switch-to-buffer) ;; status in same window as current buffer
    (magit-set-upstream-on-push 'askifnotset)               ;; ask me if I want a tracking upstream
    (vc-display-status nil)
  ;; :bind (
  ;;   ("C-c g"    . magit-status)
  ;;   :map magit-mode-map
  ;;     ("c"    . 'magit-maybe-commit)
  ;;   :map magit-status-mode-map
  ;;     ("M-RET"    . magit-diff-visit-file-other-window)
  ;;     ("q"        . magit-quit-session))
  :commands (magit-get-top-dir)
  :config
    (progn
      (defadvice magit-quit-window (around magit-restore-screen activate)
        ;; restore previously hidden windows
        ;; major mode for editing `git rebase -i`
        (let ((current-mode major-mode))
          ad-do-it
          ;; we only want to jump to register when the last seen buffer
          ;; was a magit-status buffer.
          (when (eq 'magit-status-mode current-mode)
              (jump-to-register :m))))
      (defadvice magit-status (around magit-fullscreen activate)
        ;; full screen magit-status
        (window-configuration-to-register :magit-fullscreen)
        ad-do-it
        (delete-other-windows))
      (defun +my/magit-log-follow-current-file ()
        "A wrapper around `magit-log-buffer-file' with `--follow' argument."
        (interactive)
        (magit-log-buffer-file t))
      (defun +my/magit-maybe-commit (&optional show-options)
        "Runs magit-commit unless prefix is passed"
        (interactive "P")
        (if show-options
            (magit-key-mode-popup-committing)
          (magit-commit)))
      (defun +my/magit-quit-session ()
        "Restores the previous window configuration and kills the magit buffer"
        (interactive)
        (kill-buffer)
        (jump-to-register :magit-fullscreen))
      ;; Customizing transients
      ;; This gives us the option to override local branch
      (transient-insert-suffix 'magit-pull "-r" '("-f" "Overwrite local branch" "--force")))

    (add-hook 'git-commit-mode-hook             #'+my/magit-commit-mode-init))
;;; }}} **** magit

;;; {{{ **** forge
(use-package forge
  :ensure (forge :fetcher github :repo "magit/forge")
  :after (magit)
  :init (add-to-list 'package-selected-packages 'forge)
  :custom
    (gnutls-algorithm-priority "NORMAL:-VERS-TLS1.3"))
;;; }}} **** forge

;;; {{{ **** magit-todos
(use-package magit-todos
  :after (magit hl-todo)
  :init (add-to-list 'package-selected-packages 'magit-todos)
  :config
    (magit-todos-mode t))
;;; }}} **** magit-todos

;;; {{{ **** orgit
(use-package orgit
  :after (magit org)
  :init (add-to-list 'package-selected-packages 'orgit))
;;; }}} **** orgit

;;; {{{ **** orgit-forge
(use-package orgit-forge
  :after (magit org forge)
  :init (add-to-list 'package-selected-packages 'orgit-forge))
;;; }}} **** orgit-forge

;;; {{{ **** transient
(use-package transient
  :ensure (transient :fetcher github :repo "magit/transient")
  :init (add-to-list 'package-selected-packages 'transient))
;;; }}} **** transient

;;; }}} *** git

;;; {{{ *** harpoon
(use-package harpoon
  :init (add-to-list 'package-selected-packages 'harpoon)
)
;;; }}} *** harpoon

;;; {{{ *** haskell
;;; {{{ **** haskell-mode
(use-package haskell-mode
  :init (add-to-list 'package-selected-packages 'haskell-mode)
  :config
    (add-hook 'haskell-mode-hook                #'interactive-haskell-mode
                                                #'haskell-auto-insert-module-template)
    (add-hook 'haskell-mode-hook                #'haskell-indentation-mode)
    (add-hook 'haskell-mode-hook                #'haskell-doc-mode)
    (add-hook 'haskell-mode-hook                #'haskell-decl-scan-mode)
    (add-hook 'haskell-mode-hook                #'haskell-cabal-mode))
;;; }}} **** haskell-mode

;;; {{{ **** flycheck-haskell
(use-package flycheck-haskell
  :after (flycheck haskell-mode)
  :init (add-to-list 'package-selected-packages 'flycheck-haskell)
  :config
    (add-hook 'flycheck-mode-hook               #'flycheck-haskell-setup))
;;; }}} **** flycheck-haskell

;;; {{{ **** dante
(use-package dante
  :ensure t ; ask use-package to install the package
  :after haskell-mode
  :init (add-to-list 'package-selected-packages 'dante)
  :commands 'dante-mode
  :init
    ;; flycheck backend deprecated October 2022
    ;; (add-hook 'haskell-mode-hook 'flycheck-mode)

    (add-hook 'haskell-mode-hook 'flymake-mode)
    (remove-hook 'flymake-diagnostic-functions 'flymake-proc-legacy-flymake)
    (add-hook 'haskell-mode-hook 'dante-mode)
    (add-hook 'haskell-mode-hook
              (defun +my/dante-fix-hs-eldoc ()
                (setq eldoc-documentation-strategy #'eldoc-documentation-default)))
  :custom
    (dante-repl-command-line '("nix-shell" "--run" "cabal repl"))
    (dante-repl-command-line-methods-alist '((nix-shell . dante-repl-nix-shell)))
  :config
    (require 'flymake-flycheck)
    (defalias 'flymake-hlint
      (flymake-flycheck-diagnostic-function-for 'haskell-hlint))
    (add-to-list 'flymake-diagnostic-functions 'flymake-hlint)
    ;; flycheck backend deprecated October 2022
    ;; (flycheck-add-next-checker 'haskell-dante '(info . haskell-hlint)))

    (defun +my/dante-repl-nix-shell (root)
      "Return the command line to start a REPL in the project's nix-shell."
      (list "nix-shell" "--run" "cabal repl"))

    (add-hook 'dante-mode-hook
              (defun +my/dante-mode-hook ()
                (flymake-mode -1)
                (flycheck-mode 1)
                (flycheck-add-next-checker 'haskell-dante '(info . haskell-hlint)))))
;;; }}} **** dante
;;; }}} *** haskell

;;; {{{ *** ibuffer
;;; {{{ **** ibuffer-project
;; enhance ibuffer with ibuffer-project if it is available.
(use-package ibuffer-project
  :init (add-to-list 'package-selected-packages 'ibuffer-project)

    (custom-set-variables
      '(ibuffer-formats
        '((mark modified read-only locked " "
          (name 18 18 :left :elide) " "
          (size 9 -1 :right) " "
          (mode 16 16 :left :elide) " "
          project-file-relative))))

    (defun +my/ide-enhance-ibuffer-with-ibuffer-project ()
        "Set up integration for `ibuffer' with `ibuffer-project'."
        (setopt ibuffer-filter-groups (ibuffer-project-generate-filter-groups))
        (unless (eq ibuffer-sorting-mode 'project-file-relative)
            (ibuffer-do-sort-by-project-file-relative)))

  :config
    (add-hook 'ibuffer-hook                      #'+my/ide-enhance-ibuffer-with-ibuffer-project)
    (add-to-list 'ibuffer-project-root-functions '(file-remote-p . "Remote")))
;;; }}} **** ibuffer-project

;;; {{{ **** ibuffer-sidebar
(use-package ibuffer-sidebar
  :init (add-to-list 'package-selected-packages 'ibuffer-sidebar)
  :custom
    (ibuffer-sidebar-use-custom-font t)
  :custom-face
    (ibuffer-sidebar-face ((t (:family "Helvetica" :height 140))))
  :commands (ibuffer-sidebar-toggle-sidebar)
  :config
    ;; Sidebar can also be toggled together with dired-sidebar.
    (defun +my/sidebar-toggle ()
      "Toggle both `dired-sidebar' and `ibuffer-sidebar'."
      (interactive)
      (dired-sidebar-toggle-sidebar)
      (ibuffer-sidebar-toggle-sidebar)))
;;; }}} **** ibuffer-sidebar

;;; {{{ **** ibuffer-tramp
(use-package ibuffer-tramp
  :init (add-to-list 'package-selected-packages 'ibuffer-tramp))
;;; }}} **** ibuffer-tramp

;;; {{{ **** ibuffer-vc
(use-package ibuffer-vc
  :ensure (:source "GNU-devel ELPA" :depth nil)
  :init (add-to-list 'package-selected-packages 'ibuffer-vc))
;;; }}} **** ibuffer-vc
;;; }}} *** ibuffer

;;; {{{ *** lisp
;; Configuration for the Lisp family of languages, including Common
;; Lisp, Clojure, Scheme, and Racket.

;; For Common Lisp, configure SLY and a few related packages.
;;    An implementation of CL will need to be installed, examples are:
;;    * CLISP (GNU Common Lisp)
;;    * CMUCL (Carnegie-Mellon Common Lisp)
;;    * SBCL (Steel-Bank Common Lisp)


;; For Clojure, configure cider, clj-refactor

;; For Scheme and Racket, configure geiser.
;;   Out of the box, geiser already supports some scheme
;;   implementations.  However, there are several modules which can be
;;   added to geiser for specific implementations:
;;   * geiser-chez
;;   * geiser-chibi
;;   * geiser-chicken
;;   * geiser-gambit
;;   * geiser-gauche
;;   * geiser-guile
;;   * geiser-kawa
;;   * geiser-mit
;;   * geiser-racket
;;   * geiser-stklos

;;; **** Global defaults
(require 'eldoc)

;;; {{{ **** Indentation
(use-package aggressive-indent
  :init (add-to-list 'package-selected-packages 'aggressive-indent)
  :config
    (add-hook 'clojure-mode-hook                #'aggressive-indent-mode)
    (add-hook 'lisp-mode-hook                   #'aggressive-indent-mode)
    (add-hook 'scheme-mode-hook                 #'aggressive-indent-mode))
;;; }}} **** Indentation

;;; {{{ **** Emacs Lisp
(use-package buttercup
  :init (add-to-list 'package-selected-packages 'buttercup)
  :commands (buttercup-run-at-point))

;;; {{{ ***** macrostep
;; macrostep is an Emacs minor mode for interactively stepping through the expansion of macros in Emacs Lisp source code.
;; https://github.com/joddie/macrostep
(use-package macrostep
  :init (add-to-list 'package-selected-packages 'macrostep)
  ;; :bind (
  ;;   :map emacs-lisp-mode-map
  ;;     ("C-c c"    . macrostep-collapse)
  ;;     ("C-c e"    . macrostep-expand)
  ;;     ("C-c n"    . macrostep-next-macro)
  ;;     ("C-c p"    . macrostep-prev-macro))
)
;;; }}} ***** macrostep

;;; {{{ ***** package-lint
(use-package package-lint
  :ensure (:wait t)
  :init (add-to-list 'package-selected-packages 'package-lint)
  :commands
    (package-lint-current-buffer +package-lint-elpaca)
  :config
    (defun +my/package-lint-elpaca ()
      "Help package-lint deal with elpaca."
      (interactive)
      (require 'package)
      (setq package-user-dir (make-temp-file "emacs-package-dir-" t))
      (add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/") t)
      (package-initialize)
      (package-refresh-contents))
    (add-hook 'elpaca-after-init-Hook           #'+my/package-lint-elpaca)
    (+package-lint-elpaca))

(use-package package-lint-flymake
  :after (flymake package-lint)
  :init (add-to-list 'package-selected-packages 'package-lint-flymake)
  :config
    (add-hook 'emacs-lisp-mode-hook             #'package-lint-flymake-setup))
;;; }}} ***** package-lint
;;; }}} **** Emacs Lisp

;;; {{{ **** sly (common lisp)
(use-package sly
  :init (add-to-list 'package-selected-packages 'sly)
  :config
    (add-hook #'lisp-mode-hook                  #'sly-editing-mode)
    ;; Uncomment and update if you need to set the path to an
    ;; implementation of common lisp. This would be needed only if you
    ;; have multiple instances of common lisp installed, for example,
    ;; both CLISP and SBCL. In this case, we are assuming SBCL.
    ;; (setq inferior-lisp-program "/usr/bin/sbcl")

    (load (expand-file-name "~/quicklisp/slime-helper.el"))
    ;; Replace "sbcl" with the path to your implementation
    (setopt inferior-lisp-program "sbcl")

    (require 'sly-asdf "sly-asdf" :no-error)
    (require 'sly-quicklisp "sly-quicklisp" :no-error)
    (require 'sly-repl-ansi-color "sly-repl-ansi-color" :no-error))
;;; }}} **** sly (common lisp)

;;; {{{ **** clojure
(use-package cider
  :after (clojure-mode)
  :init (add-to-list 'package-selected-packages 'cider))

(use-package clj-refactor
  :after (clojure-mode)
  :init (add-to-list 'package-selected-packages 'clj-refactor)
  :config
    (clj-refactor-mode t)
    (cljr-add-keybindings-with-prefix "C-c r")
    (defun +my/lisp-load-clojure-refactor ()
      "Load `clj-refactor' toooling and fix keybinding conflicts with cider."
      (clj-refactor-mode t)
      ;; keybindings mentioned on clj-refactor github page
      ;; conflict with cider, use this by default as it does
      ;; not conflict and is a better mnemonic
      (cljr-add-keybindings-with-prefix "C-c r"))
    (add-hook 'clojure-mode-hook #'+my/lisp-load-clojure-refactor))

(use-package clojure-mode
  :init (add-to-list 'package-selected-packages 'clojure-mode)
  :config
    (require 'cider "cider" :no-error)
    (require 'clj-refactor "clj-refactor" :no-error))

(use-package flycheck-clojure
  :after (clojure-mode flycheck)
  :init (add-to-list 'package-selected-packages 'flycheck-clojure)
  :config
    (flycheck-clojure-setup))

(use-package inflections
  :ensure (:depth nil)
  :init (add-to-list 'package-selected-packages 'inflections))
;;; }}} **** clojure

;;; {{{ **** scheme and guile
(use-package geiser
  :init (add-to-list 'package-selected-packages 'geiser)
  :custom
    ;; The default is "scheme" which is used by cmuscheme, xscheme and
    ;; chez (at least). We are configuring guile, so use the apporpriate
    ;; command for that implementation.
    (scheme-program-name "guile"))

(use-package geiser-guile
  :init (add-to-list 'package-selected-packages 'geiser-guile))

(use-package flymake-guile
  :init (add-to-list 'package-selected-packages 'flymake-guile)
  :config
    (add-hook 'scheme-mode-hook                 #'flymake-guile))

(use-package geiser-racket
  :disabled
  :init (add-to-list 'package-selected-packages 'geiser-racket))
;;; }}} **** scheme and guile
;;; }}} *** lisp

;;; {{{ *** lua
;;; {{{ **** lua-mode
(use-package lua-mode
  :init (add-to-list 'package-selected-packages 'lua-mode)
  :mode (("\\.lua\\'" . lua-mode))
  :config
    (add-hook 'lua-mode-hook                    #'lua-electric-mode)
    (add-hook 'lua-mode-hook                    #'lua-font-lock-keywords)
    (add-hook 'lua-mode-hook                    #'lua-mode-set-constants)
    (add-hook 'lua-mode-hook                    #'lua-mode-set-functions)
    (add-hook 'lua-mode-hook                    #'lua-mode-set-variables))
;;; }}} **** lua-mode

;;; {{{ **** luarocks
(use-package luarocks
  :init (add-to-list 'package-selected-packages 'luarocks))
;;; }}} **** luarocks
;;; }}} *** lua

;;; {{{ *** ocaml
;; Major mode for OCaml programming
;;; {{{ **** tuareg
(use-package tuareg
  :init (add-to-list 'package-selected-packages 'tuareg)
  :mode (("\\.ocamlinit\\'" . tuareg-mode))
  :config
    (add-hook 'tuareg-mode-hook                 #'aggressive-indent-mode)
    (add-hook 'tuareg-mode-hook                 #'eldoc-mode)
    (add-hook 'tuareg-mode-hook                 #'flycheck-ocaml-setup)
    (add-hook 'tuareg-mode-hook                 #'flymake-mode)
    (add-hook 'tuareg-mode-hook                 #'highlight-comments-mode)
    (add-hook 'tuareg-mode-hook                 #'highlight-constants-mode)
    (add-hook 'tuareg-mode-hook                 #'highlight-escape-sequences)
    (add-hook 'tuareg-mode-hook                 #'highlight-functions-mode)
    (add-hook 'tuareg-mode-hook                 #'highlight-keywords-mode)
    (add-hook 'tuareg-mode-hook                 #'highlight-numbers-mode)
    (add-hook 'tuareg-mode-hook                 #'highlight-operators-mode)
    (add-hook 'tuareg-mode-hook                 #'highlight-operators-mode)
    (add-hook 'tuareg-mode-hook                 #'highlight-parentheses-mode)
    (add-hook 'tuareg-mode-hook                 #'highlight-quoted-mode)
    (add-hook 'tuareg-mode-hook                 #'highlight-strings-mode)
    (add-hook 'tuareg-mode-hook                 #'highlight-types-mode)
    (add-hook 'tuareg-mode-hook                 #'highlight-variables-mode)
    (add-hook 'tuareg-mode-hook                 #'highlight-variables-mode)
    (add-hook 'tuareg-mode-hook                 #'merlin-mode)
    (add-hook 'tuareg-mode-hook                 #'rainbow-delimiters-mode)
    (add-hook 'tuareg-mode-hook                 #'tuareg-eldoc-setup)
    (add-hook 'tuareg-mode-hook                 #'tuareg-electric-mode)
    (add-hook 'tuareg-mode-hook                 #'tuareg-font-lock-setup)
    (add-hook 'tuareg-mode-hook                 #'tuareg-imenu-set-imenu)
    (add-hook 'tuareg-mode-hook                 #'tuareg-indent-setup)
    (add-hook 'tuareg-mode-hook                 #'utop-minor-mode)
    (add-hook 'tuareg-mode-hook                 #'utop-setup-ocaml-buffer)
    (add-hook 'tuareg-mode-hook
              (lambda()
                (setq-local comment-continue "   ")
                (setq-local comment-style 'multi-line)
                (setq tuareg-mode-name "🐫")
                (when (functionp 'prettify-symbols-mode)
                    (prettify-symbols-mode t)))))
;;; }}} **** tuareg

;;; {{{ **** dune
;; Major mode for editing Dune project files
(use-package dune
  :init (add-to-list 'package-selected-packages 'dune)
  :custom
    (dune-use-dune-mode t)
  :mode (("\\(?:dune\\(?:\\.inc\\)?\\|jbuild\\)\\'" . dune-mode))
  :config
    (add-hook 'dune-mode-hook                   #'highlight-comments-mode)
    (add-hook 'dune-mode-hook                   #'highlight-constants-mode)
    (add-hook 'dune-mode-hook                   #'highlight-escape-sequences)
    (add-hook 'dune-mode-hook                   #'highlight-functions-mode)
    (add-hook 'dune-mode-hook                   #'highlight-keywords-mode)
    (add-hook 'dune-mode-hook                   #'highlight-numbers-mode)
    (add-hook 'dune-mode-hook                   #'highlight-operators-mode)
    (add-hook 'dune-mode-hook                   #'highlight-parentheses-mode)
    (add-hook 'dune-mode-hook                   #'highlight-quoted-mode)
    (add-hook 'dune-mode-hook                   #'highlight-strings-mode)
    (add-hook 'dune-mode-hook                   #'highlight-types-mode)
    (add-hook 'dune-mode-hook                   #'highlight-variables-mode)
    (add-hook 'dune-mode-hook                   #'rainbow-delimiters-mode)
    (add-hook 'dune-mode-hook                   #'tuareg-eldoc-setup)
    (add-hook 'dune-mode-hook                   #'tuareg-electric-mode)
    (add-hook 'dune-mode-hook                   #'tuareg-font-lock-setup)
    (add-hook 'dune-mode-hook                   #'tuareg-imenu-set-imenu)
    (add-hook 'dune-mode-hook                   #'tuareg-indent-setup))
;;; }}} **** dune

;; This uses Merlin internally
(use-package flycheck-ocaml
  :init (add-to-list 'package-selected-packages 'flycheck-ocaml)
  :custom
    (flycheck-ocaml-executable "ocaml")
    (flycheck-ocaml-merlin-executable "ocamlmerlin")
    (flycheck-ocaml-merlin-args '("merlin" "locate"))
  :config
    (add-hook 'tuareg-mode-hook                 #'flycheck-ocaml-setup)
    (flycheck-ocaml-setup))

;; learn-ocaml
(use-package learn-ocaml
  :init (add-to-list 'package-selected-packages 'learn-ocaml)
  :commands (learn-ocaml))

;; Merlin provides advanced IDE features
(use-package merlin
  :init (add-to-list 'package-selected-packages 'merlin)
  :custom
    (merlin-error-after-save nil "Don't check errors after saving, we're using flycheck instead.")
  :config
    (add-hook 'caml-mode-hook                   #'merlin-mode t)
    (add-hook 'reason-mode-hook                 #'merlin-mode t)
    (add-hook 'tuareg-mode-hook                 #'merlin-mode t)
    (add-hook 'tuareg-mode-hook                 #'merlin-use-merlin-imenu)
    (add-hook 'tuareg-mode-hook                 #'merlin-use-merlin-eldoc)
    (add-hook 'tuareg-mode-hook                 #'merlin-use-merlin-highlight))

  ;; Quick setup for EMACS
  ;;  -------------------
  ;;  Add opam emacs directory to your load-path by appending this to your .emacs:
  ;;    (let ((opam-share (ignore-errors (car (process-lines "opam" "var" "share")))))
  ;;      (when (and opam-share (file-directory-p opam-share))
  ;;          ;; Register Merlin
  ;;          (add-to-list 'load-path (expand-file-name "emacs/site-lisp" opam-share))
  ;;          (autoload 'merlin-mode "merlin" nil t nil)
  ;;          ;; Automatically start it in OCaml buffers
  ;;          (add-hook 'tuareg-mode-hook 'merlin-mode t)
  ;;          (add-hook 'caml-mode-hook 'merlin-mode t)
  ;;          ;; Use opam switch to lookup ocamlmerlin binary
  ;;          (setq merlin-command 'opam)
  ;;          ;; To easily change opam switches within a given Emacs session, you can
  ;;          ;; install the minor mode https://github.com/ProofGeneral/opam-switch-mode
  ;;          ;; and use one of its "OPSW" menus.
  ;;      ))
  ;;  Take a look at https://github.com/ocaml/merlin for more information


(use-package merlin-eldoc
  :init (add-to-list 'package-selected-packages 'merlin-eldoc)
  ;; :bind (
  ;;   :map merlin-mode-map
  ;;     ("C-c m n" . merlin-eldoc-jump-to-next-occurrence)
  ;;     ("C-c m p" . merlin-eldoc-jump-to-prev-occurrence))
  :config
    (add-hook 'tuareg-mode-hook                 #'merlin-eldoc-setup)
    (add-hook 'tuareg-mode-hook                 #'merlin-eldoc-turn-on))

;; ocp-indent
(use-package ocp-indent
  :init (add-to-list 'package-selected-packages 'ocp-indent)
  :config
    (add-hook 'tuareg-mode-hook                 #'ocp-indent-setup)
    (add-hook 'caml-mode-hook                   #'ocp-indent-setup))

;; opam-switch-mode
(use-package opam-switch-mode
  :init (add-to-list 'package-selected-packages 'opam-switch-mode)
  :custom
    (opam-switch-mode-prompt t)
  :config
    (add-hook 'tuareg-mode-hook                 #'opam-switch-mode)
    (add-hook 'caml-mode-hook                   #'opam-switch-mode))

;; utop configuration
(use-package utop
  :init (add-to-list 'package-selected-packages 'utop)
  :custom
    (utop-command "opam exec -- dune utop . -- -emacs")
  :config
    (add-hook 'tuareg-mode-hook                 #'utop-minor-mode)
    (add-hook 'tuareg-mode-hook                 #'utop-setup-ocaml-buffer))

;; OCaml configuration
;;  - better error and backtrace matching
(use-feature emacs
  :config
    (defun +my/set-ocaml-error-regexp ()
      (set
        'compilation-error-regexp-alist
        (list
          '("[Ff]ile \\(\"\\(.*?\\)\", line \\(-?[0-9]+\\)\\(, characters \\(-?[0-9]+\\)-\\([0-9]+\\)\\)?\\)\\(:\n\\(\\(Warning .*?\\)\\|\\(Error\\)\\):\\)?"
            2 3 (5 . 6) (9 . 11) 1 (8 compilation-message-face)))))
    (add-hook 'tuareg-mode-hook                 #'+my/set-ocaml-error-regexp)
    (add-hook 'caml-mode-hook                   #'+my/set-ocaml-error-regexp))
;; ## added by OPAM user-setup for emacs / base ## 56ab50dc8996d2bb95e7856a6eddb17b ## you can edit, but keep this line
(require 'opam-user-setup)
;; ## end of OPAM user-setup addition for emacs / base ## keep this line
;;; }}} *** ocaml

;;; {{{ *** php
;;; {{{ **** php-mode
(use-package php-mode
  :init (add-to-list 'package-selected-packages 'php-mode)
  :mode (("\\.php\\'" . php-mode))
  :custom
    (php-mode-coding-style 'PSR-2)
  :config
    (add-hook 'php-mode-hook                    #'php-enable-psr2-coding-style))
;;; }}} **** php-mode
;;; }}} *** php

;;; {{{ *** rust
;; Reassign the rust-mode keybindings to the rust-ts-mode map.
(use-package rust-mode
  :after (rust-ts-mode)
  :init (add-to-list 'package-selected-packages 'rust-mode)
  ;; :bind (
  ;;   ;; Reassign the rust-mode keybindings to the rust-ts-mode map.
  ;;   :map rust-ts-mode-map
  ;;     ("C-c C-c C-k"  . #'rust-check)
  ;;     ("C-c C-c C-l"  . #'rust-run-clippy)
  ;;     ("C-c C-c C-r"  . #'rust-run)
  ;;     ("C-c C-c C-t"  . #'rust-test)
  ;;     ("C-c C-c C-u"  . #'rust-compile)
  ;;     ("C-c C-f"      . #'rust-format-buffer)
  ;;     ("C-c C-n"      . #'rust-goto-format-problem))
)
;;; }}} *** rust

;;; {{{ *** tempel
;; Configure Tempel
(use-package tempel
  :init (add-to-list 'package-selected-packages 'tempel)

    ;; Setup completion at point
    (defun +my/tempel-setup-capf ()
      ;; Add the Tempel Capf to `completion-at-point-functions'.
      ;; `tempel-expand' only triggers on exact matches. Alternatively use
      ;; `tempel-complete' if you want to see all matches, but then you
      ;; should also configure `tempel-trigger-prefix', such that Tempel
      ;; does not trigger too often when you don't expect it. NOTE: We add
      ;; `tempel-expand' *before* the main programming mode Capf, such
      ;; that it will be tried first.
      (setq-local completion-at-point-functions
                  (cons #'tempel-expand completion-at-point-functions)))
    (add-hook 'conf-mode-hook '+my/tempel-setup-capf)
    (add-hook 'prog-mode-hook '+my/tempel-setup-capf)
    (add-hook 'text-mode-hook '+my/tempel-setup-capf)

    ;; Optionally make the Tempel templates available to Abbrev,
    ;; either locally or globally. `expand-abbrev' is bound to C-x '.
    ;;(add-hook 'prog-mode-hook #'tempel-abbrev-mode)
    (global-tempel-abbrev-mode t)
  :custom
    (tempel-path (no-littering-expand-var-file-name "templates/*/*.eld")
      "A file or a list of template files.
        The file paths can contain wildcards, e.g.,
        \"~/.config/emacs/etc/templates/*/*.eld\", which matches all
        `lisp-data-mode' files in the subdirectories of the templates
        directory.")
    ;; Require trigger prefix before template name when completing.
    (tempel-trigger-prefix "<")
  ;; :bind (
  ;;   ("M-+"          . tempel-complete)      ;; Alternative tempel-expand
  ;;   ("M-*"          . tempel-insert))
  :config
    ;; Binding important templates to a key
    ;; Important templates can be bound to a key with the small utility macro tempel-key
    ;; which accepts three arguments, a key, a template or name and optionally a map.
    (tempel-key "C-c t d" (format-time-string "%Y-%m-%d"))
    (tempel-key "C-c t f" fun emacs-lisp-mode-map))

;; Optional: Add tempel-collection.
;; The package is young and doesn't have comprehensive coverage.
(use-package tempel-collection
  :after tempel
  :init (add-to-list 'package-selected-packages 'tempel-collection))
;;; }}} *** tempel

;;; {{{ *** treesit-auto
(use-package treesit-auto
  :init (add-to-list 'package-selected-packages 'treesit-auto)
  :custom
    (treesit-auto-enable-abbrevs t)
    (treesit-auto-enable-commenting t)
    (treesit-auto-enable-completion t)
    (treesit-auto-enable-debugging t)
    (treesit-auto-enable-folding t)
    (treesit-auto-enable-formatting t)
    (treesit-auto-enable-highlighting t)
    (treesit-auto-enable-ide t)
    (treesit-auto-enable-indentation t)
    (treesit-auto-enable-keybindings t)
    (treesit-auto-enable-linting t)
    (treesit-auto-enable-matchers t)
    (treesit-auto-enable-navigation t)
    (treesit-auto-enable-project t)
    (treesit-auto-enable-refactoring t)
    (treesit-auto-enable-snippets t)
    (treesit-auto-enable-templates t)
    (treesit-auto-enable-testing t)
    (treesit-auto-install 'prompt)
  :config
    (add-hook 'treesit-auto-mode-hook            #'treesit-auto-mode)

    (treesit-auto-add-to-auto-mode-alist 'all)
    (global-treesit-auto-mode t))
;;; }}} *** treesit-auto

;;; {{{ *** web-mode
(use-package web-mode
  :init (add-to-list 'package-selected-packages 'web-mode)
  :custom
    (web-mode-enable-auto-pairing t)
    (web-mode-enable-auto-closing t)
    (web-mode-enable-auto-indentation t)
    (web-mode-enable-auto-opening t)
    (web-mode-enable-auto-quoting t)
    (web-mode-enable-auto-expanding t)
    (web-mode-enable-current-element-highlight t)
    (web-mode-enable-current-column-highlight t)
    (web-mode-enable-css-colorization t)
    (web-mode-enable-block-face t)
    (web-mode-enable-part-face t)
    (web-mode-enable-comment-interpolation t)
    (web-mode-enable-heredoc-fontification t)
    (web-mode-enable-engine-detection t)
    (web-mode-enable-element-content-fontification t)
    (web-mode-enable-element-tag-fontification t)
    (web-mode-enable-html-entities-fontification t)
    (web-mode-enable-inlays t)
    (web-mode-enable-sql-detection t)
    (web-mode-enable-block-padding t)
    (web-mode-enable-part-padding t)
    (web-mode-enable-comment-annotation t)
  :mode (
    ("\\.blade.php\\'"  . web-mode)
    ("\\.ctp\\'"        . web-mode)
    ("\\.eex\\'"        . web-mode)
    ("\\.ejs\\'"        . web-mode)
    ("\\.erb\\'"        . web-mode)
    ("\\.handlebars\\'" . web-mode)
    ("\\.hbs\\'"        . web-mode)
    ("\\.html?\\'"      . web-mode)
    ("\\.jinja2\\'"     . web-mode)
    ("\\.jsx?\\'"       . web-mode)
    ("\\.leex\\'"       . web-mode)
    ("\\.liquid\\'"     . web-mode)
    ("\\.mustache\\'"   . web-mode)
    ("\\.njk\\'"        . web-mode)
    ("\\.php\\'"        . web-mode)
    ("\\.phtml\\'"      . web-mode)
    ("\\.svelte\\'"     . web-mode)
    ("\\.tmpl\\'"       . web-mode)
    ("\\.tpl.php\\'"    . web-mode)
    ("\\.tpl\\'"        . web-mode)
    ("\\.tsx?\\'"       . web-mode)
    ("\\.twig\\'"       . web-mode)
    ("\\.vue\\'"        . web-mode)))
;;; }}} *** web-mode
;;; }}} ** ide

;;; {{{ ** emojify
(use-package emojify
  :init (add-to-list 'package-selected-packages 'emojify)
  :config
    (add-hook 'after-init-hook                  'global-emojify-mode))
;;; }}} ** emojify

;;; {{{ ** flycheck-lilypond
(use-package flycheck-lilypond
  :after (flycheck lilypond)
  :init (add-to-list 'package-selected-packages 'flycheck-lilypond))
;;; }}} ** flycheck-lilypond

;;; {{{ ** hl-todo
(use-package hl-todo
  :ensure (:depth nil)
  :after (consult)
  :init (add-to-list 'package-selected-packages 'hl-todo)
  :custom
    (hl-todo-keyword-faces
      '(("TODO"   . "#FF0000")
        ("DEBUG"  . "#A020F0")
        ("FIXME"  . "#FF0000")
        ("GOTCHA" . "#FF4500")
        ("STUB"   . "#1E90FF")))
  ;; :bind (
  ;;   :map hl-todo-mode-map
  ;;     ("C-c i"    . #'hl-todo-insert)
  ;;     ("C-c n"    . #'hl-todo-next)
  ;;     ("C-c o"    . #'hl-todo-occur)
  ;;     ("C-c p"    . #'hl-todo-previous))
)

(use-package consult-todo
  :after (consult hl-todo)
  :init (add-to-list 'package-selected-packages 'consult-todo))

(use-package flycheck-hl-todo
  :after (flycheck hl-todo)
  :init (add-to-list 'package-selected-packages 'flycheck-hl-todo))
;;; }}} ** hl-todo

;;; {{{ ** hyperbole
(use-package hyperbole
  :init (add-to-list 'package-selected-packages 'hyperbole)
  :config
    (hyperbole-mode t))
;;; }}} ** hyperbole

;;; {{{ ** org-mode
;;; {{{ *** ascii-art-to-unicode
(use-package ascii-art-to-unicode
    ;;; ascii-art-to-unicode
    ;; Converts simple ASCII art line drawings in the region of the current buffer to Unicode.
    ;; ascii-art-to-unicode is useful if you want org-brain-visualize-mode to look a bit nicer. After installing, add the following to your init-file:
  :init (add-to-list 'package-selected-packages 'ascii-art-to-unicode)
  :config
    (defface aa2u-face '((t . nil))
      "Face for aa2u box drawing characters")
    (advice-add #'aa2u-1c :filter-return
                (lambda (str) (propertize str 'face 'aa2u-face)))

    (defun +my/aa2u-org-brain-buffer ()
      (let ((inhibit-read-only t))
        (make-local-variable 'face-remapping-alist)
        (add-to-list 'face-remapping-alist
                     '(aa2u-face . org-brain-wires))
        (ignore-errors (aa2u (point-min) (point-max)))))
    (with-eval-after-load 'org-brain
      (add-hook 'org-brain-after-visualize-hook #'+my/aa2u-org-brain-buffer)))
;;; }}} *** ascii-art-to-unicode

;;; {{{ *** auto-tangle-mode
(use-package auto-tangle-mode
  :ensure (auto-tangle-mode
            :host github
            :repo "progfolio/auto-tangle-mode.el"
            :local-repo "auto-tangle-mode")
  :after (org)
  :init (add-to-list 'package-selected-packages 'auto-tangle-mode)
  :commands (auto-tangle-mode)
  :config
    (add-to-list 'package-selected-packages 'auto-tangle-mode)
    (auto-tangle-mode t))
;;; }}} *** auto-tangle-mode

;;; {{{ *** doct
(use-package doct
  :after (org)
  :init (add-to-list 'package-selected-packages 'doct)
  :commands (doct))
;;; }}} *** doct

;;; {{{ *** dslide
(use-package dslide
  :ensure (dslide
            :host github
            :repo "positron-solutions/dslide")
  :init (add-to-list 'package-selected-packages 'dslide)
  :commands (dslide))
;;; }}} *** dslide

;;; {{{ *** el2org
(use-package el2org
  :after (org)
  :init (add-to-list 'package-selected-packages 'el2org))
;;; }}} *** el2org

;;; {{{ *** holy-books
(use-package holy-books
  :after (org)
  :init (add-to-list 'package-selected-packages 'holy-books)
  :custom
    (holy-books-quran-translation "19" "The translation code of the Quran; a string.

Possible codes include

Code  Translation
--------------------
131   Dr.  Mustafa Khattab, the Clear Quran (Default)
20    Sahih International
85    Abdul Haleem
19    Picktall
22    Yusuf Ali
95    Abul Ala Maududi
167   Maarif-ul-Quran
57    Transliteration

A longer list of translations can be found here:
https://api.quran.com/api/v3/options/translations")

    (holy-books-bible-version "kjv" "The version code of the Holy Bible; a symbol or string.

Possible version codes include:

Code   Version
---------------------------------------
niv    New International Version, DEFAULT
asv    American Standard Version
bbe    Bible in Basic English
drb    Darby's Translation
esv    English Standard Version
kjv    King James Version
nas    New American Standard
nkjv   New King James Version
nlt    New Living Translation
nrs    New Revised Standard Version
rsv    Revised Standard Version
msg    The Message Bible
web    World English Bible
ylt    Young's Literal"))
;;; }}} *** holy-books

;;; {{{ *** link-hint
(use-package link-hint
  :init (add-to-list 'package-selected-packages 'link-hint)
  ;; :bind (
  ;;   ("C-c l c"      . link-hint-copy-link)
  ;;   ("C-c l o"      . link-hint-open-link))
  :config
    (with-eval-after-load 'evil
      (define-key evil-normal-state-map (kbd "SPC f") 'link-hint-open-link)))
;;; }}} *** link-hint

;;; {{{ *** master-of-ceremonies
(use-package master-of-ceremonies
  :ensure (master-of-ceremonies
            :host github
            :repo "positron-solutions/master-of-ceremonies")
  :init (add-to-list 'package-selected-packages 'master-of-ceremonies)
  :commands (master-of-ceremonies))
;;; }}} *** master-of-ceremonies

;;; {{{ *** org
(use-package org
  :ensure (:autoloads "org-loaddefs.el")
  :init (add-to-list 'package-selected-packages 'org)
  :custom
    (org-M-RET-may-split-line nil "Don't split current line when creating new heading")
    (org-default-notes-file
      (concat (file-name-as-directory ews-home-directory)
              "nc/org/ews/inbox.org"))
    (org-ellipsis (nth 5 '("↴" "˅" "…" " ⬙" " ▽" "▿")))
    (org-export-date-timestamp-format "%e %B %Y")
    (org-export-with-broken-links t)
    (org-export-with-drawers t)
    (org-export-with-smart-quotes t)
    (org-export-with-toc t)
    (org-export-with-todo-keywords t)
    (org-fold-catch-invisible-edits 'error)
    (org-fontify-done-headline t)
    ;; Hide markup markers
    (org-hide-emphasis-markers t)
    (org-image-actual-width '(800))
    ;; Display links as the description provided
    (org-link-descriptive t)
    (org-modules '(ol-bbdb ol-bibtex ol-docview ol-eww ol-gnus org-habit ol-info ol-irc ol-mhe ol-rmail ol-w3m))
    ;; Return or left-click with mouse follows link
    (org-mouse-1-follows-link t)
    (org-return-follows-link t)
    (org-pretty-entities t)
    (org-priority-lowest ?D)
    (org-startup-indented t)
    (org-startup-with-inline-images t)
    (org-startup-with-latex-preview t)
    ;;move to theme?
    (org-todo-keyword-faces
      `(("CANCELED" . (:foreground "IndianRed1" :weight bold))
        ("TODO" . (:foreground "#ffddaa"
                    :weight bold
                    :background "#202020"
                    :box (:line-width 3 :width -2 :style released-button)))))
    (org-todo-keywords
      '((sequence  "TODO(t)" "STARTED(s!)" "NEXT(n!)" "BLOCKED(b@/!)" "|" "DONE(d)")
        (sequence  "IDEA(i)" "|" "CANCELED(c@/!)" "DELEGATED(D@/!)")
        (sequence  "RESEARCH(r)" "|")))
    (org-use-sub-superscripts "{}")
    (sentence-end-double-space nil)
  ;; :bind (
  ;;   ;; for EWS
  ;;   :map org-mode-map
  ;;     ("C-c w c"  . ews-org-count-words)
  ;;     ("C-c w n"  . ews-org-insert-notes-drawer)
  ;;     ("C-c w p"  . ews-org-insert-screenshot))
  :config
    (defun +my/org-sparse-tree (&optional arg type)
      (interactive)
      (funcall #'org-sparse-tree arg type)
      (org-remove-occur-highlights))

    (defun +my/insert-heading-advice (&rest _args)
      "Enter insert mode after org-insert-heading. Useful so I can tab to control level of inserted heading."
      (when evil-mode (evil-insert t)))

    (advice-add #'org-insert-heading :after #'+my/insert-heading-advice)

    (defun +my/org-update-cookies ()
      (interactive)
      (org-update-statistics-cookies "ALL"))

    ;; Offered a patch to fix this upstream. Too much bikeshedding for such a simple fix.
    (defun +my/org-tags-crm (fn &rest args)
      "Workaround for bug which excludes \",\" when reading tags via `completing-read-multiple'.\n I offered a patch to fix this, but it was met with too much resistance to be worth pursuing."
      (let ((crm-separator "\\(?:[[:space:]]*[,:][[:space:]]*\\)"))
        (unwind-protect (apply fn args)
          (advice-remove #'completing-read-multiple #'+my/org-tags-crm))))

    (define-advice org-set-tags-command (:around (fn &rest args) comma-for-crm)
      (advice-add #'completing-read-multiple :around #'+my/org-tags-crm)
      (apply fn args))

    ;; Disable auto-pairing of "<" in org-mode with electric-pair-mode
    (defun +my/org-enhance-electric-pair-inhibit-predicate ()
      "Disable auto-pairing of \"<\" in `org-mode' when using `electric-pair-mode'."
      (when (and electric-pair-mode (eql major-mode #'org-mode))
          (setq-local
            electric-pair-inhibit-predicate
            `(lambda (c)
              (if (char-equal c ?<)
                  t
                (,electric-pair-inhibit-predicate c))))))
    ;; Add hook to both electric-pair-mode-hook and org-mode-hook
    ;; This ensures org-mode buffers don't behave weirdly,
    ;; no matter when electric-pair-mode is activated.
    (add-hook 'electric-pair-mode-hook  #'+my/org-enhance-electric-pair-inhibit-predicate)
    (add-hook 'org-mode-hook            #'+my/org-enhance-electric-pair-inhibit-predicate)

    ;; Visually indent org-mode files to a given header level
    (add-hook 'org-mode-hook            #'org-indent-mode)
)
;;; }}} *** org

;;; {{{ *** org-appear
;; Toggle the visibility of some Org elements.
(use-package org-appear
  :after (org)
  :init (add-to-list 'package-selected-packages 'org-appear)
  :config
    (add-hook 'org-mode-hook            'org-appear-mode))
;;; }}} *** org-appear

;;; {{{ *** org-attach-screenshot
(use-package org-attach-screenshot
  :after (org)
  :init (add-to-list 'package-selected-packages 'org-attach-screenshot)
  :custom
    (org-attach-screenshot-dirfunction
          (lambda ()
        (progn
          (assert (buffer-file-name))
          (concat (file-name-sans-extension (buffer-file-name))
                                 "_att")))))
;;; }}} *** org-attach-screenshot

;;; {{{ *** org-auto-expand
(use-package org-auto-expand
  :after (org)
  :init (add-to-list 'package-selected-packages 'org-auto-expand)
  :config
    (org-auto-expand-mode t))
;;; }}} *** org-auto-expand

;;; {{{ *** org-auto-tangle
(use-package org-auto-tangle
  :after (org)
  :init (add-to-list 'package-selected-packages 'org-auto-tangle)
  :custom
    ;; Babel Auto Tangle Safelist
    ;; Add a list of files to the safelist to autotangle with noweb evaluation
    (org-auto-tangle-babel-safelist '("~/system.org"
                                      "~/test.org"))
  :hook (
    (org-mode-hook  . org-auto-tangle-mode)))
;;; }}} *** org-auto-tangle

;;; {{{ *** org-babel
(use-package ob-async
  :after (org)
  :init (add-to-list 'package-selected-packages 'ob-async))

(use-package ob-blockdiag
  :after (org)
  :init (add-to-list 'package-selected-packages 'ob-blockdiag)
  :config
    (org-babel-do-load-languages 'org-babel-load-languages
                                    (append org-babel-load-languages
                                      '((blockdiag  . t)))))

(use-package ob-compile
  :after (org)
  :init (add-to-list 'package-selected-packages 'ob-compile))

(use-package ob-dart
  :after (org)
  :init (add-to-list 'package-selected-packages 'ob-dart)
  :config
    ;; For Dart to appear as one of the values of
    ;;   customize-variable org-babel-load-languages, add this code:
    (org-babel-do-load-languages 'org-babel-load-languages
                                    (append org-babel-load-languages
                                      '((dart       . t)))))

(use-package ob-diagrams
  :after (org)
  :init (add-to-list 'package-selected-packages 'ob-diagrams))

(use-package ob-elixir
  :after (org)
  :init (add-to-list 'package-selected-packages 'ob-elixir)
  :config
    (org-babel-do-load-languages 'org-babel-load-languages
                                    (append org-babel-load-languages
                                      '((elixir     . t)))))

(use-package ob-elm
  :after (org)
  :init (add-to-list 'package-selected-packages 'ob-elm)
  :config
    (org-babel-do-load-languages 'org-babel-load-languages
                                    (append org-babel-load-languages
                                      '((elm        . t)))))

(use-package ob-elvish
  :after (org)
  :init (add-to-list 'package-selected-packages 'ob-elvish)
  :config
    (org-babel-do-load-languages 'org-babel-load-languages
                                    (append org-babel-load-languages
                                      '((elvish     . t)))))

;; Load ob-ess-julia and dependencies
(use-package ob-ess-julia
  :after (org)
  :init (add-to-list 'package-selected-packages 'ob-ess-julia)
  :custom
    ;; Link this language to ess-julia-mode (although it should be done by default):
    (org-src-lang-modes (append org-src-lang-modes '(("ess-julia" . ess-julia))))
  :config
    ;; Add ess-julia into supported languages:
    (org-babel-do-load-languages 'org-babel-load-languages
                                    (append org-babel-load-languages
                                      '((ess-julia . t))))
    ;; Demo
    ;; Some examples of implemented features can be found in the file examples-ob-ess-julia.org.

    ;; Notes and tips
    ;; :session names should be prefixed an suffixed by *, e.g. *julia* or *mysession* are convenient names.
    ;; The following Julia packages are required: CSV, DelimitedFiles, Pipe. They are used for the :result value output type. They are loaded (with using) at the beginning of each Julia session started with ob-ess-julia (which is inelegant; but I couldn’t find a better option).
    ;; I suggest the following settings for the Emacs initialisation file:
    ;; Shortcuts for Julia code block headers.
    ;; Shortcut for "normal" session evaluation with verbatim output:
    (add-to-list 'org-structure-template-alist
                   '("j" . "src ess-julia :results output :session *julia* :exports both"))
    ;; Shortcut for inline graphical output within a session:
    (add-to-list 'org-structure-template-alist
                   '("jfig" . "src ess-julia :results output graphics file :file FILENAME.png :session *julia* :exports both"))
    ;; Shortcut for well-formatted org table output within a session:
    (add-to-list 'org-structure-template-alist
                   '("jtab" . "src ess-julia :results value table :session *julia* :exports both :colnames yes"))
)

(use-package ob-fsharp
  :after (org)
  :init (add-to-list 'package-selected-packages 'ob-fsharp)
  :config
    (org-babel-do-load-languages 'org-babel-load-languages
                                    (append org-babel-load-languages
                                      '((fsharp     . t)))))

(use-package ob-go
  :after (org)
  :init (add-to-list 'package-selected-packages 'ob-go)
  :config
    (org-babel-do-load-languages 'org-babel-load-languages
                                    (append org-babel-load-languages
                                      '((go         . t)))))

(use-package ob-http
  :after (org)
  :init (add-to-list 'package-selected-packages 'ob-http)
  :config
    (org-babel-do-load-languages 'org-babel-load-languages
                                    (append org-babel-load-languages
                                      '((http       . t)))))

(use-package ob-nix
  :after (org)
  :init (add-to-list 'package-selected-packages 'ob-nix)
  :config
    (org-babel-do-load-languages 'org-babel-load-languages
                                    (append org-babel-load-languages
                                      '((nix        . t)))))

(use-package ob-php
  :after (org)
  :init (add-to-list 'package-selected-packages 'ob-php)
  :config
    (org-babel-do-load-languages 'org-babel-load-languages
                                    (append org-babel-load-languages
                                      '((php        . t)))))

(use-package ob-powershell
  :after (org)
  :init (add-to-list 'package-selected-packages 'ob-powershell)
  :config
    (org-babel-do-load-languages 'org-babel-load-languages
                                    (append org-babel-load-languages
                                      '((powershell . t)))))

(use-package ob-prolog
  :after (org)
  :init (add-to-list 'package-selected-packages 'ob-prolog)
  :config
    (org-babel-do-load-languages 'org-babel-load-languages
                                    (append org-babel-load-languages
                                      '((prolog     . t)))))

(use-package ob-raku
  :after (org)
  :init (add-to-list 'package-selected-packages 'ob-raku)
  :config
    (org-babel-do-load-languages 'org-babel-load-languages
                                    (append org-babel-load-languages
                                      '((raku       . t)))))

(use-package ob-restclient
  :after (org)
  :init (add-to-list 'package-selected-packages 'ob-restclient)
  :config
    (org-babel-do-load-languages 'org-babel-load-languages
                                    (append org-babel-load-languages
                                      '((restclient . t)))))

(use-package ob-rust
  :after (org)
  :init (add-to-list 'package-selected-packages 'ob-rust)
  :config
    (org-babel-do-load-languages 'org-babel-load-languages
                                    (append org-babel-load-languages
                                      '((rust       . t)))))

(use-package ob-typescript
  :after (org)
  :init (add-to-list 'package-selected-packages 'ob-typescript)
  :custom
    (org-babel-command:typescript "npx -p typescript -- tsc")
  :config
    (org-babel-do-load-languages 'org-babel-load-languages
                                    (append org-babel-load-languages
                                      '((typescript . t)))))

;;; {{{ **** org-babel-eval-in-repl
(use-package org-babel-eval-in-repl
  :after (ob)
  :init (add-to-list 'package-selected-packages 'org-babel-eval-in-repl)
  :custom
    (eir-jump-after-eval nil)
  ;; :bind (
  ;;   :map org-mode-map
  ;;     ("C-<return>" . 'ober-eval-in-repl)
  ;;     ("M-<return>" . 'ober-eval-block-in-repl))
)
;;; }}} **** org-babel-eval-in-repl
;;; }}} *** org-babel

;;; {{{ *** org-board
(use-package org-board
  :after (org)
  :init (add-to-list 'package-selected-packages 'org-board)
  :config
    (global-set-key (kbd "C-c o b") org-board-keymap))
;;; }}} *** org-board

;;; {{{ *** org-bookmark-heading
(use-package org-bookmark-heading
  :after (org)
  :init (add-to-list 'package-selected-packages 'org-boookmark-heading)
  :custom
    (org-bookmark-jump-indirect t "Make Org bookmarks always open in indirect buffers."))
;;; }}} *** org-bookmark-heading

;;; {{{ *** org-brain
(use-package org-brain
  :after (org)
  :init (add-to-list 'package-selected-packages 'org-brain)
    ;; For Evil users
    (with-eval-after-load 'evil
      (evil-set-initial-state 'org-brain-visualize-mode 'emacs))
  :custom
    (org-brain-file-entries-use-title t)
    (org-brain-include-file-entries t)
    (org-brain-path "~/nc/org/brain")
    (org-brain-title-max-length 12)
    (org-brain-visualize-default-choices 'all)
    (org-id-locations-file (no-littering-expand-etc-file-name "org/.org-id-locations") "no-littering `org-id-locations-file'")
    (org-id-track-globally t)
  ;; :hook (
  ;;   (before-save-hook   . #'org-brain-ensure-ids-in-buffer))
  :config
    (bind-key "C-c b" 'org-brain-prefix-map org-mode-map)
    (push
      '("b" "Brain"
        plain (function org-brain-goto-end)
        "* %i%?" :empty-lines 1)
      org-capture-templates)

    ;;; Chronological entries with org-expiry
    ;; org-brain doesn’t add any information on when entries are created, so it is hard get a list of your entries in chronological order. I’ve managed to use org-expiry (part of org-plus-contrib) to add a CREATED property to all org-brain headline entries. Then we can use org-agenda to show the entries in chronological order.
    ;; Setup org-expiry and define a org-agenda function to compare timestamps
    (require 'org-expiry)
    (customize-set-variable 'org-expiry-inactive-timestamps t)
    (defun +my/org-expiry-created-comp (a b)
      "Compare `org-expiry-created-property-name' properties of A and B."
      (let ((ta (ignore-errors
                  (org-time-string-to-seconds
                    (org-entry-get (get-text-property 0 'org-marker a)
                                    org-expiry-created-property-name))))
            (tb (ignore-errors
                  (org-time-string-to-seconds
                    (org-entry-get (get-text-property 0 'org-marker b)
                                    org-expiry-created-property-name)))))
        (cond ((if ta (and tb (< ta tb)) tb) -1)
              ((if tb (and ta (< tb ta)) ta) +1))))

    ;; Add CREATED property when adding a new org-brain headline entry
    (add-hook 'org-brain-new-entry-hook #'+my/org-expiry-insert-created)

    ;; Finally add a function which lets us watch the entries chronologically
    ;; Now we can use `org-brain-timeline' to view entries in chronological order (newest first).
    (defun +my/org-brain-timeline ()
      "List all org-brain headlines in chronological order."
      (interactive)
      (let ((org-agenda-files (org-brain-files))
            (org-agenda-cmp-user-defined #'+my/org-expiry-created-comp)
            (org-agenda-sorting-strategy '(user-defined-down)))
        (org-tags-view nil (format "+%s>\"\"" org-expiry-created-property-name))))

    ;;; org-cliplink
    ;; A simple command that takes a URL from the clipboard and inserts an org-mode link with a title of a page found by the URL into the current buffer.
    ;; Here’s a command which uses org-cliplink to add a link from the clipboard as an org-brain resource. It guesses the description from the URL title. Here I’ve bound it to L in org-brain-visualize.
    (defun +my/org-brain-cliplink-resource ()
      "Add a URL from the clipboard as an org-brain resource.\n Suggest the URL title as a description for resource."
      (interactive)
      (let ((url (org-cliplink-clipboard-content)))
        (org-brain-add-resource
          url
          (org-cliplink-retrieve-title-synchronously url)
          t)))
    (define-key org-brain-visualize-mode-map (kbd "L") #'+my/org-brain-cliplink-resource)

    ;;; link-hint
    ;; link-hint.el is inspired by the link hinting functionality in vim-like browsers and browser plugins such as pentadactyl. It provides commands for using avy to open or copy “links.”
    ;; After installing link-hint you could bind link-hint-open-link to a key, and use it in org-brain-visualize-mode. If you only want to use link-hint in org-brain-visualize-mode, you could add the following to your init-file:
    ;; (define-key org-brain-visualize-mode-map (kbd "C-l") #'link-hint-open-link)

    ;;; all-the-icons
    ;; A utility package to collect various Icon Fonts and propertize them within Emacs.
    ;; After installing all-the-icons you could decorate the resources in org-brain, by using org-brain-after-resource-button-functions. Here’s a small example:
    (defun +my/org-brain-insert-resource-icon (link)
      "Insert an icon, based on content of org-mode LINK."
      (insert
        (format "%s "
                (cond
                  ((string-prefix-p "brain:" link)
                    (all-the-icons-fileicon "brain"))
                  ((string-prefix-p "info:" link)
                    (all-the-icons-octicon "info"))
                  ((string-prefix-p "help:" link)
                    (all-the-icons-material "help"))
                  ((string-prefix-p "http" link)
                    (all-the-icons-icon-for-url link))
                  (t
                    (all-the-icons-icon-for-file link))))))
    (add-hook 'org-brain-after-resource-button-functions #'+my/org-brain-insert-resource-icon)
    ;; You could also use all-the-icons to add icons to entry categories. For instance if you have two categories named computers and books which you want icons for:
    (customize-set-variable 'org-agenda-category-icon-alist
                            `(("computers" ,(list (all-the-icons-material "computer")) nil nil :ascent center)
                              ("books" ,(list (all-the-icons-faicon "book")) nil nil :ascent center)))
)
;;; }}} *** org-brain

;;; {{{ *** org-bullets
(use-package org-bullets
  :after (org)
  :init (add-to-list 'package-selected-packages 'org-bullets)
  :config
    (add-hook 'org-mode-hook        #'org-bullets-mode))
;;; }}} *** org-bullets

;;; {{{ *** org-cite-overlay
(use-package org-cite-overlay
  :after (org)
  :init (add-to-list 'package-selected-packages 'org-cite-overlay)
  :custom
    (universal-sidecar-citeproc-locales "~/nc/org/csl-data/locales/")
    ;; set to your directories for locale and style data
    (universal-sidecar-citeproc-styles "~/nc/org/csl-data/styles/")
  :hook (
    (org-mode-hook  . org-cite-overlay-mode))
  :config
    (add-to-list 'universal-sidecar-sections 'org-cite-overlay-sidecar))
;;; }}} *** org-cite-overlay

;; ;;; {{{ *** org-clean-refile
;; (use-package org-clean-refile
;;   :ensure (org-clean-refile :host github :repo "progfolio/org-clean-refile")
;;   :after (org)
;;   :init
;;     (add-to-list 'package-selected-packages 'org-clean-refile)
;;   :commands (org-clean-refile)
;;   :config
;;     (add-to-list 'package-selected-packages 'org-clean-refile))
;; ;;; }}} *** org-clean-refile

;;; {{{ *** org-cliplink
(use-package org-cliplink
  :after (org)
  :init (add-to-list 'package-selected-packages 'org-cliplink)
  ;; :bind (
  ;;   ("C-x p i"      . 'org-cliplink))
)
;;; }}} *** org-cliplink

;;; {{{ *** org-download
(use-package org-download
  :after (org)
  :init (add-to-list 'package-selected-packages 'org-download)
    (setq-default org-download-image-dir "~/nc/org/pictures")
  :config
    ;; Drag-and-drop to `dired`
    (add-hook 'dired-mode-hook      #'org-download-enable))
;;; }}} *** org-download

;;; {{{ *** org-edna
(use-package org-edna
  :after (org)
  :init (add-to-list 'package-selected-packages 'org-edna)
  :config
    (org-edna-mode t))
;;; }}} *** org-ewdna

;;; {{{ *** org-fancy-priorities
(use-package org-fancy-priorities
  :after (org)
  :init (add-to-list 'package-selected-packages 'org-fancy-priorities)
  :commands (org-fancy-priorities-mode)
  :config
    (add-hook 'org-mode-hook        #'org-fancy-priorities-mode)
    ;;"Eisenhower Matrix of Importance and Urgency"
    (defvar +org-fancy-priorities-eisenhower-matrix
      "↑ |-----------+-----------|
I |   Eisenhower Matrix   |
M |-----------+-----------|
P |           |           |
O | Schedule  | Immediate |
R |           |           |
T |-----------+-----------|
A |           |           |
N | Eliminate | Delegate  |
C |           |           |
E |-----------+-----------|
        URGENCY →"
      "Eisenhower Matrix help text.")
  (customize-set-variable 'org-fancy-priorities-list
    (mapcar
      (lambda (cell)
        (format (car cell)
                (propertize
                  (cdr cell)
                  'help-echo +org-fancy-priorities-eisenhower-matrix)))
      '(("I∧U (%s)"     . "I")
        ("I¬U (%s)"     . "S")
        ("¬IU (%s)"     . "D")
        ("¬I¬U (%s)"    . "E")))))
;;; }}} *** org-fancy-priorities

;;; {{{ *** org-habit-stats
(use-package org-habit-stats
  :after (org org-habit)
  :init (add-to-list 'package-selected-packages 'org-habit-stats)
  ;; :bind (
  ;;   :map org-agenda-mode-map
  ;;     ("H"          . 'org-habit-stats-view-habit-at-point-agenda)
  ;;   :map org-mode-map
  ;;     ("C-c h"      . 'org-habit-stats-view-habit-at-point))
  :config
    (add-hook 'org-after-todo-state-change-Hook     #'org-habit-stats-update-properties))
;;; }}} *** org-habit-stats

;;; {{{ *** org-inline-anim
(use-package org-inline-anim
  :after (org)
  :init (add-to-list 'package-selected-packages 'org-inline-anim)
  :config
    (add-hook 'org-mode-hook        #'org-inline-anim-mode))
;;; }}} *** org-inline-anim

;;; {{{ *** org-link-beautify
(use-package org-link-beautify
  :after (org)
  :init (add-to-list 'package-selected-packages 'org-link-beautify)
  :custom
    (org-link-beautify-async-preview t)
    (org-element-use-cache t)
  :config
    (org-link-beautify-mode t))
;;; }}} *** org-link-beautify

;;; {{{ *** org-make-toc
(use-package org-make-toc
  :after (org)
  :init (add-to-list 'package-selected-packages 'org-make-toc)
  :commands (org-make-toc)
  :config
    (add-hook 'org-mode-hook        #'org-make-toc-mode))
;;; }}} *** org-make-toc

;;; {{{ *** org-mime
(use-package org-mime
  :after (org)
  :init (add-to-list 'package-selected-packages 'org-mime)
  :custom
    (org-mime-export-options '(:section-numbers nil
                                :with-author nil
                                :with-latex dvipng
                                :with-toc nil))
  :commands
    (org-mime-htmlize
      org-mime-org-buffer-htmlize
      org-mime-org-subtree-htmlize))
;;; }}} *** org-mime

;;; {{{ *** org-ml
(use-package org-ml
  :after (org)
  :init (add-to-list 'package-selected-packages 'org-ml))
;;; }}} *** org-ml

;;; {{{ *** org-modern
(use-package org-modern
  :after (org)
  :init (add-to-list 'package-selected-packages 'org-modern)
  :custom
    (org-modern-block-name nil)
    (org-modern-checkbox nil)
    (org-modern-footnote nil)
    (org-modern-internal-target nil)
    (org-modern-keyword nil)
    (org-modern-keyword nil)
    (org-modern-priority nil)
    (org-modern-progress nil)
    (org-modern-radio-target nil)
    (org-modern-statistics nil)
    (org-modern-table nil)
    (org-modern-tag nil)
    (org-modern-timestamp nil)
  :config
    (add-hook 'org-mode-hook        #'org-modern-mode)
    (global-org-modern-mode t)
    (remove-hook 'org-agenda-finalize-hook 'org-modern-agenda))
;;; }}} *** org-modern

;;; {{{ *** org-newtab
(use-package org-newtab
  :after (org)
  :init (add-to-list 'package-selected-packages 'org-newtab)
  :config
    (org-newtab-mode t))
;;; }}} *** org-newtab

;;; {{{ *** org-noter
(use-package org-noter
  :after (org)
  :init (add-to-list 'package-selected-packages 'org-noter)
  :custom
    (org-noter-arrow-background-color   "cyan")
    (org-noter-arrow-foreground-color   "black")
    (org-noter-default-notes-file-names '("notes.org"))
    (org-noter-notes-search-path        '("~/nc/org/notes"))
  :config
    ;; Your org-noter config ........
    ;; Include this only next block only if you use ~evil~ with ~general~
    (require 'org-noter-pdftools))

(use-package org-noter-pdftools
  :after (org org-noter org-pdftools)
  :init (add-to-list 'package-selected-packages 'org-noter-pdftools)
  :config
    ;; Add a function to ensure precise note is inserted
    (defun +my/org-noter-pdftools-insert-precise-note (&optional toggle-no-questions)
      (interactive "P")
      (org-noter--with-valid-session
        (let ((org-noter-insert-note-no-questions
                (if toggle-no-questions
                    (not org-noter-insert-note-no-questions)
                  org-noter-insert-note-no-questions))
              (org-pdftools-use-freepointer-annot t)
              (org-pdftools-use-isearch-link t))
          (org-noter-insert-note (org-noter--get-precise-info)))))

    ;; fix https://github.com/weirdNox/org-noter/pull/93/commits/f8349ae7575e599f375de1be6be2d0d5de4e6cbf
    (defun +my/org-noter-set-start-location (&optional arg)
      "When opening a session with this document, go to the current location.\n With a prefix ARG, remove start location."
      (interactive "P")
      (org-noter--with-valid-session
        (let ((inhibit-read-only t)
               (ast (org-noter--parse-root))
               (location (org-noter--doc-approx-location (when (called-interactively-p 'any) 'interactive))))
          (with-current-buffer (org-noter--session-notes-buffer session)
            (org-with-wide-buffer
              (goto-char (org-element-property :begin ast))
              (if arg
                  (org-entry-delete nil org-noter-property-note-location)
                (org-entry-put nil org-noter-property-note-location
                               (org-noter--pretty-print-location location))))))))
    (with-eval-after-load 'pdf-annot
      (add-hook 'pdf-annot-activate-handler-functions #'org-noter-pdftools-jump-to-note)))
;;; }}} *** org-noter

;;; {{{ *** org-onenote
(use-package org-onenote
  :after (org)
  :init (add-to-list 'package-selected-packages 'org-onenote))
;;; }}} *** org-onenote

;;; {{{ *** org-outline-numbering
(use-package org-outline-numbering
  :after (org)
  :init (add-to-list 'package-selected-packages 'org-outline-numbering)
  :config
    (org-outline-numbering-mode t))
;;; }}} *** org-outline-numbering

;;; {{{ *** org-pdftools
(use-package org-pdftools
  :after (org)
  :init (add-to-list 'package-selected-packages 'org-pdftools)
  :config
    (add-hook 'org-mode-hook        #'org-pdftools-setup-link))
;;; }}} *** org-pdftools

;;; {{{ *** org-present
(use-package org-present
  :after (org)
  :init (add-to-list 'package-selected-packages 'org-present)
  :config
    '(progn
       (add-hook 'org-present-mode-hook
                 (lambda ()
                   (org-present-big)
                   (org-display-inline-images)
                   (org-present-hide-cursor)
                   (org-present-read-only)))
       (add-hook 'org-present-mode-quit-hook
                 (lambda ()
                   (org-present-small)
                   (org-remove-inline-images)
                   (org-present-show-cursor)
                   (org-present-read-write)))))
;;; }}} *** org-present

;;; {{{ *** org-pretty-tags
(use-package org-pretty-tags
  :after (org)
  :init (add-to-list 'package-selected-packages 'org-pretty-tags))
;;; }}} *** org-pretty-tags

;;; {{{ *** org-project-capture
(use-package org-project-capture
  :after (org)
  :init (add-to-list 'package-selected-packages 'org-project-capture)
  :custom
    (org-project-capture-backend (make-instance 'org-project-capture-project-backend))
    (org-project-capture-projects-file "~/nc/org/projects.org")
    (org-project-capture-strategy
      (make-instance 'org-project-capture-combine-strategies
        :strategies (list (make-instance 'org-project-capture-single-file-strategy)
                          (make-instance 'org-project-capture-per-project-strategy))))
  ;; :bind (
  ;;   ("C-c n p"      . org-project-capture-project-todo-completing-read))
  :config
    (org-project-capture-single-file))
;;; }}} *** org-project-capture

;;; {{{ *** org-ql
(use-package org-ql
  :after (org)
  :init (add-to-list 'package-selected-packages 'org-ql))
;;; }}} *** org-ql

;;; {{{ *** org-rainbow-tags
(use-package org-rainbow-tags
  :after (org)
  :init (add-to-list 'package-selected-packages 'org-rainbow-tags)
  :custom
    (org-rainbow-tags-extra-face-attributes '(:inverse-video t :box t :weight 'bold))   ;; Default is '(:weight 'bold)
    (org-rainbow-tags-hash-start-index 10)
  :config
    (add-hook 'org-mode-hook 'org-rainbow-tags-mode)
    (add-hook 'org-mode-hook
      #'(lambda ()
          (add-hook 'post-command-hook #'org-rainbow-tags--apply-overlays nil t))))
;;; }}} *** org-rainbow-tags

;;; {{{ *** org-ref
(use-package org-ref
  :after (org)
  :init (add-to-list 'package-selected-packages 'org-ref)
  :custom
    (bibtex-autokey-name-year-separator "-")
    (bibtex-autokey-titleword-length 5)
    (bibtex-autokey-titleword-separator "-")
    (bibtex-autokey-titlewords 2)
    (bibtex-autokey-titlewords-stretch 1)
    (bibtex-autokey-year-length 4)
    (bibtex-autokey-year-title-separator "-")
    (bibtex-completion-additional-search-fields '(keywords))
    (bibtex-completion-bibliography
      '("~/nc/Documents/bibliography/references.bib"
        "~/nc/Documents/bibliography/dei.bib"
        "~/nc/Documents/bibliography/master.bib"
        "~/nc/Documents/bibliography/archive.bib"))
    (bibtex-completion-display-formats
      '((article       . "${=has-pdf=:1}${=has-note=:1} ${year:4} ${author:36} ${title:*} ${journal:40}")
        (inbook        . "${=has-pdf=:1}${=has-note=:1} ${year:4} ${author:36} ${title:*} Chapter ${chapter:32}")
        (incollection  . "${=has-pdf=:1}${=has-note=:1} ${year:4} ${author:36} ${title:*} ${booktitle:40}")
        (inproceedings . "${=has-pdf=:1}${=has-note=:1} ${year:4} ${author:36} ${title:*} ${booktitle:40}")
        (t             . "${=has-pdf=:1}${=has-note=:1} ${year:4} ${author:36} ${title:*}")))
    (bibtex-completion-library-path '("~/nc/Documents/bibliography/bibtex-pdfs/"))
    (bibtex-completion-notes-path "~/mc/Documents/bibliography/notes/")
    (bibtex-completion-notes-template-multiple-files
      "* ${author-or-editor}, ${title}, ${journal}, (${year}) :${=type=}: \n\nSee [[cite:&${=key=}]]\n")
    (bibtex-completion-pdf-open-function
      (lambda (fpath)
            (call-process "open" nil 0 nil fpath))))
;;; }}} *** org-ref

;;; {{{ *** org-ref-prettify
(use-package org-ref-prettify
  :after (org)
  :init (add-to-list 'package-selected-packages 'org-ref-prettify)
  :config
    (add-hook 'org-mode-hook        #'org-ref-prettify-mode))
;;; }}} *** org-ref-prettify

;; ;;; {{{ *** org-region-link
;; (use-package org-region-link
;;   :ensure (org-region-link :host github :repo "progfolio/org-region-link")
;;   :after (org)
;;   :init
;;     (add-to-list 'package-selected-packages 'org-region-link))
;; ;;; }}} *** org-region-link

;;; {{{ *** org-roam
(use-package org-roam
  :ensure (org-roam :host github :repo "org-roam/org-roam" :depth nil)
  :after (org)
  :init (add-to-list 'package-selected-packages 'org-roam)
  :custom
    (org-roam-capture-templates
      '(( "d" "default" plain
          "%?"
          :target
            (file+head
              "%<%Y%m%d%H%M%S>-${slug}.org"
              "#+title: ${note-title}\n")
          :unnarrowed t)
        ("n" "literature note" plain
          "%?"
          :target
            (file+head
              "%(expand-file-name (or citar-org-roam-subdir \"\") org-roam-directory)/${citar-citekey}.org"
              "#+title: ${citar-citekey} (${citar-date}). ${note-title}.\n#+created: %U\n#+last_modified: %U\n\n")
          :unnarrowed t)))
    (org-roam-directory (file-truename "~/nc/org/roam/"))
    ;; If you're using a vertical completion framework, you might want a more informative completion interface
    (org-roam-node-display-template (concat "${title:*} " (propertize "${tags:10}" 'face 'org-tag)))
    ;; (org-roam-v2-ack t)
  :config
    (add-to-list 'package-selected-packages 'org-roam)
    (org-roam-db-autosync-mode)
    ;; If using org-roam-protocol
    (require 'org-roam-protocol))

;;; {{{ **** org-roam-bibtex
(use-package org-roam-bibtex
  :after (org-roam)
  :init (add-to-list 'package-selected-packages 'org-roam-bibtex)
  :config
    ;; optional: if using Org-ref v2 or v3 citation links
    (require 'org-ref)
    (org-roam-bibtex-mode t))
;;; }}} **** org-roam-bibtex

;;; {{{ **** org-roam-ql
(use-package org-roam-ql
  ;; Simple configuration
  :after (org-roam)
  :init (add-to-list 'package-selected-packages 'org-roam-ql)
  ;; :bind (
  ;;   :map org-roam-mode-map
  ;;     ;; Have org-roam-ql's transient available in org-roam-mode buffers
  ;;     ("v"          . org-roam-ql-buffer-dispatch)
  ;;   :map minibuffer-mode-map
  ;;     ;; Be able to add titles in queries while in minibuffer.
  ;;     ;; This is similar to `org-roam-node-insert', but adds
  ;;     ;; only title as a string.
  ;;     ("C-c n i"    . org-roam-ql-insert-node-title))
)

(use-package org-roam-ql-ql
  :after (org-ql org-roam-ql)
  :init (add-to-list 'package-selected-packages 'org-roam-ql-ql)
  :config
    ;; Simple config
    (org-roam-ql-ql-init))
;;; }}} **** org-roam-ql

;;; {{{ **** org-roam-timestamps
(use-package org-roam-timestamps
  :after (org-roam)
  :init (add-to-list 'package-selected-packages 'org-roam-timestamps)
  :custom
    (org-roam-timestamps-minimum-gap 3600)
    (org-roam-timestamps-parent-file t)
    (org-roam-timestamps-remember-timestamps t)
  :config
    (org-roam-timestamps-mode t))
;;; }}} **** org-roam-timestamps

;;; {{{ **** org-roam-ui
(use-package org-roam-ui
  :ensure
    (:host github :repo "org-roam/org-roam-ui" :branch "main" :files ("*.el" "out"))
  :after (org-roam)
  :init (add-to-list 'package-selected-packages 'org-roam-ui)
  :custom
    (org-roam-ui-follow t)
    (org-roam-ui-open-on-start t)
    (org-roam-ui-sync-theme t)
    (org-roam-ui-update-on-save t)
  :config
    ;; normally we'd recommend hooking orui after org-roam, but since org-roam does not have
    ;; a hookable mode anymore, you're advised to pick something yourself
    ;; if you don't care about startup time, use
    (add-hook 'after-init-hook      #'org-roam-ui-mode))
;;; }}} **** org-roam-ui
;;; }}} *** org-roam

;;; {{{ *** org-sidebar
(use-package org-sidebar
  :after (org)
  :init (add-to-list 'package-selected-packages 'org-sidebar))
;;; }}} *** org-sidebar

;;; {{{ *** org-special-block-extras
(use-package org-special-block-extras
  :after (org)
  :init (add-to-list 'package-selected-packages 'org-special-block-extras)
  :custom
    (o-docs-libraries
      '("~/nc/org/org-special-block-extras/documentation.org")
      "The places where I keep my ‘#+documentation’")
  :config
    ;; All relevant Lisp functions are prefixed ‘o-’; e.g., `o-docs-insert'.
    (add-hook 'org-mode-hook        #'org-special-block-extras-mode))
;;; }}} *** org-special-block-extras

;;; {{{ *** org-sql
(use-package org-sql
  :after (org)
  :init (add-to-list 'package-selected-packages 'org-sql))
;;; }}} *** org-sql

;;; {{{ *** org-sticky-header
(use-package org-sticky-header
  :after (org)
  :init (add-to-list 'package-selected-packages 'org-sticky-header)
  :config
    (add-hook 'org-mode-hook        #'org-sticky-header-mode)
    (org-sticky-header-mode t))
;;; }}} *** org-sticky-header

;;; {{{ *** org-super-agenda
(use-package org-super-agenda
  :after (org)
  :init (add-to-list 'package-selected-packages 'org-super-agenda)
  :config
    (let ((org-super-agenda-groups
            '(;; Each group has an implicit boolean OR operator between its selectors.
              (:name "Today"  ; Optionally specify section name
                :time-grid t  ; Items that appear on the time grid
                :todo "TODAY")  ; Items that have this TODO keyword
              (:name "Important"
                ;; Single arguments given alone
                :tag "bills"
                :priority "A")
              ;; Set order of multiple groups at once
              (:order-multi
                (2  (:name "Shopping in town"
                      ;; Boolean AND group matches items that match all subgroups
                      :and (:tag "shopping" :tag "@town"))
                    (:name "Food-related"
                      ;; Multiple args given in list with implicit OR
                      :tag ("food" "dinner"))
                    (:name "Personal"
                      :habit t
                      :tag "personal")
                    (:name "Space-related (non-moon-or-planet-related)"
                      ;; Regexps match case-insensitively on the entire entry
                      :and (:regexp ("space" "NASA")
                      ;; Boolean NOT also has implicit OR between selectors
                      :not (:regexp "moon" :tag "planet")))))
              ;; Groups supply their own section names when none are given
              (:todo "WAITING" :order 8)  ; Set order of this section
              (:todo ("SOMEDAY" "TO-READ" "CHECK" "TO-WATCH" "WATCHING")
                ;; Show this group at the end of the agenda (since it has the
                ;; highest number). If you specified this group last, items
                ;; with these todo keywords that e.g. have priority A would be
                ;; displayed in that group instead, because items are grouped
                ;; out in the order the groups are listed.
                :order 9)
              (:priority<= "B"
                ;; Show this section after "Today" and "Important", because
                ;; their order is unspecified, defaulting to 0. Sections
                ;; are displayed lowest-number-first.
                :order 1)
              (:auto-property "ProjectId")
              ;; After the last group, the agenda will display items that didn't
              ;; match any of these groups, with the default order position of 99
              )))
      (org-agenda nil "a")))
;;; }}} *** org-super-agenda

;;; {{{ *** org-superstar
(use-package org-superstar
  :ensure (org-superstar :host github :repo "integral-dw/org-superstar-mode")
  :after (org)
  :init (add-to-list 'package-selected-packages 'org-superstar)
  :custom
    ;; This is usually the default, but keep in mind it must be nil
    (org-hide-leading-stars nil)
    ;; If you use Org Indent you also need to add this, otherwise the
    ;; above has no effect while Indent is enabled.
    (org-indent-mode-turns-on-hiding-stars nil)
    ;; This line is necessary.
    (org-superstar-leading-bullet ?\s)
  :config
    (add-hook 'org-mode-hook        #'(lambda () (org-superstar-mode t))))
;;; }}} *** org-superstar

;;; {{{ *** org-table-color
(use-package org-table-color
  :after (org-table)
  :init (add-to-list 'package-selected-packages 'org-table-color))
;;; }}} *** org-table-color

;;; {{{ *** org-table-sticky-header
(use-package org-table-sticky-header
  :after (org-table)
  :init (add-to-list 'package-selected-packages 'org-table-sticky-header)
  :config
    (add-hook 'org-mode-hook        #'org-table-sticky-header-mode))
;;; }}} *** org-table-sticky-header

;;; {{{ *** org-tag-beautify
(use-package org-tag-beautify
  :after (org)
  :init (add-to-list 'package-selected-packages 'org-tag-beautify)
  :custom
    (org-tag-beautify-data-dir (no-littering-expand-etc-file-name "org/org-tag-beautify/data/") "no-littering `org-tag-beautify-data-dir'")
  :config
    (org-tag-beautify-mode t))
;;; }}} *** org-tag-beautify

;;; {{{ *** org-unique-id
(use-package org-unique-id
  ;; :ensure (org-unique-id :type git :host github :repo "Phundrak/org-unique-id")
  :after (org)
  :init (add-to-list 'package-selected-packages 'org-unique-id)
    (add-hook 'before-save-hook     #'org-unique-id-maybe))
;;; }}} *** org-unique-id

;;; {{{ *** org-variable-pitch
(use-package org-variable-pitch
  :after (org)
  :init (add-to-list 'package-selected-packages 'org-variable-pitch)
  :config
    (add-hook 'org-mode-hook        #'org-variable-pitch-minor-mode))
;;; }}} *** org-variable-pitch

;;; {{{ *** org-view-mode
(use-package org-view-mode
  :after (org)
  :init (add-to-list 'package-selected-packages 'org-view-mode)
  :commands
    (org-view-mode))
;;; }}} *** org-view-mode

;;; {{{ *** org-web-tools
(use-package org-web-tools
  :after (org)
  :init (add-to-list 'package-selected-packages 'org-web-tools)
  ;; :bind (
  ;;   ("C-c w w"      . org-web-tools-insert-link-for-url))
)
;;; }}} *** org-web-tools

;;; {{{ *** org-yt
(use-package org-yt
  :ensure (:host github :repo "TobiasZawada/org-yt")
  :after (org)
  :init (add-to-list 'package-selected-packages 'org-yt))
;;; }}} *** org-yt

;;; {{{ *** orglink
(use-package orglink
  :after (org)
  :init (add-to-list 'package-selected-packages 'org-link)
  :config
    (global-org-link-mode t))
;;; }}} *** orglink

;;; {{{ *** ox (org-export)
;;; {{{ **** ox-clip
(use-package ox-clip
  :after (org)
  :init (add-to-list 'package-selected-packages 'ox-clip))
;;; }}} **** ox-clip

;;; {{{ **** ox-epub
(use-package ox-epub
  :after (ox)
  :init (add-to-list 'package-selected-packages 'ox-epub))
;;; }}} **** ox-epub

;;; {{{ **** ox-gfm
(use-package ox-gfm
  :after (ox)
  :init (add-to-list 'package-selected-packages 'ox-gfm))
;;; }}} **** ox-gfm

;;; {{{ **** ox-gist
(use-package ox-gist
  :after (ox)
  :init (add-to-list 'package-selected-packages 'ox-gist))
;;; }}} **** ox-gist

;;; {{{ **** ox-hugo
(use-package ox-hugo
  :after (ox)
  :init (add-to-list 'package-selected-packages 'ox-hugo)
    (setq-default org-hugo-base-dir (expand-file-name "~/nc/Documents/hugo/")))
;;; }}} **** ox-hugo

;;; {{{ **** ox-json
(use-package ox-json
  :after (ox)
  :init (add-to-list 'package-selected-packages 'ox-json))
;;; }}} **** ox-json

;;; {{{ **** ox-leanpub
(use-package ox-leanpub
  :after (ox)
  :init (add-to-list 'package-selected-packages 'ox-leanpub))
;;; }}} **** ox-leanpub

;;; {{{ **** ox-mediawiki
(use-package ox-mediawiki
  :after (ox)
  :init (add-to-list 'package-selected-packages 'ox-mediawiki))
;;; }}} **** ox-mediawiki

;;; {{{ **** ox-odt
;; Reading LibreOffice files
;; Fixing a bug in Org Mode pre 9.7
;; Org mode clobbers associations with office documents
(use-package ox-odt
  :ensure (ox-odt
            :host github
            :repo "kjambunathan/org-mode-ox-odt"
            :files ("lisp/ox-odt.el"
                     "lisp/odt.el"
                     "etc"
                     "docs"
                     "contrib/odt/LibreOffice"))
  :after (ox)
  :init (add-to-list 'package-selected-packages 'ox-odt)
  :config
    (add-to-list 'auto-mode-alist
        '("\\.\\(?:OD[CFIGPST]\\|od[cfigpst]\\)\\'" . doc-view-mode-maybe)))
;;; }}} **** ox-odt

;;; {{{ **** ox-pandoc
(use-package ox-pandoc
  :after (ox)
  :init (add-to-list 'package-selected-packages 'ox-pandoc)
  :custom
    ;; special extensions for markdown_github output
    (org-pandoc-format-extensions '(markdown_github+pipe_tables+raw_html))
    ;; default options for all output formats
    (org-pandoc-options '((standalone . t)))
    ;; special settings for beamer-pdf and latex-pdf exporters
    (org-pandoc-options-for-beamer-pdf '((pdf-engine . "xelatex")))
    (org-pandoc-options-for-latex-pdf '((pdf-engine . "pdflatex")))
    ;; cancel above settings only for 'docx' format
    (org-pandoc-options-for-docx '((standalone . nil))))
;;; }}} **** ox-pandoc

;;; {{{ **** ox-rfc
(use-package ox-rfc
  :after (ox)
  :init (add-to-list 'package-selected-packages 'ox-rfc))
;;; }}} **** ox-rfc

;;; {{{ **** ox-rss
(use-package ox-rss
  :after (ox)
  :init (add-to-list 'package-selected-packages 'ox-rss))
;;; {{{ **** ox-twbs
;;; }}} **** ox-rss

(use-package ox-twbs
  :after (ox)
  :init (add-to-list 'package-selected-packages 'ox-twbs))
;;; }}} **** ox-twbs
;;; }}} *** ox (org-export)

;;; {{{ *** pkg-overview
(use-package pkg-overview
  :init (add-to-list 'package-selected-packages 'pkg-overview))
;;; }}} *** pkg-overview

;;; {{{ *** toc-org
(use-package toc-org
  :after (org)
  :init (add-to-list 'package-selected-packages 'toc-org)
  ;; :bind (
  ;;   :map markdown-mode-map
  ;;     ("C-c C-o"    . 'toc-org-markdown-follow-thing-at-point))
  :config
    (add-hook 'markdown-mode-hook   #'toc-org-mode)
    (add-hook 'org-mode-hook        #'toc-org-mode))
;;; }}} *** toc-org

;;; {{{ *** wikinforg
;;; {{{ **** wikinfo
(use-package wikinfo
  :ensure (wikinfo :host github :repo "progfolio/wikinfo"  :depth nil)
  :init (add-to-list 'package-selected-packages 'wikinfo))
;;; }}} **** wikinfo

(use-package wikinforg
  :ensure (wikinforg :host github :repo "progfolio/wikinforg" :depth nil :wait t)
  :requires (wikinfo)
  :init (add-to-list 'package-selected-packages 'wikinforg)
  :custom
    (wikinforg-include-thumbnail t)
    (wikinforg-post-insert-hook '(org-redisplay-inline-images))
    (wikinforg-thumbnail-directory (no-littering-expand-var-file-name "wikinforg") "no-littering `wikinforg-thumbnail-directory'")
  :commands
    (wikinforg wikinforg-capture)
  :config
    (add-hook 'wikinforg-mode-hook #'olivetti-mode)
    (add-hook 'wikinforg-mode-hook #'visual-line-mode)
    (add-hook 'wikinforg-mode-hook #'(lambda () (writegood-mode -1)))
    ;; So we can bury temp buffers without evil bindings taking precedence
    (when (or (bound-and-true-p ce-example-use-evil-escape)
              (bound-and-true-p prot-emacs-load-evil))
        (evil-make-intercept-map wikinforg-mode-map)))
;;; }}} *** wikinforg
;;; }}} ** org-mode

;;; {{{ ** polymode
(use-package polymode
  :init (add-to-list 'package-selected-packages 'polymode)
  :custom
    (polymode-exporter-output-dir (no-littering-expand-var-file-name "polymode-exporter-output") "no-littering `polymode-exporter-output-dir'")
  :mode (
    ("\\.ex$"         . poly-elixir-web-mode)
    ("\\.org$"        . poly-org-mode))
  :config
    (define-hostmode poly-elixir-hostmode :mode 'elixir-mode)
    (define-innermode poly-liveview-expr-elixir-innermode
      :mode 'web-mode
      :allow-nested nil
      :fallback-mode 'host
      :head-matcher (rx line-start (* space) "~H" (= 3 (char "\"'")) line-end)
      :head-mode 'host
      :keep-in-mode 'host
      :tail-matcher (rx line-start (* space) (= 3 (char "\"'")) line-end)
      :tail-mode 'host)
    (define-polymode poly-elixir-web-mode
      :hostmode 'poly-elixir-hostmode
      :innermodes '(poly-liveview-expr-elixir-innermode))

    (define-hostmode poly-org-hostmode :mode 'org-mode)
    (define-innermode poly-org-expr-innermode
      :mode 'org-mode
      :head-matcher (rx line-start (* space) "#+BEGIN_SRC" (+ space) (group (+ (not (any space))))
                      (? (group (+ nonl))) line-end)
      :tail-matcher (rx line-start (* space) "#+END_SRC" line-end)
      :head-mode 'host
      :tail-mode 'host)
    (define-polymode poly-org-mode
      :hostmode 'poly-org-hostmode
      :innermodes '(poly-org-expr-innermode))

    ;; Allows you to edit entries directly from org-brain-visualize
    (add-hook 'org-brain-visualize-mode-Hook    #'org-brain-polymode))

(use-package poly-R :init (add-to-list 'package-selected-packages 'poly-R))
(use-package poly-ansible :init (add-to-list 'package-selected-packages 'poly-ansible))
(use-package poly-erb :init (add-to-list 'package-selected-packages 'poly-erb))
(use-package poly-markdown :init (add-to-list 'package-selected-packages 'poly-markdown))
(use-package poly-noweb :init (add-to-list 'package-selected-packages 'poly-noweb))
(use-package poly-org :init (add-to-list 'package-selected-packages 'poly-org))
(use-package poly-rst :init (add-to-list 'package-selected-packages 'poly-rst))
(use-package poly-ruby :init (add-to-list 'package-selected-packages 'poly-ruby))
(use-package poly-slim :init (add-to-list 'package-selected-packages 'poly-slim))
(use-package poly-wdl :init (add-to-list 'package-selected-packages 'poly-wdl))
(use-package quarto-mode
  :init (add-to-list 'package-selected-packages 'quarto-mode)
  :mode
    (("\\.Rmd"  . poly-quarto-mode)))
;;; }}} ** polymode

;;; {{{ ** prescient
(use-package prescient :init (add-to-list 'package-selected-packages 'prescient))
(use-package corfu-prescient :init (add-to-list 'package-selected-packages 'corfu-prescient))
(use-package vertico-prescient :init (add-to-list 'package-selected-packages 'vertico-prescient))
;;; }}} ** prescient

;;; {{{ ** procress
(use-package procress
  :ensure (:host github :repo "haji-ali/procress")
  :init (add-to-list 'package-selected-packages 'procress)
  :commands (procress-auctex-mode)
  :config
    (add-hook 'LaTeX-mode-hook                  #'procress-auctex-mode)
    (procress-load-default-svg-images))
;;; }}} ** procress

;;; {{{ ** prot emacs init
(defgroup prot-emacs nil
    "User options for my dotemacs.\nThese produce the expected results only when set in a file called prot-emacs-pre-custom.el.\nThis file must be in the same directory as the init.el."
    :group 'file)

(defcustom prot-emacs-load-theme-family 'modus
    "Set of themes to load.\nValid values are the symbols `ef', `modus', and `standard',\nwhich reference the `ef-themes', `modus-themes', and `standard-themes', respectively.\n\nA nil value does not load any of the above (use Emacs without a theme).\n\nThis user option must be set in the `prot-emacs-pre-custom.el' file.\nIf that file exists in the Emacs directory, it is loaded before all other modules of my setup."
    :group 'prot-emacs
    :type '(choice :tag "Set of themes to load" :value modus
            (const :tag "The `ef-themes' module" ef)
            (const :tag "The `modus-themes' module" modus)
            (const :tag "The `standard-themes' module" standard)
            (const :tag "Do not load a theme module" nil)))
;;; }}} ** prot emacs init

;;; {{{ ** prot emacs packages
;;; {{{ *** agitate
;; A package of mine to complement VC and friends.    Read the manual
;; here: <https://protesilaos.com/emacs/agitate>.
(use-package agitate
  :ensure (:source "GNU-devel ELPA")
  :init (add-to-list 'package-selected-packages 'agitate)
  :custom
    (agitate-log-edit-informative-show-files nil)
    (agitate-log-edit-informative-show-root-log nil)
  :init
    (advice-add #'vc-git-push :override #'agitate-vc-git-push-prompt-for-remote)
  ;; :bind (
  ;;   ("C-x v ="      . #'agitate-diff-buffer-or-file)                  ;; replace `vc-diff'
  ;;   ("C-x v f"      . #'agitate-vc-git-find-revision)
  ;;   ("C-x v g"      . #'agitate-vc-git-grep)                          ;; replace `vc-annotate'
  ;;   ("C-x v p n"    . #'agitate-vc-git-format-patch-n-from-head)
  ;;   ("C-x v p p"    . #'agitate-vc-git-format-patch-single)
  ;;   ("C-x v s"      . #'agitate-vc-git-show)
  ;;   ("C-x v w"      . #'agitate-vc-git-kill-commit-message)
  ;;   :map diff-mode-map
  ;;   ("C-c C-b"      . #'agitate-diff-refine-cycle)                    ;; replace `diff-refine-hunk'
  ;;   ("C-c C-n"      . #'agitate-diff-narrow-dwim)
  ;;   ("L"            . #'vc-print-root-log)
  ;;   ;; Emacs 29 can use C-x v v in diff buffers, which is great, but now I
  ;;   ;; need quick access to it...
  ;;   ("v"            . #'vc-next-action)
  ;;   :map log-edit-mode-map
  ;;   ;; See user options `agitate-log-edit-emoji-collection' and
  ;;   ;; `agitate-log-edit-conventional-commits-collection'.
  ;;   ("C-c C-i C-c"  . #'agitate-log-edit-conventional-commit)
  ;;   ("C-c C-i C-e"  . #'agitate-log-edit-emoji-commit)
  ;;   ("C-c C-i C-n"  . #'agitate-log-edit-insert-file-name)
  ;;   :map log-view-mode-map
  ;;   ("W"            . #'agitate-log-view-kill-revision-expanded)
  ;;   ("w"            . #'agitate-log-view-kill-revision)
  ;;   :map vc-git-log-view-mode-map
  ;;   ("c"            . #'agitate-vc-git-format-patch-single))
  :config
    (add-hook 'diff-mode-hook           #'agitate-diff-enable-outline-minor-mode)

    (agitate-log-edit-informative-mode t))
;;; }}} *** agitate

;;; {{{ *** aLtCaPs
(use-package altcaps
  :ensure (:source "GNU-devel ELPA")
  :init (add-to-list 'package-selected-packages 'altcaps)
  :custom
    ;; Force letter casing for certain characters (for legibility).
    (altcaps-force-character-casing
        '(("i"      . downcase)
          ("l"      . upcase)
          ("o"      . downcase)))
  ;; :bind (
  ;;   ;; We do not bind any keys, but you are free to do so:
  ;;   ("C-x C-a"      . #'altcaps-dwim))
  :commands (
    ;; The commands we provide:
    altcaps-dwim
    altcaps-region altcaps-word))
;;; }}} *** aLtCaPs

;;; {{{ *** beframe
(use-package beframe
  :ensure (:source "GNU-devel ELPA")
  :init (add-to-list 'package-selected-packages 'beframe)
  :custom
    ;; This is the default value.  Write here the names of buffers that
    ;; should not be beframed.
    (beframe-global-buffers '("*scratch*" "*Messages*" "*Backtrace*"))
  ;; :bind (
  ;;   ;; Bind Beframe commands to a prefix key, such as C-c b:
  ;;   ("C-c b"    . beframe-prefix-map))
  :config
    ;; It is possible to add beframed buffers to the list of sources the consult-buffer command reads from. Just add the following to the beframe configuration:
    (defvar consult-buffer-sources)
    (declare-function consult--buffer-state "consult")
    (with-eval-after-load 'consult
      (defface beframe-buffer
        '((t :inherit font-lock-string-face))
        "Face for `consult' framed buffers.")
      (defun +my/beframe-buffer-names-sorted (&optional frame)
        "Return the list of buffers from `beframe-buffer-names' sorted by visibility.\nWith optional argument FRAME, return the list of buffers of FRAME."
        (beframe-buffer-names frame :sort #'beframe-buffer-sort-visibility))
      (defvar beframe-consult-source
        `(:name       "Frame-specific buffers (current frame)"
          :action     ,#'switch-to-buffer
          :category   buffer
          :face       beframe-buffer
          :history    beframe-history
          :items      ,#'+my/beframe-buffer-names-sorted
          :narrow     ?F
          :state      ,#'consult--buffer-state))
      (add-to-list 'consult-buffer-sources 'beframe-consult-source))

    ;; This is not perfect because frames can have duplicate buffers, but it works:
    (with-eval-after-load 'ibuffer
      (defun +my/beframe-buffer-in-frame (buf frame)
          "Return non-nil if BUF is in FRAME."
          (memq buf (beframe-buffer-list (beframe-frame-object frame))))
      (defun +my/beframe-frame-name-list ()
          "Return list with frame names."
          (mapcar #'car (make-frame-names-alist)))
      (defun +my/beframe-generate-ibuffer-filter-groups ()
        "Create a set of ibuffer filter groups based on the Frame of buffers."
        (mapcar
          (lambda (frame)
            (list (format "%s" frame)
              (list 'predicate '+my/beframe-buffer-in-frame '(current-buffer) frame)))
          (+my/beframe-frame-name-list)))
      (customize-set-variable 'ibuffer-saved-filter-groups `(("Frames" ,@(beframe-generate-ibuffer-filter-groups))))
      (define-ibuffer-filter frame
        "Limit current view to buffers in frames."
        (:description "frame")
        (memq buf (beframe-buffer-list))))

    (beframe-mode t))
;;; }}} *** beframe

;;; {{{ *** cursory
(use-package cursory
  :ensure (:source "GNU-devel ELPA")
  :init (add-to-list 'package-selected-packages 'cursory)
  :custom
    ;; Check the `cursory-presets' for how to set your own preset styles.
    (cursory-presets
      '((box
          :blink-cursor-interval 1.2)
        (box-no-blink
          :blink-cursor-mode -1)
        (bar
          :cursor-type (bar . 2)
          :blink-cursor-interval 0.5)
        (bar-no-other-window
          :inherit bar
          :cursor-in-non-selected-windows nil)
        (underscore
          :cursor-type (hbar . 3)
          :blink-cursor-blinks 50)
        (underscore-thin-other-window
          :inherit underscore
          :cursor-in-non-selected-windows (hbar . 1))
        (underscore-thick
          :cursor-type (hbar . 8)
          :blink-cursor-interval 0.3
          :blink-cursor-blinks 50
          :cursor-in-non-selected-windows (hbar . 3))
        (underscore-thick-no-blink
          :blink-cursor-mode -1
          :cursor-type (hbar . 8)
          :cursor-in-non-selected-windows (hbar . 3))
        (t  ;; the default values
          :cursor-type box
          :cursor-in-non-selected-windows hollow
          :blink-cursor-mode 1
          :blink-cursor-blinks 10
          :blink-cursor-interval 0.2
          :blink-cursor-delay 0.2)))
    ;; I am using the default values of `cursory-latest-state-file'.
    (cursory-latest-state-file (no-littering-expand-var-file-name "cursory-latest-state.eld") "no-littering `cursory-latest-state-file'")
  ;; :bind (
  ;;   ;; We have to use the "point" mnemonic, because C-c c is often the
  ;;   ;; suggested binding for `org-capture'.
  ;;   ("C-c p"    . #'cursory-set-preset))
  :config
    ;; The other side of `cursory-restore-latest-preset'.
    (add-hook 'kill-emacs-hook          #'cursory-store-latest-preset)

    ;; Set last preset or fall back to desired style from `cursory-presets'.
    (cursory-set-preset (or (cursory-restore-latest-preset) 'box)))     ;;'bar)))
;;; }}} *** cursory

;;; {{{ *** denote
(use-package denote
  :ensure (:source "GNU-devel ELPA")
  :init (add-to-list 'package-selected-packages 'denote)
  :custom
    ;; Remember to check the doc strings of those variables.

    ;; By default, we do not show the context of links.  We just display
    ;; file names.  This provides a more informative view.
    (denote-backlinks-show-context t)
    ;; Also see `denote-link-backlinks-display-buffer-action' which is a bit
    ;; advanced.

    ;; Pick dates, where relevant, with Org's advanced interface:
    (denote-date-format nil)                    ;; read doc string
    (denote-date-prompt-use-org-read-date t)
    (denote-directory (file-truename "~/nc/Documents/notes/"))
    ;; We use different ways to specify a path for demo purposes.
    (denote-dired-directories
      (list denote-directory
            (thread-last denote-directory (expand-file-name "attachments"))
            (expand-file-name "~/nc/Documents/books")))
    (denote-excluded-directories-regexp nil)
    (denote-excluded-keywords-regexp nil)
    (denote-file-name-letter-casing
      '((signature . verbatim)
        (title . downcase)
        (keywords . verbatim)
        (t , verbatim)))
    (denote-file-type nil)                      ;; Org is the default, set others here
    ;;(denote-file-type 'text)                  ;; Org is the default, set others here like I do

    ;; If you want to have a "controlled vocabulary" of keywords,
    ;; meaning that you only use a predefined set of them, then you want
    ;; `denote-infer-keywords' to be nil and `denote-known-keywords' to
    ;; have the keywords you need.
    (denote-infer-keywords t)
    (denote-known-keywords '("emacs" "philosophy" "politics" "economics"))
    (denote-sort-keywords t)

    (denote-prompts '(title keywords))
    (denote-rename-buffer-format "[D] %t")
    (denote-rename-no-confirm nil)                  ;; Set to t if you are familiar with `denote-rename-file'
    (denote-save-buffer-after-creation nil)

  :custom-face
    (denote-faces-link ((t (:slant italic))))

    ;; Read this manual for how to specify `denote-templates'.  We do not
    ;; include an example here to avoid potential confusion.
  ;; :bind (
  ;;   ;; Denote DOES NOT define any key bindings.  This is for the user to
  ;;   ;; decide.  For example:
  ;;   ("C-c n K"      . #'denote-keywords-remove)
  ;;   ("C-c n N"      . #'denote-type)
  ;;   ("C-c n c"      . #'denote-region)          ;; "contents" mnemonic
  ;;   ("C-c n d"      . #'denote-date)
  ;;   ("C-c n k"      . #'denote-keywords-add)
  ;;   ("C-c n n"      . #'denote)
  ;;   ("C-c n s"      . #'denote-subdirectory)
  ;;   ("C-c n t"      . #'denote-template)
  ;;   ("C-c n z"      . #'denote-signature)       ;; "zettelkasten" mnemonic
  ;;   ;; If you intend to use Denote with a variety of file types, it is
  ;;   ;; easier to bind the link-related commands to the `global-map', as
  ;;   ;; shown here.  Otherwise follow the same pattern for `org-mode-map',
  ;;   ;; `markdown-mode-map', and/or `text-mode-map'.
  ;;   ("C-c n I"      . #'denote-add-links)
  ;;   ("C-c n b"      . #'denote-backlinks)
  ;;   ("C-c n f b"    . #'denote-find-backlink)
  ;;   ("C-c n f f"    . #'denote-find-link)
  ;;   ("C-c n i"      . #'denote-link-or-create)  ;; "insert" mnemonic
  ;;   ;; Note that `denote-rename-file' can work from any context, not just
  ;;   ;; Dired bufffers.  That is why we bind it here to the `global-map'.
  ;;   ("C-c n R"      . #'denote-rename-file-using-front-matter)
  ;;   ("C-c n r"      . #'denote-rename-file)

  ;;   ;; I do not bind the Org dynamic blocks, but they are useful:
  ;;   ;;
  ;;   ;; - `denote-org-dblock-insert-links'
  ;;   ;; - `denote-org-dblock-insert-backlinks'
  ;;   ;; - `denote-org-dblock-insert-files'
  ;;   ("C-c n o I"    . #'denote-org-extras-dblock-insert-links)  ;; from ews
  ;;   ("C-c n o b"    . #'denote-org-dblock-insert-backlinks)
  ;;   ("C-c n o f"    . #'denote-org-dblock-insert-files)
  ;;   ("C-c n o i"    . #'denote-org-dblock-insert-links)

  ;;   ;; Key bindings specifically for Dired.
  ;;   :map dired-mode-map
  ;;   ("C-c C-d C-i"  . #'denote-link-dired-marked-notes)
  ;;   ("C-c C-d C-r"  . #'denote-dired-rename-files)
  ;;   ("C-c C-d C-k"  . #'denote-dired-rename-marked-files-with-keywords)
  ;;   ("C-c C-d C-R"  . #'denote-dired-rename-marked-files-using-front-matter)
  ;;   ;; Also check the commands `denote-link-after-creating',
  ;;   ;; `denote-link-or-create'.  You may want to bind them to keys as well.
  ;; )
  :config
    ;; If you use Markdown or plain text files you want to buttonise
    ;; existing buttons upon visiting the file (Org renders links as
    ;; buttons right away).
    (add-hook 'find-file-hook           #'denote-link-buttonize-buffer)

    ;; Highlight Denote file names in Dired buffers.  Below is the
    ;; generic approach, which is great if you rename files Denote-style
    ;; in lots of places as I do:
    (add-hook 'dired-mode-hook          #'denote-dired-mode)
    ;;
    ;; OR if you only want the `denote-dired-mode' in select
    ;; directories, then modify the variable `denote-dired-directories'
    ;; and use the following instead:
    ;;
    ;; (add-hook 'dired-mode-hook          #'denote-dired-mode-in-directories)

    ;; If you want to have Denote commands available via a right click
    ;; context menu, use the following and then enable
    ;; `context-menu-mode'.
    (add-hook 'context-menu-functions   #'denote-context-menu)

    (with-eval-after-load 'org-capture
      (customize-set-variable 'denote-org-capture-specifiers "%l\n%i\n%?")
      (add-to-list 'org-capture-templates
                   '("n" "New note (with denote.el)" plain
                     (file denote-last-path)
                     #'denote-org-capture
                     :no-save t
                     :immediate-finish nil
                     :kill-buffer t
                     :jump-to-captured t))
      ;; This prompts for TITLE, KEYWORDS, and SUBDIRECTORY
      (add-to-list 'org-capture-templates
                   '("N" "New note with prompts (with denote.el)" plain
                     (file denote-last-path)
                     (function
                       (lambda ()
                         (denote-org-capture-with-prompts :title :keywords :signature)))
                     :immediate-finish nil
                     :kill-buffer t
                     :jump-to-captured t
                     :no-save t)))

    (when (require 'denote-journal-extras nil :noerror)
        (customize-set-variable 'denote-journal-extras-directory "journal")       ;; use the `denote-directory'
        (customize-set-variable 'denote-journal-extras-keyword "journal")
        (customize-set-variable 'denote-journal-extras-title-format nil))   ;; always prompt for title

    ;; Automatically rename Denote buffers when opening them so that
    ;; instead of their long file name they have a literal "[D]"
    ;; followed by the file's title.  Read the doc string of
    ;; `denote-rename-buffer-format' for how to modify this.
    (denote-rename-buffer-mode t))

;;; {{{ **** consult-notes
(use-package consult-notes
  :after (consult denote)
  :init (add-to-list 'package-selected-packages 'consult-notes)
  :custom
    (consult-narrow-key ":")
    (consult-notes-file-dir-sources `(("Denote Notes"  ?d ,ews-notes-directory)))
  ;; :bind (
  ;;   ("C-c w f"  . consult-notes)
  ;;   ("C-c w g"  . consult-notes-search-in-all-notes)
  ;;   ("C-c w h"  . consult-org-heading))
)
;;; }}} **** consult-notes

;;; {{{ **** consult-denote
(use-package consult-denote
  :ensure (:source "GNU-devel ELPA")
  :after (consult denote)
  :init (add-to-list 'package-selected-packages 'consult-denote)
  :custom
    (consult-denote-consult-notes-command #'consult-notes)
  :bind (
    ("C-c w n"  . consult-denote))
  :config
    (consult-denote-mode t))
;;; }}} **** consult-denote

;;; {{{ **** denote-explore
(use-package denote-explore
  :init (add-to-list 'package-selected-packages 'denote-explore)
  :custom
    (denote-explore-extensions
      '(("org" . 0) ("md" . 0) ("txt" . 0) ("el" . 0) ("sh" . 0) ("py" . 0) ("R" . 0) ("jl" . 0) ("ipynb" . 0))
      "File extensions to explore.")
  ;; :bind (
  ;;   ;; Statistics
  ;;   ("C-c w x C" . denote-explore-count-keywords)
  ;;   ("C-c w x b" . denote-explore-keywords-barchart)
  ;;   ("C-c w x c" . denote-explore-count-notes)
  ;;   ("C-c w x x" . denote-explore-extensions-barchart)
  ;;   ;; Random walks
  ;;   ("C-c w x k" . denote-explore-random-keyword)
  ;;   ("C-c w x l" . denote-explore-random-link)
  ;;   ("C-c w x r" . denote-explore-random-note)
  ;;   ;; Denote Janitor
  ;;   ("C-c w x d" . denote-explore-identify-duplicate-notes)
  ;;   ("C-c w x o" . denote-explore-sort-keywords)
  ;;   ("C-c w x r" . denote-explore-rename-keywords)
  ;;   ("C-c w x s" . denote-explore-single-keywords)
  ;;   ("C-c w x z" . denote-explore-zero-keywords)
  ;;   ;; Visualise denote
  ;;   ("C-c w x D" . denote-explore-degree-barchart)
  ;;   ("C-c w x n" . denote-explore-network)
  ;;   ("C-c w x v" . denote-explore-network-regenerate))
)
;;; }}} **** denote-explore

;;; {{{ **** denote-menu
(use-package denote-menu
  :after (denote)
  :init (add-to-list 'package-selected-packages 'denote-menu)
  :custom
    (denote-menu-commands
      '(("b" "Backlinks" . denote-backlinks)
        ("B" "Find backlink" . denote-find-backlink)
        ("c" "Contents" . denote-region)
        ("d" "Date" . denote-date)
        ("F" "Find link" . denote-find-link)
        ("f" "Find note" . denote-find)
        ("g" "Consult notes search" . consult-notes-search-in-all-notes)
        ("h" "Consult org heading" . consult-org-heading)
        ("i" "Insert link" . denote-link-or-create)
        ("I" "Insert links" . denote-add-links)
        ("k" "Keywords" . denote-keywords-add)
        ("K" "Remove keywords" . denote-keywords-remove)
        ("l" "Consult link" . consult-denote)
        ("L" "Consult notes link" . consult-notes-link)
        ("N" "New note with prompts" . denote-with-prompts)
        ("n" "New note" . denote)
        ("o" "Org extras" . denote-org-extras)
        ("r" "Rename file using front matter" . denote-rename-file-using-front-matter)
        ("R" "Rename file" . denote-rename-file)
        ("s" "Subdirectory" . denote-subdirectory)
        ("t" "Template" . denote-template)
        ("w" "Consult notes" . consult-notes)
        ("x" "Explore" . denote-explore)
        ("z" "Signature" . denote-signature))
      "Commands for the Denote menu.")
  :bind (
    ("C-c w m"  . denote-menu))
  :config
    (denote-menu-mode t))
;;; }}} **** denote-menu

;;; {{{ **** denote-refs
(use-package denote-refs
  :ensure (:repo "https://codeberg.org/akib/emacs-denote-refs.git")
  :after (denote)
  :init (add-to-list 'package-selected-packages 'denote-refs)
  :custom
    (denote-refs-commands
      '(("b" "Backlinks" . denote-backlinks)
        ("B" "Find backlink" . denote-find-backlink)
        ("F" "Find link" . denote-find-link)
        ("f" "Find note" . denote-find)
        ("g" "Consult notes search" . consult-notes-search-in-all-notes)
        ("h" "Consult org heading" . consult-org-heading)
        ("i" "Insert link" . denote-link-or-create)
        ("I" "Insert links" . denote-add-links)
        ("k" "Keywords" . denote-keywords-add)
        ("K" "Remove keywords" . denote-keywords-remove)
        ("l" "Consult link" . consult-denote)
        ("L" "Consult notes link" . consult-notes-link)
        ("N" "New note with prompts" . denote-with-prompts)
        ("n" "New note" . denote)
        ("o" "Org extras" . denote-org-extras)
        ("r" "Rename file using front matter" . denote-rename-file-using-front-matter)
        ("R" "Rename file" . denote-rename-file)
        ("s" "Subdirectory" . denote-subdirectory)
        ("t" "Template" . denote-template)
        ("w" "Consult notes" . consult-notes)
        ("z" "Signature" . denote-signature))
      "Commands for the Denote refs menu.")
  :bind (
    ("C-c w r"  . denote-refs))
  :config
    (denote-refs-mode t))
;;; }}} **** denote-refs
;;; }}} *** denote

;;; {{{*** dired-preview
(use-package dired-preview
  :ensure (:source "GNU-devel ELPA")
  :init (add-to-list 'package-selected-packages 'dired-preview)
  :custom
    ;; Default values for demo purposes
    (dired-preview-delay 0.7)
    (dired-preview-ignored-extensions-regexp
      (concat "\\."
        "\\(mkv\\|webm\\|mp4\\|mp3\\|ogg\\|m4a"
        "\\|gz\\|zst\\|tar\\|xz\\|rar\\|zip"
        "\\|iso\\|epub\\|pdf\\)"))
    (dired-preview-max-size (expt 2 20))
  :config
    (dired-preview-global-mode t))
;;; }}}*** dired-preview

;;; {{{ *** ef-themes
(use-package ef-themes
  :ensure (:source "GNU-devel ELPA")
  :init (add-to-list 'package-selected-packages 'ef-themes)
  :custom
    (ef-themes-headings  ;; read the manual's entry or the doc string
      '((0 variable-pitch light 1.9)
        (1 variable-pitch light 1.8)
        (2 variable-pitch regular 1.7)
        (3 variable-pitch regular 1.6)
        (4 variable-pitch regular 1.5)
        (5 variable-pitch 1.4) ; absence of weight means `bold'
        (6 variable-pitch 1.3)
        (7 variable-pitch 1.2)
        (t variable-pitch 1.1)))
    (ef-themes-mixed-fonts t)
    ;; Make customisations that affect Emacs faces BEFORE loading a theme
    ;; (any change needs a theme re-load to take effect).
    ;; If you like two specific themes and want to switch between them, you
    ;; can specify them in `ef-themes-to-toggle' and then invoke the command
    ;; `ef-themes-toggle'.  All the themes are included in the variable
    ;; `ef-themes-collection'.
    (ef-themes-to-toggle '(ef-deuteranopia-dark ef-duo-dark))
    (ef-themes-variable-pitch-ui t)
  :commands (
    ;; We also provide these commands, but do not assign them to any key:
    ;;
    ;; - `ef-themes-toggle'
    ;; - `ef-themes-select'
    ;; - `ef-themes-select-dark'
    ;; - `ef-themes-select-light'
    ;; - `ef-themes-load-random'
    ;; - `ef-themes-preview-colors'
    ;; - `ef-themes-preview-colors-current'
    ef-themes-load-random
    ef-themes-preview-colors
    ef-themes-preview-colors-current
    ef-themes-select
    ef-themes-select-dark
    ef-themes-select-light
    ef-themes-toggle)
  :config
    ;; The `ef-themes' provide lots of themes.    I want to pick one at
    ;; random when I start Emacs: the `ef-themes-load-random' does just
    ;; that (it can be called interactively as well).    I just check with
    ;; my desktop environment to determine if the choice should be about
    ;; a light or a dark theme.    Those functions are in my init.el.
    ;;(if (prot-emacs-theme-environment-dark-p)
    ;;        (ef-themes-load-random 'dark)
    ;;    (ef-themes-load-random 'light)))
    (ef-themes-load-random 'dark))
;;; }}} *** ef-themes

;;; {{{ *** fontaine
(use-package fontaine
  :ensure (:source "GNU-devel ELPA")
  :init (add-to-list 'package-selected-packages 'fontaine)
  :custom
    ;; This is the default value.   Just including it here for completeness.
    (fontaine-latest-state-file (no-littering-expand-var-file-name "fontaine-latest-state.eld") "no-littering `fontaine-latest-state-file'")
    ;; Iosevka Comfy is my highly customised build of Iosevka with
    ;; monospaced and duospaced (quasi-proportional) variants as well as
    ;; support or no support for ligatures:
    ;; <https://github.com/protesilaos/iosevka-comfy>.
    (fontaine-presets
      '((small
          :default-family "Iosevka Comfy Motion"
          :default-height 80
          :variable-pitch-family "Iosevka Comfy Duo")
        (regular) ; like this it uses all the fallback values and is named `regular'
        (medium
          :default-weight semilight
          :default-height 115
          :bold-weight extrabold)
        (large
          :inherit medium
          :default-height 150)
        (live-stream
          :default-family "Iosevka Comfy Wide Motion"
          :default-height 150
          :default-weight medium
          :fixed-pitch-family "Iosevka Comfy Wide Motion"
          :variable-pitch-family "Iosevka Comfy Wide Duo"
          :bold-weight extrabold)
        (presentation
          :default-height 180)
        (t
          ;; I keep all properties for didactic purposes, but most can be
          ;; omitted.  See the fontaine manual for the technicalities:
          ;; <https://protesilaos.com/emacs/fontaine>.
          :default-family "Iosevka Comfy"
          :default-weight regular
          :default-height 100

          :fixed-pitch-family nil ; falls back to :default-family
          :fixed-pitch-weight nil ; falls back to :default-weight
          :fixed-pitch-height 1.0

          :fixed-pitch-serif-family nil ; falls back to :default-family
          :fixed-pitch-serif-weight nil ; falls back to :default-weight
          :fixed-pitch-serif-height 1.0

          :variable-pitch-family "Iosevka Comfy Motion Duo"
          :variable-pitch-weight nil
          :variable-pitch-height 1.0

          :mode-line-active-family nil ; falls back to :default-family
          :mode-line-active-weight nil ; falls back to :default-weight
          :mode-line-active-height 0.9

          :mode-line-inactive-family nil ; falls back to :default-family
          :mode-line-inactive-weight nil ; falls back to :default-weight
          :mode-line-inactive-height 0.9

          :header-line-family nil ; falls back to :default-family
          :header-line-weight nil ; falls back to :default-weight
          :header-line-height 0.9

          :line-number-family nil ; falls back to :default-family
          :line-number-weight nil ; falls back to :default-weight
          :line-number-height 0.9

          :tab-bar-family nil ; falls back to :default-family
          :tab-bar-weight nil ; falls back to :default-weight
          :tab-bar-height 1.0

          :tab-line-family nil ; falls back to :default-family
          :tab-line-weight nil ; falls back to :default-weight
          :tab-line-height 1.0

          :bold-family nil ; use whatever the underlying face has
          :bold-weight bold

          :italic-family nil
          :italic-slant italic

          :line-spacing nil)))
    ;; This is defined in Emacs C code: it belongs to font settings.
    (x-underline-at-descent-line nil)
  ;; :bind (
  ;;   ;; fontaine does not define any key bindings.  This is just a sample that
  ;;   ;; respects the key binding conventions.  Evaluate:
  ;;   ;;
  ;;   ;;     (info "(elisp) Key Binding Conventions")
  ;;   ("C-c f"        . #'fontaine-set-preset))
  :config
    ;; Persist font configurations while switching themes.    The
    ;; `enable-theme-functions' is from Emacs 29.
    (add-hook 'enable-theme-functions   #'fontaine-apply-current-preset)
    (add-hook 'fontaine-set-preset      #'fontaine-store-latest-preset)
    ;; The other side of `fontaine-restore-latest-preset'.
    (add-hook 'kill-emacs-hook          #'fontaine-store-latest-preset)

    (setq-default text-scale-remap-header-line t)   ;; Emacs 28
    ;; Set last preset or fall back to desired style from `fontaine-presets'.
    (fontaine-set-preset (or (fontaine-restore-latest-preset) 'regular))
    ;; Persist the latest font preset when closing/starting Emacs and
    ;; while switching between themes.
    (fontaine-mode t))
;;; }}} *** fontaine

;;; {{{ *** lin
(use-package lin
  :ensure (:source "GNU-devel ELPA")
  :init (add-to-list 'package-selected-packages 'lin)
  :custom
    ;; You can use this to live update the face:
    ;;
    ;; (lin-face 'lin-green)
    (lin-face 'lin-magenta)     ;; check doc string for alternative styles
    (lin-mode-hooks
      '(bongo-mode-hook
        dired-mode-hook
        elfeed-search-mode-hook
        git-rebase-mode-hook
        grep-mode-hook
        ibuffer-mode-hook
        ilist-mode-hook
        ledger-report-mode-hook
        log-view-mode-hook
        magit-log-mode-hook
        mu4e-headers-mode-hook
        notmuch-search-mode-hook
        notmuch-tree-mode-hook
        occur-mode-hook
        org-agenda-mode-hook
        pdf-outline-buffer-mode-hook
        proced-mode-hook
        tabulated-list-mode-hook))
  :config
    (lin-global-mode t))
;;; }}} *** lin

;;; {{{ *** logos
(use-package logos
  :ensure (:source "GNU-devel ELPA")
  :init (add-to-list 'package-selected-packages 'logos)
  :custom
    ;; If you want to use outlines instead of page breaks (the ^L):
    (logos-outlines-are-pages t)
    ;; This is the default value for the outlines:
    (logos-outline-regexp-alist
      `((emacs-lisp-mode      . "^;;;+ ")
        (markdown-mode        . "^\\#+ +")
        (org-mode             . "^\\*+ +")))

    ;; 5.1. Center the buffer in its window
    ;; Install the excellent olivetti package by Paul W. Rankin. Then set logos-olivetti to non-nil.
    ;; The present author’s favourite settings given a fill-column of 72:
    (olivetti-body-width 0.7)
    (olivetti-minimum-body-width 80)
    (olivetti-recall-visual-line-mode-entry-state t)
    ;; Though note that Olivetti works well even without a fill-column and auto-fill-mode disabled.
  :config
    ;; These apply when `logos-focus-mode' is enabled.  Their value is buffer-local.
    (setq-default
      logos-buffer-read-only nil
      logos-hide-buffer-boundaries t
      logos-hide-cursor nil
      logos-hide-fringe t
      logos-hide-header-line t
      logos-hide-mode-line t
      logos-olivetti nil
      logos-scroll-lock nil
      logos-variable-pitch nil)
    ;; Also check this manual for `logos-focus-mode-hook'.  It lets you extend `logos-focus-mode'.
    (let ((map global-map))
      (define-key map [remap narrow-to-region] #'logos-narrow-dwim)
      (define-key map [remap forward-page] #'logos-forward-page-dwim)
      (define-key map [remap backward-page] #'logos-backward-page-dwim)
      (define-key map (kbd "<f9>") #'logos-focus-mode))
    ;; Also consider adding keys to `logos-focus-mode-map'.  They will take effect when `logos-focus-mode' is enabled.

    ;; Assuming the `menu-bar-mode' is enabled by default...
    (defun +my/logos-hide-menu-bar ()
      (when logos-focus-mode
          (logos-set-mode-arg 'menu-bar-mode -1)))
    (add-hook 'logos-focus-mode-hook    #'+my/logos-hide-menu-bar)

    ;; Assuming the `tab-bar-mode' is enabled by default...
    (defun +my/logos-hide-tab-bar ()
      (when logos-focus-mode
          (logos-set-mode-arg 'tab-bar-mode -1)))
    (add-hook 'logos-focus-mode-hook    #'+my/logos-hide-tab-bar)

    ;; Assuming the `tab-line-mode' is enabled by default...
    (defun +my/logos-hide-tab-line ()
      (when logos-focus-mode
          (logos-set-mode-arg 'tab-line-mode -1)))
    (add-hook 'logos-focus-mode-hook    #'+my/logos-hide-tab-line)

    ;; Assuming the `tool-bar-mode' is enabled by default...
    (defun +my/logos-hide-tool-bar ()
      (when logos-focus-mode
          (logos-set-mode-arg 'tool-bar-mode -1)))
    (add-hook 'logos-focus-mode-hook    #'+my/logos-hide-tool-bar)

    ;; place point at the top when changing pages
    (defun +my/logos-recenter-top ()
      "Use `recenter' to reposition the view at the top."
      (unless (derived-mode-p 'prog-mode)
          (recenter 0)))
    (add-hook 'logos-page-motion-hook   #'+my/logos-recenter-top)

    (defun +my/logos-reveal-entry ()
      "Reveal Org or Outline entry."
      (cond
        ( (and (eq major-mode 'org-mode)
            (org-at-heading-p))
          (org-show-entry))
        ( (or (eq major-mode 'outline-mode)
            (bound-and-true-p outline-minor-mode))
          (outline-show-entry))))
    (add-hook 'logos-page-motion-hook   #'+my/logos-reveal-entry)

    ;; glue code to expand an Org/Outline heading
    (defun +my/logos-reveal-subtree ()
      "Reveal Org or Outline subtreee."
      (cond
        ( (and (eq major-mode 'org-mode)
                (org-at-heading-p))
          (org-show-subtree))
        ( (or (eq major-mode 'outline-mode)
                (bound-and-true-p outline-minor-mode))
          (outline-show-subtree))))
    (add-hook 'logos-page-motion-hook   #'+my/logos-reveal-subtree))
;;; }}} *** logos

;;; {+{{ *** mandoura
(use-package mandoura
  :ensure (mandoura :host github :repo "protesilaos/mandoura")
  :init (add-to-list 'package-selected-packages 'mandoura)
  :custom
    (mandoura-saved-playlist-directory (file-true-name "~/nc/Music/mandoura/"))
    (mandoura-saved-playlist-file (expand-file-name "mandoura-playlist.org" mandoura-saved-playlist-directory)))
;;; }}} *** mandoura

;;; {{{ *** modus-themes
;;; For packaged versions which must use `require'.
(use-package modus-themes
  :ensure (:source "GNU-devel ELPA")
  :init (add-to-list 'package-selected-packages 'modus-themes)
  :custom
    ;; Add all your customizations prior to loading the themes
    (modus-themes-bold-constructs nil)
    (modus-themes-bold-constructs t)

    (modus-themes-common-palette-overrides nil)
        ;; '((bg-mode-line-active bg-cyan-subtle)
        ;;   (keybind yellow-warmer)))
    ;; Maybe define some palette overrides, such as by using our presets
    (modus-themes-common-palette-overrides 'modus-themes-preset-overrides-intense)

    ;; Make the modeline borderless
    ;; Remove the border
    (modus-themes-common-palette-overrides
      '((border-mode-line-active unspecified)
        (border-mode-line-inactive unspecified)))
    ;; Keep the border but make it the same color as the background of the
    ;; mode line (thus appearing borderless).  The difference with the
    ;; above is that this version is a bit thicker because the border are
    ;; still there.
    ;;(modus-themes-common-palette-overrides
    ;;  '((border-mode-line-active bg-mode-line-active)
    ;;    (border-mode-line-inactive bg-mode-line-inactive)))

    (modus-themes-completions '((t . (extrabold))))
    (modus-themes-custom-auto-reload nil)
    (modus-themes-disable-other-themes t)
    (modus-themes-headings
      '((agenda-date        . (variable-pitch regular 1.3))
        (agenda-structure   . (variable-pitch light 2.2))
        (t                  . (regular 1.15))))
    (modus-themes-italic-constructs t)
    (modus-themes-mixed-fonts t)
    (modus-themes-prompts '(bold italic))
    (modus-themes-prompts '(extrabold))
    ;;(modus-themes-to-toggle '(modus-operandi modus-vivendi))
    ;;(modus-themes-to-toggle '(modus-operandi-deuteranopia modus-vivendi-deuteranopia))
    ;;(modus-themes-to-toggle '(modus-operandi-tinted modus-vivendi-tinted))
    ;;(modus-themes-to-toggle '(modus-operandi-tritanopia modus-vivendi-tritanopia))
    (modus-themes-to-toggle '(modus-vivendi modus-vivendi-tinted))
    (modus-themes-variable-pitch-ui t)
  ;; :bind (
  ;;   ("<f5>"    . #'modus-themes-toggle))
  :config
    ;; Load the theme of your choice.
    (load-theme 'modus-vivendi)

    ;;(if (prot-emacs-theme-environment-dark-p)
    ;;    (modus-themes-load-theme (cadr modus-themes-to-toggle))
    ;;  (modus-themes-load-theme (car modus-themes-to-toggle))))
    (modus-themes-load-theme 'modus-vivendi))
;;; }}} *** modus-themes

;;; {{{ *** notmuch-indicator
(use-package notmuch-indicator
  :ensure (:source "GNU-devel ELPA")
  :init (add-to-list 'package-selected-packages 'notmuch-indicator)
  :custom
    (notmuch-indicator-notify nil)
    (notmuch-indicator-show-count t)
    (notmuch-indicator-show-unread t)
  :config
    (notmuch-indicator-mode t))
;;; }}} *** notmuch-indicator

;;; {{{ *** pulsar
(use-package pulsar
  :ensure (:source "GNU-devel ELPA")
  :init (add-to-list 'package-selected-packages 'pulsar)
  :custom
    ;; Check the default value of `pulsar-pulse-functions'.  That is where
    ;; you add more commands that should cause a pulse after they are
    ;; invoked
    (pulsar-delay 0.055)
    (pulsar-face 'pulsar-magenta)
    (pulsar-highlight-face 'pulsar-cyan)
    (pulsar-iterations 10)
    (pulsar-pulse t)
  ;; :bind (
  ;;   ;; pulsar does not define any key bindings.  This is just a sample that
  ;;   ;; respects the key binding conventions.  Evaluate:
  ;;   ;;
  ;;   ;;     (info "(elisp) Key Binding Conventions")
  ;;   ;;
  ;;   ;; The author uses C-x l for `pulsar-pulse-line' and C-x L for
  ;;   ;; `pulsar-highlight-line'.
  ;;   ;;
  ;;   ;; You can replace `pulsar-highlight-line' with the command
  ;;   ;; `pulsar-highlight-dwim'.
  ;;   ;;(let ((map global-map))
  ;;     ;;(define-key map (kbd "C-c h p") #'pulsar-pulse-line)
  ;;     ;;(define-key map (kbd "C-c h h") #'pulsar-highlight-line))
  ;;   ("C-x L"    . #'pulsar-highlight-dwim)      ;; or use `pulsar-highlight-line'
  ;;   ("C-x l"    . #'pulsar-pulse-line))         ;; override `count-lines-page'
  :config
    ;; integration with the `consult' package:
    (add-hook 'consult-after-jump-hook          #'pulsar-recenter-top)
    (add-hook 'consult-after-jump-hook          #'pulsar-reveal-entry)
    ;; integration with the built-in `imenu':
    (add-hook 'imenu-after-jump-hook            #'pulsar-recenter-top)
    (add-hook 'imenu-after-jump-hook            #'pulsar-reveal-entry)
    (add-hook 'minibuffer-setup-hook            #'pulsar-pulse-line-red)
    (add-hook 'next-error-hook                  #'pulsar-pulse-line-red)
    (add-hook 'next-error-hook                  #'pulsar-recenter-top)
    (add-hook 'next-error-hook                  #'pulsar-reveal-entry)

    (pulsar-global-mode t))
    ;; OR use the local mode for select mode hooks
    ;;(dolist (hook '(org-mode-hook emacs-lisp-mode-hook))
      ;;(add-hook hook #'pulsar-mode)))
;;; }}} *** pulsar

;;; {{{ *** rainbow-mode
;;;; Rainbow mode for colour previewing (rainbow-mode.el)
(use-package rainbow-mode
  :ensure (:source "GNU-devel ELPA")
  :init (add-to-list 'package-selected-packages 'rainbow-mode)
  :custom
    (customize-set-variable 'rainbow-ansi-colors nil)
    (customize-set-variable 'rainbow-x-colors nil)
  ;; :bind (
  ;;   :map ctl-x-x-map
  ;;     ("c"      . #'rainbow-mode))
  :config
    (defun +my/rainbow-mode-in-themes ()
      (when-let ( (file (buffer-file-name))
                  ((derived-mode-p 'emacs-lisp-mode))
                  ((string-match-p "-theme" file)))
          (rainbow-mode t)))
    (add-hook 'emacs-lisp-mode-hook             #'+my/rainbow-mode-in-themes))
;;; }}} *** rainbow-mode

;;; {{{ *** spacious-padding
(use-package spacious-padding
  :ensure (:source "GNU-devel ELPA")
  :init (add-to-list 'package-selected-packages 'spacious-padding)
  ;; :bind (
  ;;   ;; Set a key binding if you need to toggle spacious padding.
  ;;   ("<f8>" . #'spacious-padding-mode))
  :custom
    ;; These is the default value, but I keep it here for visiibility.
    (spacious-padding-widths
      '(:internal-border-width 15
        :header-line-width 4
        :mode-line-width 6
        :tab-width 8
        :right-divider-width 30
        :scroll-bar-width 8
        :fringe-width 8))

    ;; ;; Read the doc string of `spacious-padding-subtle-mode-line' as
    ;; ;; it is very flexible.
    (spacious-padding-subtle-mode-line
      `(:mode-line-active ,(if  (or (eq prot-emacs-load-theme-family 'modus)
                                  (eq prot-emacs-load-theme-family 'standard))
                                'default
                              'help-key-binding)
        :mode-line-inactive vertical-border))
  :config
    (spacious-padding-mode t))
;;; }}} *** spacious-padding

;;; {{{ *** standard-themes
(use-package standard-themes
  :ensure (:source "GNU-devel ELPA")
  :init (add-to-list 'package-selected-packages 'standard-themes)
  :custom
    ;; Read the doc string of each of those user options.  These are some sample values.
    (standard-themes-bold-constructs t)
    (standard-themes-disable-other-themes t)
    (standard-themes-fringes 'subtle)   ;; Accepts a symbol value
    ;; more complex alist to set weight, height, and optional `variable-pitch' per heading level
    ;; (t is for any level not specified):
    (standard-themes-headings
      '((0                  . (variable-pitch light 1.9))
        (1                  . (variable-pitch light 1.8))
        (2                  . (variable-pitch light 1.7))
        (3                  . (variable-pitch semilight 1.6))
        (4                  . (variable-pitch semilight 1.5))
        (5                  . (variable-pitch 1.4))
        (6                  . (variable-pitch 1.3))
        (7                  . (variable-pitch 1.2))
        (agenda-date        . (1.3))
        (agenda-structure   . (variable-pitch light 1.8))
        (t                  . (variable-pitch 1.1))))
    (standard-themes-italic-constructs t)
    (standard-themes-links nil)         ;; lists of properties
    (standard-themes-mixed-fonts t)
    (standard-themes-mode-line-accented nil)
    (standard-themes-prompts '(bold italic))
    (standard-themes-region nil)        ;; lists of properties
    (standard-themes-variable-pitch-ui t)
    ;;:bind (
    ;;  ("<f5>" . #'standard-themes-toggle))
  :config
    ;; Load a theme that is consistent with my session's theme.    Those
    ;; functions are defined in my init.el.
    ;;(if (prot-emacs-theme-environment-dark-p)
    ;;    (standard-themes-load-dark)
    ;;  (standard-themes-load-light)))
    (standard-themes-load-dark))
;;; }}} *** standard-themes

;;; {{{ *** substitute
(use-package substitute
  :ensure (:source "GNU-devel ELPA")
  :init (add-to-list 'package-selected-packages 'substitute)
  :custom
    ;; Set this to t if you want to always treat the letter casing
    ;; literally.  Otherwise each command accepts a `C-u' prefix
    ;; argument to do this on-demand.
    (substitute-fixed-letter-case t)
    ;; Set this to nil if you do not like visual feedback on the matching
    ;; target.  Default is t.
    (substitute-highlight t)
  ;;:bind (
  ;;  ;; We do not bind any keys.  This is just an idea.  The mnemonic is
  ;;  ;; that M-# (or M-S-3) is close to M-% (or M-S-5).
  ;;  ("M-# b"    . #'substitute-target-in-buffer)
  ;;  ("M-# d"    . #'substitute-target-in-defun)
  ;;  ("M-# r"    . #'substitute-target-above-point)
  ;;  ("M-# s"    . #'substitute-target-below-point))
  :custom
    ;; If you want a message reporting the matches that changed in the
    ;; given context.  We don't do it by default.
    (add-hook 'substitute-post-replace-functions    #'substitute-report-operation))
;;; }}} *** substitute

;;; {{{ *** theme-buffet
(use-package theme-buffet
  :ensure (:source "GNU-devel ELPA")
  :after
    (catppuccin modus-themes ef-themes)    ;; add your favorite themes here
  :init (add-to-list 'package-selected-packages 'theme-buffet)
  :custom
    ;; variable below needs to be set when you just want to use the timers mins/hours
    (theme-buffet--end-user
      '(:night       (catppuccin modus-vivendi ef-dark ef-winter ef-autumn ef-night ef-duo-dark ef-symbiosis)
        :morning    (catppuccin modus-vivendi ef-dark ef-winter ef-autumn ef-night ef-duo-dark ef-symbiosis modus-operandi ef-light ef-cyprus ef-spring ef-frost ef-duo-light)
        :afternoon  (catppuccin modus-vivendi-tinted ef-rosa ef-elea-dark ef-maris-dark ef-melissa-dark ef-trio-dark modus-operandi-tinted ef-arbutus ef-day ef-kassio ef-summer ef-elea-light ef-maris-light ef-melissa-light ef-trio-light)
        :evening    (catppuccin modus-vivendi-tinted ef-rosa ef-elea-dark ef-maris-dark ef-melissa-dark ef-trio-dark)))
    (theme-buffet-menu 'end-user)     ;; 'modus-ef)
  :config
    ;;; one of the three below can be uncommented
    ;;(theme-buffet-modus-ef)
    ;;(theme-buffet-built-in)
    (theme-buffet-end-user)
    ;; two additional timers are available for theme change, both can be set
    (theme-buffet-timer-mins 25)    ;; change theme every 25m from now, similar below
    (theme-buffet-timer-hours 2)

    (theme-buffet-mode nil))
;;; }}} *** theme-buffet

;;; {{{ *** tmr
(use-package tmr
  :ensure (:source "GNU-devel ELPA")
  :init (add-to-list 'package-selected-packages 'tmr)
  ;; :bind (
  ;;   ;; Set global prefix bindings (autoloaded):
  ;;   ("\C-ct"    . 'tmr-prefix-map))
  :custom
    ;; Read the `tmr-descriptions-list' doc string
    (tmr-descriptions-list 'tmr-description-history)
    ;; Desktop notification urgency level
    (tmr-notification-urgency 'normal)
    ;; Set to nil to disable the sound
    (tmr-sound-file "/usr/local/share/sounds/freedesktop/stereo/alarm-clock-elapsed.oga"))
;;; }}} *** tmr
;;; }}} ** prot emacs packages

;;; {{{ ** ui
;;; {{{ *** ace-window
(use-package ace-window
  :init (add-to-list 'package-selected-packages 'ace-window)
  :custom
    (aw-background nil)
    (aw-dispatch-always t)
    (aw-keys '(?a ?s ?d ?f ?g ?h ?j ?k ?l))
    (aw-minibuffer-flag t)
    (aw-scope 'frame)
    (aw-ignore-current t)
  :bind (
    ("M-o"      . #'ace-window))
  :config
    (ace-window-display-mode t))
;;; }}} *** ace-window

;;; {{{ ** all-the-icons
(use-package all-the-icons
  :init (add-to-list 'package-selected-packages 'all-the-icons)
  :custom
    (all-the-icons-default-adjust    0.0)     ;; -0.2
    (all-the-icons-scale-factor      2.0)     ;;  1.2
  ;; :config
  ;;   (all-the-icons-install-fonts t)
)

(use-package all-the-icons-completion
  :init (add-to-list 'package-selected-packages 'all-the-icons-completion)
  :config
    (add-hook 'marginalia-mode-hook         #'all-the-icons-completion-marginalia-setup))

(use-package all-the-icons-dired
  :init (add-to-list 'package-selected-packages 'all-the-icons-dired)
  :config
    (add-hook 'dired-mode-hook          #'all-the-icons-dired-mode))

(use-package all-the-icons-ibuffer
  :init (add-to-list 'package-selected-packages 'all-the-icons-ibuffer)
    (all-the-icons-ibuffer-mode t)
  :custom
    ;; The default icon size in ibuffer.
    (all-the-icons-ibuffer-icon-size 1.0)
    ;; The default vertical adjustment of the icon in ibuffer.
    (all-the-icons-ibuffer-icon-v-adjust 0.0)
    ;; Use human readable file size in ibuffer.
    (all-the-icons-ibuffer-human-readable-size t)
    ;; Slow Rendering
    ;; If you experience a slow down in performance when rendering multiple icons simultaneously,
    ;; you can try setting the following variable
    (inhibit-compacting-font-caches t)
  :config
    ;; A list of ways to display buffer lines with `all-the-icons'.
    ;; See `ibuffer-formats' for details.
    ;; (describe-variable 'all-the-icons-ibuffer-formats)

    (add-hook 'ibuffer-mode-hook        #'all-the-icons-ibuffer-mode))

(use-package all-the-icons-nerd-fonts
  :after (all-the-icons)
  :init (add-to-list 'package-selected-packages 'all-the-icons-nerd-fonts)
  :config
    (all-the-icons-nerd-fonts-prefer))
;;; }}} ** all-the-icons

;;; {{{ ** avy
(use-package avy
  :init (add-to-list 'package-selected-packages 'avy)
  :config
    (avy-setup-default)
    (global-set-key (kbd "C-c C-j") 'avy-resume))
;;; }}} ** avy

;;; {{{ ** breadcrumb
(use-package breadcrumb
  :init (add-to-list 'package-selected-packages 'breadcrumb)
  :config
    (breadcrumb-mode t))
;;; }}} ** breadcrumb

;;; {{{ ** catppuccin-theme
(use-package catppuccin-theme
  :init (add-to-list 'package-selected-packages 'catppuccin-theme)
  :custom
    (catppuccin-flavor 'mocha) ;; pr 'frappe, 'latte, 'macchiato 'mocha
    (catppuccin-theme-italic-comments t)
    (catppuccin-theme-scale-header t)
    (catppuccin-theme-scale-outline t)
  :config
    (load-theme 'catppuccin))
;;; }}} ** catppuccin-theme

;;; {{{ *** dashboard
(use-package dashboard ;; :disabled
  :demand t
  :preface
    (defun +my/dashboard-banner ()
      """Set a dashboard banner including information on package initialization
      time and garbage collections."""
      (setq dashboard-banner-logo-title
        (format "Welcome to Emacs\nEmacs ready in %.2f seconds with %d garbage collections."
                (float-time (time-subtract after-init-time before-init-time)) gcs-done)))
  :init (add-to-list 'package-selected-packages 'dashboard)
    (add-hook 'elpaca-after-init-hook           #'dashboard-refresh-buffer)
    (add-hook 'dashboard-mode-hook              #'+my/dashboard-banner)
  :custom
    (dashboard-banner-logo-title "Welcome to Emacs")
    (dashboard-center-content t)
    (dashboard-display-icons-p t)
    (dashboard-filter-agenda-entry 'dashboard-no-filter-agenda)
    (dashboard-force-refresh t)
    (dashboard-icon-type 'nerd-icons)
    (dashboard-item-names '(("Agenda for today:"            . "Today's Agenda:")
                            ("Agenda for the coming week:"  . "Week's Agenda:")))
    (dashboard-items '((recents   . 10)
                       (bookmarks . 10)
                       (projects  . 5)
                       (agenda    . 5)
                       (registers . 10)))
    (dashboard-modify-heading-icons '((recents    . "nf-oct-file_text")
                                      (bookmarks  . "nf-oct-book")))
    (dashboard-navigation-cycle t)
    (dashboard-path-shorten-string "…")
    (dashboard-remove-missing-entry t)
    (dashboard-set-heading-icons t)
    (dashboard-set-file-icons t)
    (dashboard-set-navigator t)
    (dashboard-vertically-center-content t)
    (dashboard-week-agenda t)

    (dashboard-startup-banner
      (list
        'ascii
        'logo
        'official
        1 2 3 4 5 6 7 8 9 10
        (no-littering-expand-etc-file-name "emacs-logos/thumb/Breezeicons-apps-48-emacs.svgthumb.png")
        (no-littering-expand-etc-file-name "emacs-logos/thumb/cacodemonthumb.png")
        (no-littering-expand-etc-file-name "emacs-logos/thumb/dragonthumb.png")
        (no-littering-expand-etc-file-name "emacs-logos/thumb/elrumo1thumb.png")
        (no-littering-expand-etc-file-name "emacs-logos/thumb/elrumo2thumb.png")
        (no-littering-expand-etc-file-name "emacs-logos/thumb/emacs-card-blue-deepthumb.png")
        (no-littering-expand-etc-file-name "emacs-logos/thumb/emacs-card-british-racing-greenthumb.png")
        (no-littering-expand-etc-file-name "emacs-logos/thumb/emacs-card-carminethumb.png")
        (no-littering-expand-etc-file-name "emacs-logos/thumb/emacs-card-greenthumb.png")
        (no-littering-expand-etc-file-name "emacs-logos/thumb/emacs-plusthumb.png")
        (no-littering-expand-etc-file-name "emacs-logos/thumb/emacs-seeklogothumb.svg")
        (no-littering-expand-etc-file-name "emacs-logos/thumb/EmacsIcon1thumb.png")
        (no-littering-expand-etc-file-name "emacs-logos/thumb/EmacsIcon2thumb.png")
        (no-littering-expand-etc-file-name "emacs-logos/thumb/EmacsIcon3thumb.png")
        (no-littering-expand-etc-file-name "emacs-logos/thumb/EmacsIcon4thumb.png")
        (no-littering-expand-etc-file-name "emacs-logos/thumb/EmacsIcon5thumb.png")
        (no-littering-expand-etc-file-name "emacs-logos/thumb/EmacsIcon6thumb.png")
        (no-littering-expand-etc-file-name "emacs-logos/thumb/EmacsIcon7thumb.png")
        (no-littering-expand-etc-file-name "emacs-logos/thumb/EmacsIcon8thumb.png")
        (no-littering-expand-etc-file-name "emacs-logos/thumb/EmacsIcon9thumb.png")
        (no-littering-expand-etc-file-name "emacs-logos/thumb/gnu-headthumb.png")
        (no-littering-expand-etc-file-name "emacs-logos/thumb/gnu_colorthumb.png")
        (no-littering-expand-etc-file-name "emacs-logos/thumb/gnu_colorthumb.svg")
        (no-littering-expand-etc-file-name "emacs-logos/thumb/memeplex-slimthumb.png")
        (no-littering-expand-etc-file-name "emacs-logos/thumb/memeplex-widethumb.png")
        (no-littering-expand-etc-file-name "emacs-logos/thumb/modern-alecive-flatwokenthumb.png")
        (no-littering-expand-etc-file-name "emacs-logos/thumb/modern-asingh4242thumb.png")
        (no-littering-expand-etc-file-name "emacs-logos/thumb/modern-azhilinthumb.png")
        (no-littering-expand-etc-file-name "emacs-logos/thumb/modern-bananxanthumb.png")
        (no-littering-expand-etc-file-name "emacs-logos/thumb/modern-black-dragonthumb.png")
        (no-littering-expand-etc-file-name "emacs-logos/thumb/modern-black-gnu-headthumb.png")
        (no-littering-expand-etc-file-name "emacs-logos/thumb/modern-black-variantthumb.png")
        (no-littering-expand-etc-file-name "emacs-logos/thumb/modern-bokehlicia-captivathumb.png")
        (no-littering-expand-etc-file-name "emacs-logos/thumb/modern-cg433nthumb.png")
        (no-littering-expand-etc-file-name "emacs-logos/thumb/modern-doomthumb.png")
        (no-littering-expand-etc-file-name "emacs-logos/thumb/modern-doom3thumb.png")
        (no-littering-expand-etc-file-name "emacs-logos/thumb/modern-mzaplotnikthumb.png")
        (no-littering-expand-etc-file-name "emacs-logos/thumb/modern-nuvolathumb.png")
        (no-littering-expand-etc-file-name "emacs-logos/thumb/modern-orangethumb.png")
        (no-littering-expand-etc-file-name "emacs-logos/thumb/modern-paperthumb.png")
        (no-littering-expand-etc-file-name "emacs-logos/thumb/modern-papirusthumb.png")
        (no-littering-expand-etc-file-name "emacs-logos/thumb/modern-pen-3dthumb.png")
        (no-littering-expand-etc-file-name "emacs-logos/thumb/modern-pen-blackthumb.png")
        (no-littering-expand-etc-file-name "emacs-logos/thumb/modern-pen-lds56thumb.png")
        (no-littering-expand-etc-file-name "emacs-logos/thumb/modern-penthumb.png")
        (no-littering-expand-etc-file-name "emacs-logos/thumb/modern-purple-flatthumb.png")
        (no-littering-expand-etc-file-name "emacs-logos/thumb/modern-sexy-v1thumb.png")
        (no-littering-expand-etc-file-name "emacs-logos/thumb/modern-sexy-v2thumb.png")
        (no-littering-expand-etc-file-name "emacs-logos/thumb/modern-sjrmanningthumb.png")
        (no-littering-expand-etc-file-name "emacs-logos/thumb/modern-vscodethumb.png")
        (no-littering-expand-etc-file-name "emacs-logos/thumb/modern-yellowthumb.png")
        (no-littering-expand-etc-file-name "emacs-logos/thumb/modernthumb.png")
        (no-littering-expand-etc-file-name "emacs-logos/thumb/nobu417-big-surthumb.png")
        (no-littering-expand-etc-file-name "emacs-logos/thumb/retro-emacs-logothumb.png")
        (no-littering-expand-etc-file-name "emacs-logos/thumb/retro-gnu-meditate-levitatethumb.png")
        (no-littering-expand-etc-file-name "emacs-logos/thumb/retro-sink-bwthumb.png")
        (no-littering-expand-etc-file-name "emacs-logos/thumb/retro-sinkthumb.png")
        (no-littering-expand-etc-file-name "emacs-logos/thumb/savchenkovaleriy-big-sur-3dthumb.png")
        (no-littering-expand-etc-file-name "emacs-logos/thumb/savchenkovaleriy-big-sur-curvy-3dthumb.png")
        (no-littering-expand-etc-file-name "emacs-logos/thumb/savchenkovaleriy-big-surthumb.png")
        (no-littering-expand-etc-file-name "emacs-logos/thumb/skamacsthumb.png")
        (no-littering-expand-etc-file-name "emacs-logos/thumb/spacemacsthumb.png")))
    (dashboard-startupify-list  '(dashboard-insert-banner
                                  dashboard-insert-newline
                                  dashboard-insert-banner-title
                                  dashboard-insert-newline
                                  dashboard-insert-navigator
                                  dashboard-insert-newline
                                  dashboard-insert-init-info
                                  dashboard-insert-items
                                  dashboard-insert-newline
                                  dashboard-insert-footer))
    (initial-buffer-choice (lambda () (get-buffer-create dashboard-buffer-name)))
  :config
    ;; (dashboard-open)
    ;; (dashboard-refresh-buffer)
    ;; (dashboard-insert-startupify-lists)
    ;; (dashboard-setup-startup-hook)
    (add-hook 'elpaca-after-init-hook           #'dashboard-initialize)
    (add-hook 'elpaca-after-init-hook           #'dashboard-insert-startupify-lists))
;;; }}} *** dashboard

;;; {{{ *** dired
(use-package dired-hacks-utils :init (add-to-list 'package-selected-packages 'dired-hacks-utils))
(use-package dired-avfs :init (add-to-list 'package-selected-packages 'dired-avfs))
(use-package dired-collapse :init (add-to-list 'package-selected-packages 'dired-collapse))

;;; {{{ ***** dired-filter
(use-package dired-filter
  :init (add-to-list 'package-selected-packages 'dired-filter)
  :custom
    (dired-filter-group-saved-groups
      '(("default"
          ("Archives"
            (extension "bz2" "gz" "rar" "tar" "zip"))
          ("Image"
            (extension "bmp" "gif" "jpeg" "jpg" "png" "svg"))
          ("LaTeX"
            (extension "bib" "tex"))
          ("Media"
            (extension "avi" "flv" "mp3" "mp4" "mpg" "ogg"))
          ("Org"
            (extension . "org"))
          ("PDF"
            (extension . "pdf"))))))
;;; }}} ***** dired-filter

(use-package dired-list :init (add-to-list 'package-selected-packages 'dired-list))
(use-package dired-narrow :init (add-to-list 'package-selected-packages 'dired-narrow))
(use-package dired-open :init (add-to-list 'package-selected-packages 'dired-open))

;;; {{{ ***** dired-rainbow
(use-package dired-rainbow
  :init (add-to-list 'package-selected-packages 'dired-rainbow)
  :config
    (progn
      (dired-rainbow-define compiled              "#4dc0b5" ("asm" "cl" "lisp" "el" "c" "h" "c++" "h++" "hpp" "hxx" "m" "cc" "cs" "cp" "cpp" "go" "f" "for" "ftn" "f90" "f95" "f03" "f08" "s" "rs" "hi" "hs" "pyc" ".java"))
      (dired-rainbow-define compressed            "#51d88a" ("7z" "zip" "bz2" "tgz" "txz" "gz" "xz" "z" "Z" "jar" "war" "ear" "rar" "sar" "xpi" "apk" "xz" "tar"))
      (dired-rainbow-define database              "#6574cd" ("xlsx" "xls" "csv" "accdb" "db" "mdb" "sqlite" "nc"))
      (dired-rainbow-define document              "#9561e2" ("docm" "doc" "docx" "odb" "odt" "pdb" "pdf" "ps" "rtf" "djvu" "epub" "odp" "ppt" "pptx"))
      (dired-rainbow-define encrypted             "#ffed4a" ("gpg" "pgp" "asc" "bfe" "enc" "signature" "sig" "p12" "pem"))
      (dired-rainbow-define executable            "#8cc4ff" ("exe" "msi"))
      (dired-rainbow-define fonts                 "#6cb2eb" ("afm" "fon" "fnt" "pfb" "pfm" "ttf" "otf"))
      (dired-rainbow-define html                  "#eb5286" ("css" "less" "sass" "scss" "htm" "html" "jhtm" "mht" "eml" "mustache" "xhtml"))
      (dired-rainbow-define image                 "#f66d9b" ("tiff" "tif" "cdr" "gif" "ico" "jpeg" "jpg" "png" "psd" "eps" "svg"))
      (dired-rainbow-define interpreted           "#38c172" ("py" "ipynb" "rb" "pl" "t" "msql" "mysql" "pgsql" "sql" "r" "clj" "cljs" "scala" "js"))
      (dired-rainbow-define log                   "#c17d11" ("log"))
      (dired-rainbow-define markdown              "#ffed4a" ("org" "etx" "info" "markdown" "md" "mkd" "nfo" "pod" "rst" "tex" "textfile" "txt"))
      (dired-rainbow-define media                 "#de751f" ("mp3" "mp4" "MP3" "MP4" "avi" "mpeg" "mpg" "flv" "ogg" "mov" "mid" "midi" "wav" "aiff" "flac"))
      (dired-rainbow-define packaged              "#faad63" ("deb" "rpm" "apk" "jad" "jar" "cab" "pak" "pk3" "vdf" "vpk" "bsp"))
      (dired-rainbow-define partition             "#e3342f" ("dmg" "iso" "bin" "nrg" "qcow" "toast" "vcd" "vmdk" "bak"))
      (dired-rainbow-define shell                 "#f6993f" ("awk" "bash" "bat" "sed" "sh" "zsh" "vim"))
      (dired-rainbow-define vc                    "#0074d9" ("git" "gitignore" "gitattributes" "gitmodules"))
      (dired-rainbow-define xml                   "#f2d024" ("xml" "xsd" "xsl" "xslt" "wsdl" "bib" "json" "msg" "pgn" "rss" "yaml" "yml" "rdata"))
      (dired-rainbow-define-chmod directory       "#6cb2eb" "d.*")
      (dired-rainbow-define-chmod executable-unix "#38c172" "-.*x.*")))
;;; }}} ***** dired-rainbow

(use-package dired-ranger :init (add-to-list 'package-selected-packages 'dired-ranger))
(use-package dired-subtree :init (add-to-list 'package-selected-packages 'dired-subtree))
;;; }}} **** dired-hacks-utils

;;; {{{ **** dired-hide-dotfiles
(use-package dired-hide-dotfiles
  :init (add-to-list 'package-selected-packages 'dired-hide-dotfiles)
  :bind (
    :map dired-mode-map
    ("."    . dired-hide-dotfiles-mode))
  :config
    (add-hook 'dired-mode-hook              #'dired-hide-dotfiles-mode))
;;; }}} **** dired-hide-dotfiles

;;; {{{ **** dired-quick-sort
(use-package dired-quick-sort
  :init (add-to-list 'package-selected-packages 'dired-quick-sort)
  :custom
    (dired-quick-sort-suppress-setup-warning t)
  :config
    (dired-quick-sort-setup))
;;; }}} **** dired-quick-sort

;;; {{{ **** diredfl
(use-package diredfl
  :init (add-to-list 'package-selected-packages 'diredfl)
  :config
    (diredfl-global-mode t))
;;; }}} **** diredfl

;;; {{{ **** dirvish
(use-package dirvish
  ;; :disabled
  :init (add-to-list 'package-selected-packages 'dirvish)
    (dirvish-override-dired-mode t)
  :custom
    (delete-by-moving-to-trash t)
    (dired-listing-switches "-l --almost-all --human-readable --group-directories-first --no-group")
    (dirvish-attributes '(nerd-icons file-time file-size collapse subtree-state vc-state git-msg))
    (dirvish-mode-line-format '(:left (sort symlink) :right (omit yank index)))
    (dirvish-mode-line-height 10)
    (dirvish-path-separators
      (list (format "    %s "   (nerd-icons-codicon "nf-cod-home"))
            (format "    %s "   (nerd-icons-codicon "nf-cod-root_folder"))
            (format " %s "      (nerd-icons-faicon "nf-fa-angle_right"))))
    (dirvish-subtree-state-style 'nerd)
  :config
    (dirvish-side-follow-mode t)     ;; similar to `treemacs-follow-mode'
    (dirvish-peek-mode t))           ;; Preview files in minibuffer
;;; }}} **** dirvish
;;; }}} *** dired

;;; {{{ *** doom-dashboard
;;; {{{ **** doom-dashboard [emacs-dashboard]
(use-package doom-dashboard :disabled
  :ensure (doom-dashboard :host github :repo "emacs-dashboard/doom-dashboard")
  :after dashboard
  :demand t
  ;; Movement keys like doom.
  :init (add-to-list 'package-selected-packages 'doom-dashboard)
  :bind (
    :map dashboard-mode-map
      ("<remap> <dashboard-next-line>"      . widget-forward)
      ("<remap> <dashboard-previous-line>"  . widget-backward)
      ("<remap> <left-char>"                . widget-backward)
      ("<remap> <next-line>"                . widget-forward)
      ("<remap> <previous-line>"            . widget-backward)
      ("<remap> <right-char>"               . widget-forward))
  :custom
    (dashboard-banner-logo-title "E M A C S")
    (dashboard-footer-icon (nerd-icons-faicon "nf-fa-github_alt" :face 'success :height 1.5))
    (dashboard-item-generators
      '((agenda    . doom-dashboard-insert-org-agenda-shortmenu)
        (bookmarks . doom-dashboard-insert-bookmark-shortmenu)
        (projects  . doom-dashboard-insert-project-shortmenu)
        (recents   . doom-dashboard-insert-recents-shortmenu)))
    (dashboard-items '(projects agenda bookmarks recents registers))
    (dashboard-page-separator "\n")
    (dashboard-startup-banner (add-to-list 'dashboard-startup-banner (concat doom-dashboard-banner-directory "bcc.txt")))
    (dashboard-startupify-list  `(dashboard-insert-banner
                                  dashboard-insert-banner-title
                                  dashboard-insert-newline
                                  dashboard-insert-navigator
                                  dashboard-insert-items
                                  ,(dashboard-insert-newline 2)
                                  dashboard-insert-init-info
                                  ,(dashboard-insert-newline 2)
                                  doom-dashboard-insert-homepage-footer))

    (doom-dashboard-banner-directory (no-littering-expand-etc-file-name "emacs-logos"))
    (doom-dashboard-banner-file (no-littering-expand-etc-file-name "emacs-logos/thumb/emacs-seeklogothumb.svg"))
    (doom-dashboard-banner-height 100)
    (doom-dashboard-banner-padding 4)
    (doom-dashboard-banner-resize 'frame)
    (doom-dashboard-center-content t)
    (doom-dashboard-footer-messages '("Happy hacking, %s!"))
    (doom-dashboard-menu-max-width 30)
    (doom-dashboard-menu-sections
      '(("Reload last session"
         :icon (all-the-icons-octicon "history" :face 'doom-dashboard-menu-title)
         :when (cond ((require 'persp-mode nil t) (file-exists-p (expand-file-name persp-auto-save-fname persp-save-dir)))
                     ((require 'desktop nil t) (file-exists-p (desktop-full-file-name))))
         :action doom/quickload-session)
        ("Recently opened files"
         :icon (all-the-icons-octicon "file-text" :face 'doom-dashboard-menu-title)
         :action recentf-open-files)
        ("Open project"
         :icon (all-the-icons-octicon "briefcase" :face 'doom-dashboard-menu-title)
         :action projectile-switch-project)
        ("Jump to bookmark"
         :icon (all-the-icons-octicon "bookmark" :face 'doom-dashboard-menu-title)
         :action bookmark-jump)
        ("Open agenda"
         :icon (all-the-icons-octicon "calendar" :face 'doom-dashboard-menu-title)
         :action org-agenda)
        ("Open documentation"
         :icon (all-the-icons-octicon "book" :face 'doom-dashboard-menu-title)
         :action doom/open-docs)
        ("Find file"
         :icon (all-the-icons-octicon "search" :face 'doom-dashboard-menu-title)
         :action find-file)
        ("Recent projects"
         :icon (all-the-icons-octicon "file-directory" :face 'doom-dashboard-menu-title)
         :action projectile-switch-project)
        ("Switch to scratch buffer"
         :icon (all-the-icons-octicon "pencil" :face 'doom-dashboard-menu-title)
         :action doom/open)
        ("Open private configuration"
          :icon (all-the-icons-octicon "tools" :face 'doom-dashboard-menu-title)
          :action doom/open-private-config)))
    (doom-dashboard-set-file-icons t)
    (doom-dashboard-set-footer t)
    (doom-dashboard-set-heading-icons t)
    (doom-dashboard-set-init-info t)
    (doom-dashboard-set-navigator t)
  :config
    ;; (doom-dashboard-setup)
    (doom-dashboard-refresh
      :async t
      :load-path doom-dashboard-banner-directory)
    (doom-dashboard-reload)
    (doom-dashboard-mode t)
  :hook
    (dashboard-mode-hook  . doom-dashboard-reload))
;;; }}} *** doom-dashboard [emacs-dashboard]

;;; {{{ *** doom-modeline
(use-package doom-modeline
  ;; :disabled
  :init (add-to-list 'package-selected-packages 'doom-modeline)
    (doom-modeline-mode t)

  :custom
    ;; If non-nil, cause imenu to see `doom-modeline' declarations.
    ;; This is done by adjusting `lisp-imenu-generic-expression' to
    ;; include support for finding `doom-modeline-def-*' forms.
    ;; Must be set before loading doom-modeline.
    (doom-modeline-support-imenu t)

    ;; How tall the mode-line should be. It's only respected in GUI.
    ;; If the actual char height is larger, it respects the actual height.
    (doom-modeline-height 1)    ;; 25)

    ;; How wide the mode-line bar should be. It's only respected in GUI.
    (doom-modeline-bar-width 4)

    ;; Whether to use hud instead of default bar. It's only respected in GUI.
    (doom-modeline-hud nil)

    ;; The limit of the window width.
    ;; If `window-width' is smaller than the limit, some information won't be
    ;; displayed. It can be an integer or a float number. `nil' means no limit."
    (doom-modeline-window-width-limit 85)

    ;; How to detect the project root.
    ;; nil means to use `default-directory'.
    ;; The project management packages have some issues on detecting project root.
    ;; e.g. `projectile' doesn't handle symlink folders well, while `project' is unable
    ;; to hanle sub-projects.
    ;; You can specify one if you encounter the issue.
    (doom-modeline-project-detection 'project)  ;; 'auto)

    ;; Determines the style used by `doom-modeline-buffer-file-name'.
    ;;
    ;; Given ~/Projects/FOSS/emacs/lisp/comint.el
    ;;   auto => emacs/l/comint.el (in a project) or comint.el
    ;;   truncate-upto-project => ~/P/F/emacs/lisp/comint.el
    ;;   truncate-from-project => ~/Projects/FOSS/emacs/l/comint.el
    ;;   truncate-with-project => emacs/l/comint.el
    ;;   truncate-except-project => ~/P/F/emacs/l/comint.el
    ;;   truncate-upto-root => ~/P/F/e/lisp/comint.el
    ;;   truncate-all => ~/P/F/e/l/comint.el
    ;;   truncate-nil => ~/Projects/FOSS/emacs/lisp/comint.el
    ;;   relative-from-project => emacs/lisp/comint.el
    ;;   relative-to-project => lisp/comint.el
    ;;   file-name => comint.el
    ;;   file-name-with-project => FOSS|comint.el
    ;;   buffer-name => comint.el<2> (uniquify buffer name)
    ;;
    ;; If you are experiencing the laggy issue, especially while editing remote files
    ;; with tramp, please try `file-name' style.
    ;; Please refer to https://github.com/bbatsov/projectile/issues/657.
    (doom-modeline-buffer-file-name-style 'auto)

    ;; Whether display icons in the mode-line.
    ;; While using the server mode in GUI, should set the value explicitly.
    (doom-modeline-icon t)

    ;; Whether display the icon for `major-mode'. It respects option `doom-modeline-icon'.
    (doom-modeline-major-mode-icon t)

    ;; Whether display the colorful icon for `major-mode'.
    ;; It respects `nerd-icons-color-icons'.
    (doom-modeline-major-mode-color-icon t)

    ;; Whether display the icon for the buffer state. It respects option `doom-modeline-icon'.
    (doom-modeline-buffer-state-icon t)

    ;; Whether display the modification icon for the buffer.
    ;; It respects option `doom-modeline-icon' and option `doom-modeline-buffer-state-icon'.
    (doom-modeline-buffer-modification-icon t)

    ;; Whether display the lsp icon. It respects option `doom-modeline-icon'.
    (doom-modeline-lsp-icon t)

    ;; Whether display the time icon. It respects option `doom-modeline-icon'.
    (doom-modeline-time-icon t)

    ;; Whether display the live icons of time.
    ;; It respects option `doom-modeline-icon' and option `doom-modeline-time-icon'.
    (doom-modeline-time-live-icon t)

    ;; Whether to use an analogue clock svg as the live time icon.
    ;; It respects options `doom-modeline-icon', `doom-modeline-time-icon', and `doom-modeline-time-live-icon'.
    (doom-modeline-time-analogue-clock nil)

    ;; The scaling factor used when drawing the analogue clock.
    (doom-modeline-time-clock-size 0.7)

    ;; Whether to use unicode as a fallback (instead of ASCII) when not using icons.
    (doom-modeline-unicode-fallback t)  ;; nil)

    ;; Whether display the buffer name.
    (doom-modeline-buffer-name t)

    ;; Whether highlight the modified buffer name.
    (doom-modeline-highlight-modified-buffer-name t)

    ;; When non-nil, mode line displays column numbers zero-based.
    ;; See `column-number-indicator-zero-based'.
    (doom-modeline-column-zero-based t)

    ;; Specification of \"percentage offset\" of window through buffer.
    ;; See `mode-line-percent-position'.
    (doom-modeline-percent-position '(-3 "%p"))

    ;; Format used to display line numbers in the mode line.
    ;; See `mode-line-position-line-format'.
    (doom-modeline-position-line-format '("L%l"))

    ;; Format used to display column numbers in the mode line.
    ;; See `mode-line-position-column-format'.
    (doom-modeline-position-column-format '("C%c"))

    ;; Format used to display combined line/column numbers in the mode line. See `mode-line-position-column-line-format'.
    (doom-modeline-position-column-line-format '("%l:%c"))

    ;; Whether display the minor modes in the mode-line.
    (doom-modeline-minor-modes nil)

    ;; If non-nil, a word count will be added to the selection-info modeline segment.
    (doom-modeline-enable-word-count t) ;; nil)

    ;; Major modes in which to display word count continuously.
    ;; Also applies to any derived modes. Respects `doom-modeline-enable-word-count'.
    ;; If it brings the sluggish issue, disable `doom-modeline-enable-word-count' or
    ;; remove the modes from `doom-modeline-continuous-word-count-modes'.
    (doom-modeline-continuous-word-count-modes '(markdown-mode gfm-mode org-mode))

    ;; Whether display the buffer encoding.
    (doom-modeline-buffer-encoding t)

    ;; Whether display the indentation information.
    (doom-modeline-indent-info nil)

    ;; Whether display the total line number。
    (doom-modeline-total-line-number t) ;; nil)

    ;; Whether display the icon of vcs segment. It respects option `doom-modeline-icon'."
    (doom-modeline-vcs-icon t)

    ;; Whether display the icon of check segment. It respects option `doom-modeline-icon'.
    (doom-modeline-check-icon t)

    ;; If non-nil, only display one number for check information if applicable.
    (doom-modeline-check-simple-format nil)

    ;; The maximum number displayed for notifications.
    (doom-modeline-number-limit 99)

    ;; The maximum displayed length of the branch name of version control.
    (doom-modeline-vcs-max-length 12)

    ;; Whether display the workspace name. Non-nil to display in the mode-line.
    (doom-modeline-workspace-name t)

    ;; Whether display the perspective name. Non-nil to display in the mode-line.
    (doom-modeline-persp-name t)

    ;; If non nil the default perspective name is displayed in the mode-line.
    (doom-modeline-display-default-persp-name nil)

    ;; If non nil the perspective name is displayed alongside a folder icon.
    (doom-modeline-persp-icon t)

    ;; Whether display the `lsp' state. Non-nil to display in the mode-line.
    (doom-modeline-lsp t)

    ;; Whether display the GitHub notifications. It requires `ghub' package.
    (doom-modeline-github t)    ;; nil)

    ;; The interval of checking GitHub.
    (doom-modeline-github-interval (* 30 60))

    ;; Whether display the modal state.
    ;; Including `evil', `overwrite', `god', `ryo' and `xah-fly-keys', etc.
    (doom-modeline-modal t)

    ;; Whether display the modal state icon.
    ;; Including `evil', `overwrite', `god', `ryo' and `xah-fly-keys', etc.
    (doom-modeline-modal-icon t)

    ;; Whether display the modern icons for modals.
    (doom-modeline-modal-modern-icon t)

    ;; When non-nil, always show the register name when recording an evil macro.
    (doom-modeline-always-show-macro-register nil)

    ;; Whether display the mu4e notifications. It requires `mu4e-alert' package.
    (doom-modeline-mu4e nil)
    ;; also enable the start of mu4e-alert
    (mu4e-alert-enable-mode-line-display)

    ;; Whether display the gnus notifications.
    (doom-modeline-gnus t)

    ;; Whether gnus should automatically be updated and how often (set to 0 or smaller than 0 to disable)
    (doom-modeline-gnus-timer 2)

    ;; Wheter groups should be excludede when gnus automatically being updated.
    (doom-modeline-gnus-excluded-groups '("dummy.group"))

    ;; Whether display the IRC notifications. It requires `circe' or `erc' package.
    (doom-modeline-irc t)

    ;; Function to stylize the irc buffer names.
    (doom-modeline-irc-stylize 'identity)

    ;; Whether display the battery status. It respects `display-battery-mode'.
    (doom-modeline-battery t)

    ;; Whether display the time. It respects `display-time-mode'.
    (doom-modeline-time t)

    ;; Whether display the misc segment on all mode lines.
    ;; If nil, display only if the mode line is active.
    (doom-modeline-display-misc-in-all-mode-lines t)

    ;; The function to handle `buffer-file-name'.
    (doom-modeline-buffer-file-name-function #'identity)

    ;; The function to handle `buffer-file-truename'.
    (doom-modeline-buffer-file-truename-function #'identity)

    ;; Whether display the environment version.
    (doom-modeline-env-version t)
    ;; Or for individual languages
    (doom-modeline-env-enable-elixir t)
    (doom-modeline-env-enable-go t)
    (doom-modeline-env-enable-perl t)
    (doom-modeline-env-enable-python t)
    (doom-modeline-env-enable-ruby t)
    (doom-modeline-env-enable-rust t)

    ;; Change the executables to use for the language version string
    (doom-modeline-env-elixir-executable "iex")
    (doom-modeline-env-go-executable "go")
    (doom-modeline-env-perl-executable "perl")
    (doom-modeline-env-python-executable "python") ; or `python-shell-interpreter'
    (doom-modeline-env-ruby-executable "ruby")
    (doom-modeline-env-rust-executable "rustc")

    ;; What to display as the version while a new one is being loaded
    (doom-modeline-env-load-string "...")

    ;; By default, almost all segments are displayed only in the active window. To
    ;; display such segments in all windows, specify e.g.
    (doom-modeline-always-visible-segments '(mu4e irc))

    ;; Hooks that run before/after the modeline version string is updated
    (doom-modeline-before-update-env-hook nil)
    (doom-modeline-after-update-env-hook nil)
  :config
    (column-number-mode t)
    (doom-modeline-mode t))
;;; }}} *** doom-modeline

;;; {{{ *** doom-themes
(use-package doom-themes   :init (add-to-list 'package-selected-packages 'doom-themes))
;;; }}} *** doom-themes

;;; {{{ *** elpher
(use-package elpher
  :after (eww)
  :init (add-to-list 'package-selected-packages 'elpher)
  :config
    (defun +my/elpher:eww-browse-url (original url &optional new-window)
      "Handle gemini links."
      (cond (
          (string-match-p "\\`\\(gemini\\|gopher\\)://" url)
            (require 'elpher)
            (elpher-go url))
          (t
            (funcall original url new-window))))
    (advice-add 'eww-browse-url :around #'+my/elpher:eww-browse-url))
;;; }}} *** elpher

;;; {{{ *** ergoemacs-mode
(use-package ergoemacs-mode
  :init (add-to-list 'package-selected-packages 'ergoemacs-mode)
  :custom
    (ergoemacs-layout "gb")
    (ergoemacs-theme nil)
  :config
    (ergoemacs-mode -1))
;;; }}} *** ergoemacs-mode

;;; {{{ *** fireplace
(use-package fireplace
  :init (add-to-list 'package-selected-packages 'fireplace)
  :custom
    (fireplace-default-to-insert-state t)
  :config
    (fireplace-mode t))
;;; }}} *** fireplace

;;; {{{ *** fortune-cookie
(use-package fortune-cookie
  :init (add-to-list 'package-selected-packages 'fortune-cookie)
  :custom
    (fortune-cookie-cowsay-args  "-f tux -s")
  :config
    (fortune-cookie-mode t))
;;; }}} *** fortune-cookie

;;; {{{ *** golden-ratio
(use-package golden-ratio
  :init (add-to-list 'package-selected-packages 'golden-ratio)
  :custom
    (golden-ratio-auto-scale t)
    (golden-ratio-exclude-modes
      '(calendar-mode
        ediff-mode
        help-mode))
    (golden-ratio-max-width 120)
  :config
    (golden-ratio-mode t))
;;; }}} *** golden-ratio

;;; {{{ *** greader
(use-package greader
  :init (add-to-list 'package-selected-packages 'greader)
  :config
    (greader-mode t))
;;; }}} *** greader

;;; {{{ *** helpful
;; [[https://github.com/Wilfred/helpful][Helpful] is an alternative to the built-in Emacs help that provides much more contextual information.
;; Make `describe-*' screens more helpful
(use-package helpful
  :demand t
  :init (add-to-list 'package-selected-packages 'helpful)
  :bind (
    ([remap describe-command]   . helpful-command)
    ([remap describe-function]  . helpful-callable)
    ([remap describe-key]       . helpful-key)
    ([remap describe-symbol]    . helpful-symbol)
    ([remap describe-variable]  . helpful-variable)
    ("C-h F"                    . helpful-function)
    ("C-h K"                    . describe-keymap)
    :map helpful-mode-map
      ([remap revert-buffer]    . helpful-update)))
;;; }}} *** Helpful

;;; {{{ *** keycast
(use-package keycast
  :init (add-to-list 'package-selected-packages 'keycast)
  :custom
    (keycast-mode-line-insert-after 'mode-line-misc-info)
    (keycast-mode-line-remove-tail-elements nil)
  :config
    (keycast-mode-line-mode t))
;;; }}} *** keycast

(use-package mpv) :init (add-to-list 'package-selected-packages 'mpv)

;;; {{{ *** nerd icons
(use-package nerd-icons
  :init (add-to-list 'package-selected-packages 'nerd-icons)
  :custom
    (nerd-icons-color-icons t)
    ;; The Nerd Font you want to use in GUI
    ;; "Symbols Nerd Font Mono" is the default and is recommended
    ;; but you can use any other Nerd Font if you want
    (nerd-icons-font-family "Symbols Nerd Font Regular")
    (nerd-icons-scale-factor 1.1)
  ;; :config
  ;;   (nerd-icons-install-fonts t)
)

(use-package nerd-icons-completion
  :after (nerd-icons)
  :init (add-to-list 'package-selected-packages 'nerd-icons-completion)
  :config
    (nerd-icons-completion-mode t))

(use-package nerd-icons-corfu
  :after (nerd-icons corfu)
  :init (add-to-list 'package-selected-packages 'nerd-icons-corfu)
  :custom
    (nerd-icons-corfu-mapping
      '((array :style "cod" :icon "symbol_array" :face font-lock-type-face)
        (boolean :style "cod" :icon "symbol_boolean" :face font-lock-builtin-face)
        (t :style "cod" :icon "code" :face font-lock-warning-face)))
  :config
    (add-to-list 'corfu-margin-formatters #'nerd-icons-corfu-formatter))

(use-package nerd-icons-dired
  :after (nerd-icons)
  :init (add-to-list 'package-selected-packages 'nerd-icons-dired)
  :config
    (add-hook 'dired-mode-hook          #'nerd-icons-dired-mode))

(use-package nerd-icons-ibuffer
  :after (nerd-icons)
  :init (add-to-list 'package-selected-packages 'nerd-icons-ibuffer)
  :custom
    ;; Whether display the colorful icons.
    ;; It respects `nerd-icons-color-icons'.
    (nerd-icons-ibuffer-color-icon t)
    ;; Use human readable file size in ibuffer.
    (nerd-icons-ibuffer-human-readable-size t)
    ;; Whether display the icons.
    (nerd-icons-ibuffer-icon t)
    ;; The default icon size in ibuffer.
    (nerd-icons-ibuffer-icon-size 1.0)
  :config
    ;; A list of ways to display buffer lines with `nerd-icons'.
    ;; See `ibuffer-formats' for details.
    ;; (describe-variable 'nerd-icons-ibuffer-formats)

    (add-hook 'ibuffer-mode-hook        #'nerd-icons-ibuffer-mode))
;;; }}} *** nerd icons

;;; {{{ *** notmuch
(use-package notmuch)  :init (add-to-list 'package-selected-packages 'notmuch)

(use-package consult-notmuch
  :after (consult notmuch)
  :init (add-to-list 'package-selected-packages 'consult-notmuch))

(use-package ol-notmuch
  :after (notmuch)
  :init (add-to-list 'package-selected-packages 'ol-notmuch))
;;; }}} notmuch

;;; {{{ *** page-break-lines
(use-package page-break-lines
  :init (add-to-list 'package-selected-packages 'page-break-lines)
  :custom
    (page-break-lines-max-width 120)
  :config
    (global-page-break-lines-mode t))
;;; }}} *** page-break-lines

;;; {{{ *** posframe
(use-package posframe :init (add-to-list 'package-selected-packages 'posframe))

;;; {{{ *** dired-posframe
(use-package dired-posframe
  :after flycheck
  :init (add-to-list 'package-selected-packages 'dired-posframe)
  :bind (
    :map dired-mode-map
    ("C-*"              . dired-posframe-show))
  :config
    (add-hook 'dired-mode-hook                  #'dired-posframe-mode))
;;; }}} *** dired-posframe

;;; {{{ *** flycheck-posframe
(use-package flycheck-posframe
  :after flycheck
  :init (add-to-list 'package-selected-packages 'flycheck-posframe)
  :config
    (add-hook 'flycheck-mode-hook               #'flycheck-posframe-mode))
;;; }}} *** flycheck-posframe

;;; {{{ *** hyudra-posframe
;; NOTE: hydra and posframe are required
(use-package hydra-posframe
  :ensure (:host github :repo "Ladicle/hydra-posframe")
  :init (add-to-list 'package-selected-packages 'hydra-posframe)
  :config
    (add-hook 'after-init-hook                  #'hydra-posframe-mode))
;;; }}} *** hydra-posframe

;;; {{{ *** transient-posframe
(use-package transient-posframe
  :init (add-to-list 'package-selected-packages 'transient-posframe)
  :custom
    (transient-posframe-poshandler (default posframe-poshandler-window-center))
  :config
    (transient-posframe-mode t))
;;; }}} *** transient-posframe

;;; {{{ *** vertico-posframe
(use-package vertico-posframe
  :init (add-to-list 'package-selected-packages 'vertico-posframe)
  :custom
    (vertico-multiform-commands
      '((consult-line
          posframe
          (vertico-posframe-poshandler . posframe-poshandler-frame-top-center)
          (vertico-posframe-border-width . 10)
          ;; NOTE: This is useful when emacs is used in both in X and
          ;; terminal, for posframe do not work well in terminal, so
          ;; vertico-buffer-mode will be used as fallback at the
          ;; moment.
          (vertico-posframe-fallback-mode . vertico-buffer-mode))
          (t posframe)))
  :config
    (vertico-posframe-mode t))
;;; }}} *** vertico-posframe
;;; }}} *** posframe

;;; {{{ *** random-splash-image
(use-package random-splash-image
  :init (add-to-list 'package-selected-packages 'random-splash-image)
  :custom
    (random-splash-image-dir (no-littering-expand-etc-file-name "emacs-logos"))
    (random-splash-image-include-dir t)
    (random-splash-image-include-subdir t)
    (random-splash-image-include-hidden t)
    (random-splash-image-include-remote t)
    (random-splash-image-include-url t)
    (random-splash-image-include-url-regex-ignore-case t)
    (random-splash-image-include-url-regex-full t)
    (random-splash-image-include-url-regex-match t)
  :config
    (random-splash-image-mode t)
    (random-splash-image-refresh)
    (random-splash-image-show))
;;; }}} *** random-splash-image

;;; {{{ *** shr-tag-pre-highlight
(use-package shr-tag-pre-highlight
  :ensure t
  :after (shr)
  :init (add-to-list 'package-selected-packages 'shr-tag-pre-highlight)
  :config
    (add-to-list 'shr-external-rendering-functions
                 '(pre . shr-tag-pre-highlight)))
;;; }}} *** shr-tag-pre-highlight

;;; {{{ *** tabspaces
(use-package tabspaces
  :init (add-to-list 'package-selected-packages 'tabspaces)
  :custom
    (tabspaces-include-buffers '("*scratch*"))
    (tabspaces-mode t)
    (tabspaces-remove-to-default t)
    (tabspaces-use-filtered-buffers-as-default t)
  :config
    ;; Make sure project is initialized
    (project--ensure-read-project-list))
;;; }}} *** tabspaces
;;; }}} ** ui

;;; {{{ ** writing
;;; {{{ *** LaTeX
;;; {{{ **** auctex
(use-package auctex
  :ensure (:build (:not elpaca--compile-info)
            :pre-build (
              ("./autogen.sh")
              ("./configure"
                "--without-texmf-dir"
                "--with-packagelispdir=./"
                "--with-packagedatadir=./")
              ("make"))
            :files ("*.el" "doc/*.info*" "etc" "images" "latex" "style")
            :version (lambda (_) (require 'tex-site) AUCTeX-version))
  :init (add-to-list 'package-selected-packages 'auctex)
  :config
    ;; (require 'f)
    (defun +my/ded:elpaca-build-dir (p)
      "Return the elpaca build directory for package symbol p"
        (-first-item
          (f-directories
            elpaca-builds-directory
            (lambda (dir)
              (string-match-p (concat "^" (symbol-name p) "$") (f-filename dir))))))
    (add-to-list 'Info-additional-directory-list (f-join (+my/ded:elpaca-build-dir 'auctex) "doc")))
;;; }}} **** auctex

;;; {{{ **** auctex-latexmk
(use-package auctex-latexmk
  :if (and (executable-find "latex")
           (executable-find "latexmk"))
  :init (add-to-list 'package-selected-packages 'auctex-latexmk))
;;; }}} **** auctex-latexmk

;;; {{{ **** consult-tex
(use-package consult-tex
  :if (executable-find "latex")
  :after (latex)
  :init (add-to-list 'package-selected-packages 'consult-tex))
;;; }}} **** consult-tex

;;; {{{ **** latex-extra
(use-package latex-extra
  :if (executable-find "latex")
  :after (latex)
  :init (add-to-list 'package-selected-packages 'latex-extra)
  :config
    (add-hook 'LaTeX-mode-hook                  #'latex-extra-mode))
;;; }}} **** latex-extra

;;; {{{ **** LaTeX configuration
(with-eval-after-load 'latex
  (customize-set-variable 'TeX-auto-save t)
  (customize-set-variable 'TeX-parse-self t)
  (setq-default TeX-master nil)

  ;; compile to pdf
  (tex-pdf-mode)

  ;; correlate the source and the output
  (TeX-source-correlate-mode)

  ;; set a correct indentation in a few additional environments
  (add-to-list 'LaTeX-indent-environment-list '("lstlisting" current-indentation))
  (add-to-list 'LaTeX-indent-environment-list '("tikzcd" LaTeX-indent-tabular))
  (add-to-list 'LaTeX-indent-environment-list '("tikzpicture" current-indentation))

  ;; add a few macros and environment as verbatim
  (add-to-list 'LaTeX-verbatim-environments "lstlisting")
  (add-to-list 'LaTeX-verbatim-environments "Verbatim")
  (add-to-list 'LaTeX-verbatim-macros-with-braces "lstinline")
  (add-to-list 'LaTeX-verbatim-macros-with-delims "lstinline")

  ;; electric pairs in auctex
  (customize-set-variable 'TeX-electric-sub-and-superscript t)
  (customize-set-variable 'LaTeX-electric-left-right-brace t)
  (customize-set-variable 'TeX-electric-math (cons "$" "$"))

  ;; open all buffers with the math mode and auto-fill mode
  (add-hook 'LaTeX-mode-hook #'auto-fill-mode)
  (add-hook 'LaTeX-mode-hook #'LaTeX-math-mode)

  ;; add support for references
  (add-hook 'LaTeX-mode-hook #'turn-on-reftex)
  (customize-set-variable 'reftex-plug-into-AUCTeX t)

  ;; to have the buffer refresh after compilation
  (add-hook 'TeX-after-compilation-finished-functions #'TeX-revert-document-buffer)

  (add-hook 'LaTeX-mode-hook
            (lambda ()
              (load "auctex.el")
              (customize-set-variable 'TeX-command-extra-options "-shell-escape"))))

(defun +my/latex-use-pdf-tools ()
  "Use PDF Tools instead of docview,\n  requires a build environment to compile PDF Tools.\n\nDepends on having pdf-tools'."

  (with-eval-after-load 'latex
    (customize-set-variable 'TeX-view-program-selection '((output-pdf "PDF Tools")))
    (customize-set-variable 'TeX-view-program-list '(("PDF Tools" TeX-pdf-tools-sync-view)))
    (customize-set-variable 'TeX-source-correlate-start-server t)))

;;;; Message the user if the latex executable is not found
(defun +my/writing-tex-warning-if-no-latex-executable ()
  "Print a message to the minibuffer if the \"latex\" executable cannot be found."
  (unless (executable-find "latex")
    (message "latex executable not found")))
(add-hook 'tex-mode-hook                        #'+my/writing-tex-warning-if-no-latex-executable)

(when (and (executable-find "latex")
            (executable-find "latexmk"))
    (with-eval-after-load 'latex
      (when (require 'auctex-latexmk nil 'noerror)
          (with-eval-after-load 'auctex-latexmk
            (auctex-latexmk-setup)
            (customize-set-variable 'auctex-latexmk-inherit-TeX-PDF-mode t))

          (defun +my/writing-tex-make-latexmk-default-command ()
            "Set `TeX-command-default' to \"LatexMk\"."
            (customize-set-variable 'TeX-command-default "LatexMk"))
          (add-hook 'TeX-mode-hook              #'+my/writing-tex-make-latexmk-default-command))))
;;; }}} **** LaTeX configuration

;;; }}} *** LaTeX

;;; {{{ *** markdown-mode
(when (fboundp 'markdown-mode)
    ;; because the markdown-command variable may not be loaded (yet),
    ;; check manually for the other markdown processors.  If it is
    ;; loaded, the others are superfluous but `or' fails fast, so they
    ;; are not checked if `markdown-command' is set and the command is
    ;; indeed found.
    (unless (or (and (boundp 'markdown-command)
                    (executable-find markdown-command))
                (executable-find "markdown")
                (executable-find "pandoc"))
        (message "No markdown processor found, preview may not possible."))

    (with-eval-after-load 'markdown-mode
      (customize-set-variable 'markdown-enable-math t)
      (customize-set-variable 'markdown-enable-html t)
      (add-hook 'markdown-mode-hook #'conditionally-turn-on-pandoc)))
;;; }}} *** markdown-mode

;;; {{{ *** pdf-tools
;;; PDF Support when using pdf-tools
(use-package pdf-tools
  :init (add-to-list 'package-selected-packages 'pdf-tools)
  :custom
    (pdf-view-display-size 'fit-width)
  :magic
    ("%PDF" . pdf-view-mode)
  :config
    (pdf-tools-install :no-query))

(when (locate-library "pdf-tools")
    ;; load pdf-tools when going into doc-view-mode
    (defun +my/writing-load-pdf-tools ()
      "Attempts to require pdf-tools, but for attaching to hooks."
      (require 'pdf-tools nil :noerror))
    (add-hook 'doc-view-mode-hook               #'+my/writing-load-pdf-tools)

    ;; when pdf-tools is loaded, apply settings.
    (with-eval-after-load 'pdf-tools
      (setq-default pdf-view-display-size 'fit-width)))
;;; }}} *** pdf-tools

;;; {{{ *** biblio
;; Managing Bibliographies
;; Biblio package for adding BibTeX records
(use-package biblio :init (add-to-list 'package-selected-packages 'biblio)
  ;; :bind (
  ;;   ("C-c w b b"    . ews-biblio-lookup))
)
;;; }}} *** biblio

;;; {{{ *** citar
(use-package citar :init (add-to-list 'package-selected-packages 'citar)
  ;; :custom
  ;;   (citar-bibliography ews-bibtex-files)
  ;;   (citar-indicators
  ;;     (list citar-indicator-files-icons
  ;;           citar-indicator-links-icons
  ;;           citar-indicator-notes-icons
  ;;           citar-indicator-cited-icons))
  ;;   (citar-templates
  ;;     '((main       . "${author editor:30%sn}     ${date year issued:4}     ${title:48}")
  ;;       (note       . "Notes on ${author editor:%etal}, ${title}")
  ;;       (preview    . "${author editor:%etal} (${year issued date}) ${title}, ${journal journaltitle publisher container-title collection-title}.\n")
  ;;       (suffix     . "          ${=key= id:15}    ${=type=:12}    ${tags keywords:*}")))
  ;; :bind (
  ;;   ("C-c w b o"    . citar-open))
  :config
    (customize-set-variables 'citar-bibliography ews-bibtex-files)
    (customize-set-variables 'citar-indicators
      (list citar-indicator-files-icons
            citar-indicator-links-icons
            citar-indicator-notes-icons
            citar-indicator-cited-icons))
    (customize-set-variables 'citar-templates
      '((main       . "${author editor:30%sn}     ${date year issued:4}     ${title:48}")
        (note       . "Notes on ${author editor:%etal}, ${title}")
        (preview    . "${author editor:%etal} (${year issued date}) ${title}, ${journal journaltitle publisher container-title collection-title}.\n")
        (suffix     . "          ${=key= id:15}    ${=type=:12}    ${tags keywords:*}")))
    (add-hook 'LaTeX-mode-hook                  #'citar-capf-setup)
    (add-hook 'org-mode-hook                    #'citar-capf-setup))

(use-package citar-denote
  :after (citar denote)
  ;; :demand t     ;; Ensure minor mode is loaded
  :init (add-to-list 'package-selected-packages 'citar-denote)
  :custom
    ;; Package defaults
    (citar-denote-file-type 'org)
    (citar-denote-keyword "bib")
    (citar-denote-signature nil)
    (citar-denote-subdir nil)
    (citar-denote-template nil)
    (citar-denote-title-format "title")
    (citar-denote-title-format-andstr "and")
    (citar-denote-title-format-authors 1)
    (citar-denote-use-bib-keywords nil)
    ;; `nil' Allow multiple notes per bibliographic entry [`t' for EWS]
    (citar-open-always-create-notes t)
  ;; :bind (
  ;;   ;; Bind all available commands
  ;;   ("C-c w a"   . citar-denote-add-citekey)
  ;;   ("C-c w c"   . citar-create-note)
  ;;   ("C-c w d"   . citar-denote-dwim)
  ;;   ("C-c w e"   . citar-denote-open-reference-entry)
  ;;   ("C-c w f"   . citar-denote-find-citation)
  ;;   ("C-c w k"   . citar-denote-remove-citekey)
  ;;   ("C-c w l"   . citar-denote-link-reference)
  ;;   ("C-c w n"   . citar-denote-no-bibliography)
  ;;   ("C-c w n"   . citar-denote-open-note)
  ;;   ("C-c w r"   . citar-denote-find-reference)
  ;;   ("C-c w x"   . citar-denote-nocite)
  ;;   ("C-c w y"   . citar-denote-cite-nocite)
  ;;   ("C-c w z"   . citar-denote-nobib)
  ;;   :map org-mode-map
  ;;   ("C-c w b K" . citar-denote-remove-citekey)
  ;;   ("C-c w b d" . citar-denote-dwim)
  ;;   ("C-c w b k" . citar-denote-add-citekey))
  :config
    (citar-denote-mode t))

(use-package citar-embark
  :after (citar embark)
  :no-require
  :init (add-to-list 'package-selected-packages 'citar-embark)
  :custom
    (citar-at-point-function 'embark-act)
  :config
    (citar-embark-mode t))

(use-package citar-org-roam
  :after (citar org-roam)
  :init (add-to-list 'package-selected-packages 'citar-org-roam)
  :custom
    (citar-org-roam-capture-template-key "n")
  :config
    (citar-org-roam-mode t))

(use-package citeproc :init (add-to-list 'package-selected-packages 'citeproc))
;;; }}} *** citar

;;; {{{ *** olivetti
(use-package olivetti
  :init (add-to-list 'package-selected-packages 'olivetti)
  :bind (
    ;; for EWS
    :map text-mode-map
    ("C-c w o"  . ews-olivetti)))
;;; }}} *** olivetti

;;; {{{ *** parentheses
(electric-pair-mode t)  ;; auto-insert matching bracket
(show-paren-mode t)     ;; turn on paren match highlighting

;;; {{{ **** smartparens
(use-package smartparens
  :init (add-to-list 'package-selected-packages 'smartparens)
  :config
    (progn
      (require 'smartparens-config)   ;; load default config
      (show-smartparens-global-mode t))
    (add-hook 'markdown-mode-hook               #'turn-on-smartparens-strict-mode)
    (add-hook 'prog-mode-hook                   #'turn-on-smartparens-strict-mode)
    (add-hook 'text-mode-hook                   #'turn-on-smartparens-strict-mode))
;;; }}} **** smartparens
;;; }}} *** parentheses

;;; {{{ *** whitespace
(defun +my/writing-configure-whitespace (use-tabs &optional use-globally &rest enabled-modes)
  "Helper function to configure `whitespace' mode.

Enable using TAB characters if USE-TABS is non-nil.  If
USE-GLOBALLY is non-nil, turn on `global-whitespace-mode'.  If
ENABLED-MODES is non-nil, it will be a list of modes to activate
whitespace mode using hooks.  The hooks will be the name of the
mode in the list with `-hook' appended.  If USE-GLOBALLY is
non-nil, ENABLED-MODES is ignored.

Configuring whitespace mode is not buffer local.  So calling this
function twice with different settings will not do what you
think.  For example, if you wanted to use spaces instead of tabs
globally except for in Makefiles, doing the following won't work:

;; turns on global-whitespace-mode to use spaces instead of tabs
(+my/writing-configure-whitespace nil t)

;; overwrites the above to turn to use tabs instead of spaces,
;; does not turn off global-whitespace-mode, adds a hook to
;; makefile-mode-hook
(+my/writing-configure-whitespace t nil 'makefile-mode)

Instead, use a configuration like this:
;; turns on global-whitespace-mode to use spaces instead of tabs
(+my/writing-configure-whitespace nil t)

;; turn on the buffer-local mode for using tabs instead of spaces.
(add-hook 'makefile-mode-hook #'indent-tabs-mode)

For more information on `indent-tabs-mode', See the info
node `(emacs)Just Spaces'

Example usage:

;; Configuring whitespace mode does not turn on whitespace mode
;; since we don't know which modes to turn it on for.
;; You will need to do that in your configuration by adding
;; whitespace mode to the appropriate mode hooks.
(+my/writing-configure-whitespace nil)

;; Configure whitespace mode, but turn it on globally.
(+my/writing-configure-whitespace nil t)

;; Configure whitespace mode and turn it on only for prog-mode
;; and derived modes.
(+my/writing-configure-whitespace nil nil 'prog-mode)"
  (if use-tabs
      (customize-set-variable 'whitespace-style
                                '(face empty trailing indentation::tab
                                  space-after-tab::tab
                                space-before-tab::tab))
    ;; use spaces instead of tabs
    (customize-set-variable 'whitespace-style
                              '(face empty trailing tab-mark
                                indentation::space)))

  (if use-globally
      (global-whitespace-mode t)
    (when enabled-modes
        (dolist (mode enabled-modes)
          (add-hook (intern (format "%s-hook" mode)) #'whitespace-mode)))))

;; cleanup whitespace
(customize-set-variable 'whitespace-action '(cleanup auto-cleanup))
(+my/writing-configure-whitespace nil t)
;;; }}} *** whitespace

;;; {{{ *** writegood-mode
(use-package writegood-mode
  :init (add-to-list 'package-selected-packages 'writegood-mode)
  :bind (
    ("C-c g"        . writegood-mode)
    ("C-c C-g e"    . writegood-reading-ease)
    ("C-c C-g g"    . writegood-grade-level)
    ;; for EWS
    ("C-c w s r"    . writegood-reading-ease))
  :config
    (add-hook 'text-mode-hook                   #'writegood-mode))
;;; }}} *** writegood-mode

;;; }}} ** writing

;;; }}} * Packages phase


;;; {{{ * Configuration phase
(defmacro with-system (type &rest body)
  "Evaluate BODY if `system-type' equals TYPE."
  (declare (indent defun))
  `(when (eq system-type ',type)
     ,@body))

;; make the menu key do M-x
;; emacs 29 new keybinding syntax
(with-system darwin
  (keymap-global-set "<application>" 'execute-extended-command))
(with-system gnu\linux
  (keymap-global-set "<menu>" 'execute-extended-command))
(with-system windows-nt
  (keymap-global-set "<apps>" 'execute-extended-command))


;;; {{{ ** features

;;; {{{ *** global keybindings
(use-feature emacs
  :init
    ;; Set `initial-scratch-message'.
  :custom
    (pixel-scroll-precision-mode t)
  :bind (
    ;;;;; Resize keys with global effect
    ;; Emacs 29 introduces commands that resize the font across all
    ;; buffers (including the minibuffer), which is what I want, as
    ;; opposed to doing it only in the current buffer.    The keys are the
    ;; same as the defaults.
    ("C-+"      . #'global-text-scale-adjust)
    ("C-="      . #'global-text-scale-adjust)
    ("C-0"      . #'global-text-scale-adjust)
    ("C-x C-+"  . #'global-text-scale-adjust)
    ("C-x C-="  . #'global-text-scale-adjust)
    ("C-x C-0"  . #'global-text-scale-adjust)
    ;;;;; `variable-pitch-mode' setup
    :map ctl-x-x-map
    ("v"        . #'variable-pitch-mode))
  :config
    (defun +my/prev-match () (interactive nil) (next-match -1))
    (global-set-key [backtab] 'auto-complete)
    (global-set-key [f3] 'next-match)
    (global-set-key [(shift f3)] '+my/prev-match))
;;; }}} *** global keybindings

;;; {{{ *** ansi-color
(use-feature ansi-color
  ;; ANSI color in compilation buffer
  :commands (ansi-color-apply-on-region)
  :config
    (defun +my/colorize-compilation-buffer ()
      "Colorize from `compilation-filter-start' to `point'."
      (toggle-read-only)
      (ansi-color-apply-on-region (point-min) (point-max))
      (toggle-read-only))
    (add-hook 'compilation-filter-hook          #'+my/colorize-compilation-buffer))
;;; }}} *** ansi-color

;;; {{{ *** auto-revert
;; Revert buffers when the underlying file has changed
(use-feature autorevert
  :custom
    (auto-revert-interval 0.01 "Instantaneously revert")
    (auto-revert-verbose t)
    ;; Revert Dired and other buffers
    (global-auto-revert-non-file-buffers t)
  :config
    (global-auto-revert-mode t))
;;; }}} *** auto-revert

;;; {{{ *** bibtex
;; Managing Bibliographies
(use-feature bibtex
  :custom
    (bibtex-align-at-equal-sign t)
    (bibtex-user-optional-fields
      '(("keywords" "Keywords to describe the entry" "")
        ("file" "Link to a document file." "" )))
  ;; :bind (
  ;;   ("C-c w b r"    . ews-biblio-register-files))
  :config
    (ews-bibtex-register))
;;; }}} *** bibtex

;;; {{{ *** bookmarks (bookmark.el)
;; save the bookmarks file every time a bookmark is made or deleted
;; rather than waiting for Emacs to be killed.  Useful especially when
;; Emacs is a long running process.
(use-feature bookmark
  :custom
    (bookmark-automatically-show-annotations t)
    (bookmark-default-file (no-littering-expand-var-file-name "bookmarks") "no-littering `bookmark-default-file'")
    (bookmark-fontify t)
    (bookmark-menu-confirm-deletion t)
    ;; Write changes to the bookmark file as soon as 1 modification is
    ;; made (addition or deletion).  Otherwise Emacs will only save the
    ;; bookmarks when it closes, which may never happen properly
    ;; (e.g. power failure).
    (bookmark-save-flag 1)
    (bookmark-use-annotations t)
  ;; :bind (
  ;;   ("C-x r D"      . bookmark-delete))
  :config
    (add-hook 'bookmark-bmenu-mode-hook         #'hl-line-mode))
;;; }}} *** bookmarks (bookmark.el)

;;; {{{ *** compile
(use-feature compile
  :commands (compile recompile)
  :custom (compilation-scroll-output 'first-error)
  :config
    (defun +my/compilation-colorize ()
      "Colorize from `compilation-filter-start' to `point'."
      (require 'ansi-color)
      (let ((inhibit-read-only t))
        (ansi-color-apply-on-region (point-min) (point-max))))
    (add-hook 'compilation-filter-hook          #'+my/compilation-colorize))
;;; }}} *** compile

;;; {{{ *** dictionary
(use-feature dictionary
  :custom
    (dictionary-create-buttons nil)
    (dictionary-server "dict.org")
    (dicitonary-use-single-buffer t)
  :bind (   ;; for EWS
    ("C-c w s d"    . dictionary-lookup-definition))
)
;;; }}} *** dictionary

;;; {{{ *** dired
(use-feature dired
  :commands
    (dired dired-jump)
  :init
    (put 'dired-find-alternate-file 'disabled nil)
  :custom
    (dired-auto-revert-buffer t)                ;; automatically update dired buffers on revisiting their directory
    ;; Make dired do something intelligent when two directories are shown
    ;; in separate dired buffers.  Makes copying or moving files between
    ;; directories easier.  The value `t' means to guess the default
    ;; target directory.
    (dired-dwim-target t)
    (dired-kill-when-opening-new-dired-buffer t)
    (dired-listing-switches "-aghlo --group-directories-first --time-style=long-iso" "Human friendly file sizes.")
    (dired-omit-files "\\(?:\\.+[^z-a]*\\)")
    (global-auto-revert-non-file-buffers t)     ;; Revert Dired and other buffers
  :config
    (add-hook 'dired-mode-hook                  #'dired-omit-mode)
    ;; Revert buffers when the underlying file has changed
    (global-auto-revert-mode t))
;;; }}} *** dired

;;; {{{ *** display-fill-column-indicator
(use-feature display-fill-column-indicator
  :custom
    (display-fill-column-indicator-character (plist-get '( double-bar   ?║ double-pipe  ?╎ empty-bullet ?◦ solid-block  ?█ triple-pipe  ?┆) 'triple-pipe))
)
;;; }}} *** display-fill-column-indicator

;;; {{{ *** doc-view
(use-feature doc-view
  :custom
    (doc-view-resolution 300)
    (large-file-warning-threshold (* 50 (expt 2 20))))
;;; }}} *** doc-view

;;; {{{ *** ede
(use-feature ede
  :config
    (global-ede-mode t))
;;; }}} *** ede

;;; {{{ *** edebug
(use-feature edebug
  :config
    ;; (global-leader
    ;;   :major-modes  '(emacs-lisp-mode lisp-interaction-mode t)
    ;;   :keymaps      '(emacs-lisp-mode-map lisp-interaction-mode-map)
    ;;     "d"     '(:ignore t)
    ;;     "dA"    'edebug-all-defs
    ;;     "db"    '(:ignore t)
    ;;     "dbU"   'edebug-unset-breakpoints
    ;;     "dbc"   'edebug-set-conditional-breakpoint
    ;;     "dbg"   'edebug-set-global-break-condition
    ;;     "dbn"   'edebug-next-breakpoint
    ;;     "dbs"   'edebug-set-breakpoint
    ;;     "dbt"   'edebug-toggle-disable-breakpoint
    ;;     "dbu"   'edebug-unset-breakpoint
    ;;     "dw"    'edebug-where)
)
;;; }}} *** edebug

;;; {{{ *** ediff
(use-feature ediff
  :custom
    ;; keep the Ediff control panel in the same frame
    (ediff-window-setup-function 'ediff-setup-windows-plain)

    (ediff-split-window-function #'split-window-horizontally)
    (ediff-window-setup-function #'ediff-setup-windows-plain)
  :config
    (add-hook 'ediff-quit-hook                  #'winner-undo))
;;; }}} *** ediff

;;; {{{ *** elisp-mode
(use-feature elisp-mode
  :config
    ;; (global-leader
    ;;   :major-modes  '(emacs-lisp-mode lisp-interaction-mode t)
    ;;   :keymaps      '(emacs-lisp-mode-map lisp-interaction-mode-map)
    ;;     "e"     '(:ignore t)
    ;;     "eb"    'eval-buffer
    ;;     "ed"    'eval-defun
    ;;     "ee"    'eval-expression
    ;;     "ep"    'pp-eval-last-sexp
    ;;     "es"    'eval-last-sexp
    ;;     "i"     'elisp-index-search)
)
;;; }}} *** elisp-mode

;;; {{{ *** epa/g-config
(use-feature epg-config
  :custom
    (epg-pinentry-mode 'loopback))

(use-feature epa-file
  :custom
    (epa-file-cache-passphrase-for-symmetric-encryption t))
;;; }}} *** epa/g-config

;;; {{{ ** eww
(use-feature eww
  :defer 60
  :custom
    (browse-url-browser-function 'eww-browse-url)
    (browse-url-secondary-browser-function 'browse-url-default-browser)
    (eww-bookmarks-directory  (no-littering-expand-etc-file-name "eww-bookmarks") "no-littering `eww-bookmarks-directory'")
    (eww-browse-url-new-window-is-tab nil)
    (eww-desktop-remove-duplicates t)
    (eww-download-directory (expand-file-name "~/Downloads/eww"))
    (eww-form-checkbox-selected-symbol "[X]")
    (eww-form-checkbox-symbol "[ ]")
    (eww-header-line-format nil)
    (eww-history-limit 150)
    (eww-restore-desktop t)

    ;; NOTE `eww-retrieve-command' is for Emacs28.  I tried the following
    ;; two values.  The first would not render properly some plain text
    ;; pages, such as by messing up the spacing between paragraphs.  The
    ;; second is more reliable but feels slower.  So I just use the
    ;; default (nil), though I find wget to be a bit faster.  In that case
    ;; one could live with the occasional errors by using `eww-download'
    ;; on the offending page, but I prefer consistency.
    ;;
    ;; '("wget" "--quiet" "--output-document=-")
    ;; '("chromium" "--headless" "--dump-dom")
    (eww-retrieve-command nil)

    (eww-search-prefix "https://duckduckgo.com/html/?q=")
    (eww-suggest-uris '(eww-links-at-point thing-at-point-url-at-point))
    (eww-use-external-browser-for-content-type "\\`\\(video/\\|audio\\)")
    (goto-address-mail-face nil)
    (goto-address-trusted-urls '(".*"))
    (goto-address-url-mouse-face 'highlight)
    (goto-addrmail-mouse-face 'highlight)
  :config
    (defun +my/eww-restore-desktop ()
      "Restore the desktop when quitting EWW."
      (when (and (bound-and-true-p eww-restore-desktop)
                 (file-exists-p (desktop-full-file-name)))
        (desktop-read)))
    (require 'shrface)
    (add-hook 'eww-after-render-hook           #'+my/eww-restore-desktop)
    (add-hook 'eww-after-render-hook           #'shrface-mode)
    (add-hook 'eww-after-render-hook           #'eww-readable))
;;; }}} ** eww

;;; {{{ *** files
;; By default Emacs saves backups in the current buffer's working directory.
;; I'd rather have everything in one folder to keep my file system tidy.
(use-feature files
  :custom
    (auto-save-file-name-transforms `((".*" ,(no-littering-expand-var-file-name "auto-save-list/") t)))
    (auto-save-visted-mode t)
    (backup-by-copying t)
    (backup-directory-alist `((".*" . ,(expand-file-name (no-littering-expand-var-file-name "backups")))) "Keep backups in their own directory")
    (backup-inhibited nil)
    (create-lockfiles nil)
    (delete-old-versions nil)
    (kept-new-versions 10)
    (kept-old-versions 5)
    (make-backup-files nil)
    (remote-file-name-inhibit-auto-save t)
    (remote-file-name-inhibit-auto-save-visited t)
    (remote-file-name-inhibit-delete-by-moving-to-trash t)
    (require-final-newline t "Automatically add newline at end of file")
    (safe-local-variable-values '((eval load "init-dev") (org-clean-refile-inherit-tags)) "Store safe local variables here instead of in emacs-custom.el")
    (vc-make-backup-files t)
    (version-control t)
  :config
    ;; source: http://steve.yegge.googlepages.com/my-dot-emacs-file
    (defun +my/rename-file-and-buffer (new-name)
      "Renames both current buffer and file it's visiting to NEW-NAME."
      (interactive "sNew name: ")
      (let ((name (buffer-name))
            (filename (buffer-file-name)))
        (if (not filename)
            (message "Buffer '%s' is not visiting a file." name)
          (if (get-buffer new-name)
              (message "A buffer named '%s' already exists." new-name)
            (progn
              (rename-file filename new-name 1)
              (rename-buffer new-name)
              (set-visited-file-name new-name)
              (set-buffer-modified-p nil))))))

    (add-hook 'before-save-hook                 #'delete-trailing-whitespace))
;;; }}} *** files

;;; {{{ *** find-func
(use-feature find-func
  :custom
    (find-function-C-source-directory (expand-file-name "~/nc/Git/Projects/emacs/src/")))
;;; }}} *** find-func

;;; {{{ *** flymake
(use-feature flymake
  :config
    (add-to-list 'display-buffer-alist
                 '("\\`\\*Flymake diagnostics.*?\\*\\'"
                   display-buffer-in-side-window  (window-parameters (window-height 0.10)) (side . bottom)))

    (add-hook 'flymake-mode-hook                #'(lambda ()
                                                    (or (ignore-errors flymake-show-project-diagnostics)
                                                        (flymake-show-buffer-diagnostics))))

    (defun +my/flymake-elpaca-bytecomp-load-path ()
      "Augment `elisp-flymake-byte-compile-load-path' to support Elpaca."
      (setq-local elisp-flymake-byte-compile-load-path
                  `("./" ,@(mapcar #'file-name-as-directory
                            (nthcdr 2 (directory-files (expand-file-name "builds" elpaca-directory) 'full))))))
    (add-hook 'flymake-mode-hook                #'+my/flymake-elpaca-bytecomp-load-path))
;;; }}} *** flymake

;;; {{{ *** flyspell
(use-feature flyspell
  :custom
    (flyspell-case-fold-duplications t)
    (flyspell-default-dictionary "en_GB")
    (flyspell-issue-message-flag nil)
    ;; (ispell-program-name "hunspell")
    (ispell-silently-savep t)
    (org-fold-core-style 'overlays) ;; Fix Org mode bug
  :commands (flyspell-mode flyspell-prog-mode)
  :config
    (add-hook 'prog-mode-hook                   #'flyspell-prog-mode)
    (add-hook 'git-commit-mode-hook             #'flyspell-mode)
    (add-hook 'mu4e-compose-mode-hook           #'flyspell-mode)
    (add-hook 'org-mode-hook                    #'flyspell-mode)
    (add-hook 'text-mode-hook                   #'flyspell-mode))
;;; }}} *** flyspell

;;; {{{ *** gnus
(use-feature gnus
  :custom
    (user-mail-address "embrace.s0ul+s-a-c@gmail.com")  ;; (+email-address +email-dev))
    (gnus-select-method '(nntp "news.gmane.io"))
    (gnus-use-dribble-file nil)
    (gnus-thread-sort-functions '(gnus-thread-sort-by-most-recent-date (not gnus-thread-sort-by-number)))
    (gnus-use-cache t)
    (gnus-interactive-exit nil)
    (gnus-ignored-newsgroups "^to\\.\\|^[0-9. ]+\\( \\|$\\)\\|^[\"]\"[#'()]")
  :config
    (require 'nnimap)
    (add-to-list 'gnus-secondary-select-methods '(nntp "news.gmane.io"))
    (add-to-list 'gnus-secondary-select-methods
                 '(nnimap "gmail"
                    (gnus-topic-set-parameters "gmail" '((display . 200)))
                    (nnimap-address "imap.gmail.com")
                    (nnimap-server-port "imaps")
                    (nnimap-stream ssl)
                    (nnir-search-engine imap)
                    (nnmail-expiry-target "nnimap+gmail:[Gmail]/Trash")
                    (nnmail-expiry-wait 90))))
;;; }}} *** gnus

;;; {{{ *** help
(use-feature help
  :custom
    (help-window-select t "Always select the help window"))
;;; }}} *** help

;;; {{{ *** holidays
;; I'd like to see holidays and anniversaries in my org-agenda and calendar
;; I've removed the default holiday lists that I don't need.
(use-feature holidays
  :commands (org-agenda)
  :custom
    (holiday-bahai-holidays nil)
    (holiday-hebrew-holidays nil)
    (holiday-islamic-holidays nil)
    (holiday-oriental-holidays nil))
;;; }}} *** holidays

;;; {{{ *** ielm
;; Provides a nice interface to evaluating Emacs Lisp expressions.
;; Input is handled by the comint package, and output is passed through the pretty-printer.
;;
;; ielm.el commentary
(use-feature ielm
  :bind (
    ;; for EWS
    ;; ("C-c w e e"      . ews-ielm)
    :map ielm-map
      ("C-c C-,"      . ielm-find-definition-other-window)
      ("C-c C-."      . ielm-find-definition)
      ("C-c C-/"      . ielm-find-definition-other-frame)
      ("C-c C-a"      . ielm-toggle-all)
      ("C-c C-b"      . ielm-backward-input)
      ("C-c C-b"      . ielm-change-working-buffer)
      ("C-c C-c"      . ielm-send-buffer)
      ("C-c C-d"      . ielm-display-working-buffer)
      ("C-c C-e"      . ielm-send-paragraph)
      ("C-c C-f"      . ielm-forward-input)
      ("C-c C-h"      . ielm-help)
      ("C-c C-j"      . ielm-return)
      ("C-c C-k"      . ielm-kill-input)
      ("C-c C-l"      . ielm-load-file)
      ("C-c C-n"      . ielm-next-input)
      ("C-c C-o"      . ielm-clear-output)
      ("C-c C-p"      . ielm-print-last-sexp)
      ("C-c C-p"      . ielm-print-working-buffer)
      ("C-c C-q"      . ielm-quit)
      ("C-c C-r"      . ielm-send-region)
      ("C-c C-r"      . ielm-send-region)
      ("C-c C-RET"    . ielm-return)
      ("C-c C-s"      . ielm-send-last-sexp)
      ("C-c C-SPC"    . ielm-toggle-all)
      ("C-c C-t"      . ielm-toggle-echo-input)
      ("C-c C-u"      . ielm-previous-input)
      ("C-c C-v"      . ielm-toggle-pretty-printing)
      ("C-c C-w"      . ielm-toggle-eldoc)
      ("C-c C-x"      . ielm-send-definition)
      ("C-c C-y"      . ielm-yank-input)
      ("C-c C-z"      . ielm))
  ;;@TODO: fix this command.
  ;;This should be easier
  ;; :config
  ;;   (global-leader
  ;;     :major-modes '(inferior-emacs-lisp-mode)
  ;;     :keymaps     '(inferior-emacs-lisp-mode-map)
  ;;       "b"  '(:ignore t)
  ;;       "bb" 'ielm-change-working-buffer
  ;;       "bd" 'ielm-display-working-buffer
  ;;       "bp" 'ielm-print-working-buffer
  ;;       "c"  'comint-clear-buffer)
)
;;; }}} *** ielm

;;; {{{ *** lilypond
;; Major mode for Lilypond music engraver. Installing Lilypond puts these in /usr/share/Emacs/site-lisp.
(use-feature lilypond-mode
  :init
    (autoload 'LilyPond-mode "lilypond-mode")
  :bind (
    ;; for EWS
    ("C-c w l c"    . lilypond-compile-file)
    ("C-c w l p"    . lilypond-play)
    :map LilyPond-mode-map
      ("C-c C-c"    . lilypond-compile-file)
      ("C-c C-p"    . lilypond-play))
  :mode "\\.ly\\'"
  :config
    (add-hook 'LilyPond-mode-hook   #'(lambda () (turn-on-font-lock))))
;;; }}} *** lilypond

;;; {{{ *** line numbers
(use-feature emacs
  :config
    (defcustom +my/ui-line-numbers-enabled-modes
      '(conf-mode prog-mode)
      "Modes which should display line numbers."
      :type 'list
      :group '+my/ui)

    (defcustom +my/ui-line-numbers-disabled-modes
      '(org-mode)
      "Modes which should not display line numbers.\n\mModes derived from the modes defined in `+my/ui-line-number-enabled-modes',\nbut should not display line numbers."
      :type 'list
      :group '+my/ui)

    (defun +my/ui--enable-line-numbers-mode ()
      "Turn on line numbers mode.\n\nUsed as hook for modes which should display line numbers."
      (display-line-numbers-mode t))

    (defun +my/ui--disable-line-numbers-mode ()
      "Turn off line numbers mode.\n\nUsed as hook for modes which should not display line numebrs."
      (display-line-numbers-mode -1))

    (defun +my/ui--update-line-numbers-display ()
      "Update configuration for line numbers display."
      (if +my/ui-display-line-numbers
          (progn
            (dolist (mode +my/ui-line-numbers-enabled-modes)
              (add-hook (intern (format "%s-hook" mode)) #'+my/ui--enable-line-numbers-mode))
            (dolist (mode +my/ui-line-numbers-disabled-modes)
              (add-hook (intern (format "%s-hook" mode)) #'+my/ui--disable-line-numbers-mode))
            (setq-default
              display-line-numbers-grow-only t
              display-line-numbers-type t
              display-line-numbers-width 2))
          (progn
            (dolist (mode +my/ui-line-numbers-enabled-modes)
              (remove-hook (intern (format "%s-hook" mode))
                           #'+my/ui--enable-line-numbers-mode))
            (dolist (mode +my/ui-line-numbers-disabled-modes)
              (remove-hook (intern (format "%s-hook" mode))
                           #'+my/ui--disable-line-numbers-mode)))))

    (defcustom +my/ui-display-line-numbers t
        "Whether line numbers should be enabled."
        :type 'boolean
        :group '+my/ui
        :set (lambda (sym val)
               (set-default sym val)
               (+my/ui--update-line-numbers-display))))
;;; }}} *** line numbers

;;; {{{ *** minibuffer
(use-feature minibuffer
  :custom (read-file-name-completion-ignore-case t)
  :config
    (defun +my/minibuffer-up-dir ()
      "Trim rightmost directory component of `minibuffer-contents'."
      (interactive)
      (unless (minibufferp) (user-error "Minibuffer not selected"))
      (let* ((f (directory-file-name (minibuffer-contents)))
             (s (file-name-directory f)))
        (delete-minibuffer-contents)
        (when s (insert s))))
    ;; (define-key minibuffer-local-filename-completion-map
    ;;             (kbd "C-h") #'+minibuffer-up-dir)
    (minibuffer-depth-indicate-mode t))
;;; }}} *** minibuffer

;;; {{{ *** novice
;; This feature tries to help new users by disabling certain potentially
;; destructive or confusing commands. Don't need it.
(use-feature novice
  :custom
    (disabled-command-function nil "Enable all commands"))
;;; }}} *** novice

;;; {{{ *** org
;;; {{{ **** org-agenda
(use-feature org-agenda
  :after (org)
  :custom
    (org-agenda-category-icon-alist
      (let  ( (categories
                '(("[Aa]ccounting" "accounting.svg")
                  ("[Bb]irthday"   "birthday.svg")
                  ("[Cc]alendar"   "calendar.svg")
                  ("[Cc]hore"      "chore.svg"    :height 25)
                  ("[Ee]xercise"   "exercise.svg" :height 24)
                  ("[Ff]ood"       "food.svg")
                  ("[Hh]abit"      "habit.svg")
                  ("[Hh]ealth"     "health.svg")
                  ("[Ii]n"         "in.svg")
                  ("[Ll]isten"     "listen.svg")
                  ("[Oo]ut"        "out.svg")
                  ("[Pp]lay"       "play.svg")
                  ("[Rr]efile"     "refile.svg")
                  ("[Rr]ead"       "read.svg")
                  ("[Ww]atch"      "watch.svg")
                  ("[Ww]ork"       "work.svg")))
              (image-dir (expand-file-name "nc/org/icons" user-emacs-directory)))
        (mapcar (lambda (category)
                  (list (nth 0 category)
                        (expand-file-name (nth 1 category) image-dir)
                        'svg
                        nil
                        :height (or (plist-get category :height) 20)
                        :ascent (or (plist-get category :ascent) 'center)))
                categories)))
    (org-agenda-clockreport-parameter-plist
      '(:link t :maxlevel 2 :stepskip0 t :fileskip0 t))
    (org-agenda-custom-commands
      '(("n" "Agenda and all TODOs" ((agenda "") (alltodo "")))
        ("w" "Work Schedule" agenda "+work"
          ( (org-agenda-archives-mode t)
            (org-agenda-files '("~/nc/org/agenda/todo-work.org"))
            (org-agenda-finalize-hook
              '((lambda ()
                  "Format custom agenda command for work schedule."
                  (save-excursion
                    (goto-char (point-min))
                    (while (re-search-forward "TODO Work" nil 'noerror)
                        (replace-match ""))
                    (goto-char (point-min))
                    (forward-line) ;skip header
                    (while (not (eobp))
                        (when (get-text-property (point) 'org-agenda-date-header)
                            (let (fn)
                              (save-excursion
                                (forward-line)
                                (setq fn
                                      (cond
                                        ((or (eobp)
                                              (get-text-property (point) 'org-agenda-date-header))
                                          (lambda () (end-of-line) (insert " OFF")))
                                        ((get-text-property (point) 'time)
                                          (lambda () (forward-line) (join-line))))))
                              (funcall fn)))
                        (forward-line))))))
            (org-agenda-format-date "%a %m-%d")
            (org-agenda-prefix-format '((agenda . " %t")))
            (org-agenda-span 'week)
            (org-agenda-start-on-weekday 2)
            (org-agenda-time-leading-zero t)
            (org-agenda-timegrid-use-ampm t)
            (org-agenda-use-time-grid nil)
            (org-agenda-weekend-days '(2 3))
            (org-mode-hook nil)))))
    (org-agenda-inhibit-startup t)
    (org-agenda-prefix-format '((agenda . " %i %?-12t% s")))
    (org-agenda-scheduled-leaders '("" "%2dx "))
    (org-agenda-skip-deadline-prewarning-if-scheduled nil "Show approaching deadlines even when scheduled.")
    (org-agenda-sorting-strategy
      '((agenda time-up priority-down category-keep)
        (search category-keep)
        (tags priority-down category-keep)
        (todo priority-down category-keep)))
    (org-agenda-span 'day)
    (org-agenda-tags-column -80)
    (org-agenda-use-tag-inheritance nil)
  :config
    (defun +my/org-agenda-archives (&optional arg)
      "Toggle `org-agenda-archives-mode' so that it includes archive files by default.\nInverts normal logic of ARG."
      (interactive "P")
      (let ((current-prefix-arg (unless (or org-agenda-archives-mode arg) '(4))))
        (call-interactively #'org-agenda-archives-mode)))
    (defun +my/org-agenda-place-point ()
      "Place point on first agenda item."
      (goto-char (point-min))
      (org-agenda-find-same-or-today-or-agenda))
    (add-hook 'org-agenda-finalize-hook #'+my/org-agenda-place-point 90)

    ;;for org-agenda-icon-alist
    (when (or (bound-and-true-p ce-example-use-evil-escape)
              (bound-and-true-p prot-emacs-load-evil))
        (evil-set-initial-state 'org-agenda-mode 'normal))
    (defun +my/org-agenda-redo-all ()
      "Rebuild all agenda buffers"
      (interactive)
      (dolist (buffer (buffer-list))
        (with-current-buffer buffer
          (when (derived-mode-p 'org-agenda-mode)
              (org-agenda-maybe-redo)))))
    (add-hook 'org-mode-hook
      (lambda ()
        (add-hook 'after-save-hook #'+my/org-agenda-redo-all nil t)
        (setq prettify-symbols-unprettify-at-point 'right-edge)
        (setq prettify-symbols-alist
              (mapcan
                (lambda (el) (list el (cons (upcase (car el)) (cdr el))))
                '(("#+begin_src"    . "λ")
                  ("#+end_src"      . "λ")
                  (":properties:"   . "⚙")
                  (":end:"          . "∎")
                  ("#+results:"     . "→"))))
        (prettify-symbols-mode t))))
;;; }}} **** org-agenda

;;; {{{ **** ob-graphviz
(use-feature ob-graphviz
  :after (org)
  :config
    (org-babel-do-load-languages 'org-babel-load-languages
                                    (append org-babel-load-languages
                                      '((dot        . t)))))
;;; }}} **** ob-graphviz

;;; {{{ **** ob-js
(use-feature ob-js
  :after (org)
  :commands (org-babel-execute:js))
;;; }}} **** ob-js

;;; {{{ **** ob-python
(use-feature ob-python
  :after (org)
  :commands (org-babel-execute:python))
;;; }}} **** ob-python

;;; {{{ **** ob-shell
(use-feature ob-shell
  :after (org)
  :commands
    (org-babel-execute:bash
      org-babel-execute:shell
      org-babel-expand-body:generic)
  :config
    (org-babel-do-load-languages 'org-babel-load-languages
                                    (append org-babel-load-languages
                                      '((shell      . t))))

    (defun +my/org-schedule-relative-to-deadline ()
      "For use with my appointment capture template.\n\nUser is first prompted for an optional deadline. Then an optional  schedule time.\nThe scheduled default time is the deadline.\nThis makes it easier to schedule relative to the deadline using the `--' or `++' operators.\n\nQuitting during either date prompt results in an empty string for that prompt."
      (interactive)
      (condition-case nil
          (org-deadline nil)
        (quit nil))
      (let ((org-overriding-default-time (or (org-get-deadline-time (point))
                                             org-overriding-default-time)))
        (org-schedule
          nil
          (org-element-interpret-data
            (org-timestamp-from-time
              org-overriding-default-time
                (and org-overriding-default-time 'with-time))))
        (let ((org-log-reschedule nil))
          (condition-case nil
              (org-schedule nil)
            (quit (org-schedule '(4)))))))

    (defun +my/org-capture-again (&optional arg)
      "Call `org-capture' with last selected template.\nPass ARG to `org-capture'.\nIf there is no previous template, call `org-capture'."
      (interactive "P")
      (org-capture arg (plist-get org-capture-plist :key)))

    (defun +org-capture-here ()
      "Convenience command to insert a template at point"
      (interactive)
      (org-capture 0))

    (defun +my/org-capture-property-drawer ()
      "Hook function run durning `org-capture-mode-hook'.\nIf a template has a :properties keyword, add them to the entry."
      (when (eq (org-capture-get :type 'local) 'entry)
          (when-let ((properties (doct-get :properties t)))
              (dolist (property properties)
                (org-set-property
                  (symbol-name (car property))
                  (replace-regexp-in-string
                    "\n.*" ""
                    (org-capture-fill-template
                      (doct--replace-template-strings (cadr property)))))))))

    (defun +my/org-capture-todo ()
      "Set capture entry to TODO automatically"
      (org-todo "TODO")))
;;; {{{ **** ob-shell

;;; {{{ **** ob-tangle
(use-feature ob-tangle
  :after (org)
  :custom
    (org-src-preserve-indentation t)
    (org-src-window-setup 'current-window)
  :bind (
    :map org-mode-map
      ("C-c C-v"      . org-babel-execute-src-block)
      ("C-c C-x"      . org-babel-tangle)
      ("C-c v"        . org-babel-execute-src-block)
      ("C-c x"        . org-babel-tangle))
  :config
    (dolist (template '(("f"    . "src fountain")
                        ("se"   . "src emacs-lisp :lexical t")
                        ("sj"   . "src javascript")
                        ("ss"   . "src shell")))
      (add-to-list 'org-structure-template-alist template)))
;;; }}} **** ob-tangle

;;; {{{ *** oc
(use-feature oc
  :after (org)
  :init
    (require 'oc-biblatex)
    (require 'oc-csl)
    (require 'oc-natbib)
  :custom
    (org-cite-activate-processor 'citar)
    (org-cite-csl-styles-dir ews-bibtex-directory)
    (org-cite-export-processors
      '((latex natbib "apalike2" "authoryear")
        (t     csl    "apa6.csl")))
    (org-cite-follow-processor 'citar)
    (org-cite-global-bibliography ews-bibtex-files)
    (org-cite-insert-processor 'citar))
;;; }}} *** oc

;;; {{{ **** org-capture
(use-feature org-capture
  :after (org)
  :custom
    (org-capture-bookmark nil)
    (org-capture-dir (concat (getenv "HOME") "/nc/org/agenda/"))
  :bind (
    :map org-mode-map
      ("C-c c"        . org-capture)
    :map org-capture-mode-map
      ("C-c C-c"      . org-capture-finalize)
      ("C-c C-k"      . org-capture-kill)
      ("C-c C-r"      . org-capture-refile))
  :commands (+org-capture-make-frame)
  :config
    (customize-set-variable 'org-capture-templates
      (doct
        `(("Appointment"
            :keys "a"
            :id "2cd2f75e-b600-4e9b-95eb-6baefeaa61ac"
            :properties ((Created "%U"))
            :template ("* %^{appointment} %^g" "%?")
            :hook (lambda ()
                    (+org-capture-property-drawer)
                    (unless org-note-abort (+org-schedule-relative-to-deadline))))
          ("Account"
            :keys "A"
            :properties ((Created "%U"))
            :template ("* TODO %^{description} %^g" "%?")
            :hook +org-capture-property-drawer
            :children
              (("Buy"
                :keys "b"
                :id "e1dcca6e-6d85-4c8e-b935-d50492b2cc58")
               ("Borrow"
                :keys "B"
                :id "a318b8ba-ed1a-4767-84bd-4f45eb409aab"
                :template ("* TODO Return %^{description} to %^{person} %^g"
                            "DEADLINE: %^T"
                            "%?"))
               ("Loan"
                :keys "l"
                :id "cfdd301d-c437-4aae-9738-da022eae8056"
                :template ("* TODO Get %^{item} back from %^{person} %^g"
                            "DEADLINE: %^T"
                            "%?"))
               ("Favor"
                :keys "f"
                :id "9cd02444-2465-4692-958b-f73edacd997f")
               ("Sell"
                :keys "s"
                :id "9c4a39c5-3ba6-4665-ac43-67e72f461c15")))
          ("Bookmark"
            :keys "b"
            :hook +org-capture-property-drawer
            :id "7c20c705-80a3-4f5a-9181-2ea14a18fa75"
            :properties ((Created "%U"))
            :template ("* [[%x][%^{title}]] %^g" "%?"))
          ("Health"
            :keys "h"
            :children
              (("Blood Pressure"
                :keys "b"
                :type table-line
                :id "4d0c16dd-ce99-4e1b-bf9f-fb10802e48a1"
                :template "%(+compute-blood-pressure-table-row)|%?|"
                :table-line-pos "II-1")))
          ("Listen"
            :keys "l"
            :hook (lambda () (+org-capture-property-drawer) (+org-capture-todo))
            :template ("* TODO %^{Title} %^g" "%^{Genre}")
            :children
              (("Audio Book"
                :keys "a"
                :id "55a01ad5-24f5-40ec-947c-ed0bc507d4e8"
                :template "* TODO %^{Title} %^g %^{Author}p %^{Year}p %^{Genre}p")
              ("Music"
                :keys "m"
                :id "dc9cfb0f-c65b-4ebe-a082-e751bb3261a6"
                :template "%(wikinforg-capture \"album\")")
              ("Podcast"
                :keys "p"
                :id "881ee183-37aa-4e76-a5af-5be8446fc346"
                :properties ((URL "[[%^{URL}][%^{Description}]]")))
              ("Radio"
                :keys "r"
                :id "78da1d3e-c83a-4769-9fb2-91e8ff7ab5da")))
              ("Note"
                :keys "n"
                :file ,(defun +my/org-capture-repo-note-file ()
                          "Find note for current repository."
                          (require 'projectile)
                          (let* ( (coding-system-for-write 'utf-8)
                                  ;;@MAYBE: extract this to a global variable.
                                  (notedir "~/nc/org/notes/")
                                  (project-root (projectile-project-root))
                                  (name (concat (file-name-base (directory-file-name project-root)) ".org"))
                                  (path (expand-file-name name (file-truename notedir))))
                            (with-current-buffer (find-file-noselect path)
                              (unless (derived-mode-p 'org-mode) (org-mode)
                                  ;;set to utf-8 because we may be visiting raw file
                                  (setq buffer-file-coding-system 'utf-8-unix))
                              (when-let ((headline (doct-get :headline)))
                                  (unless (org-find-exact-headline-in-buffer headline)
                                      (goto-char (point-max))
                                      (insert "* " headline)
                                      (org-set-tags (downcase headline))))
                              (unless (file-exists-p path) (write-file path))
                              path)))
                :template
                  (lambda () (concat  "* %{todo-state} " (when (y-or-n-p "Link? ") "%A\n") "%?"))
                :todo-state "TODO"
                :children
                  (("bug" :keys "b" :headline "Bug")
                    ("design"        :keys "d" :headline "Design")
                    ("documentation" :keys "D" :headline "Documentation")
                    ("enhancement"   :keys "e" :headline "Enhancement" :todo-state "IDEA")
                    ("feature"       :keys "f" :headline "Feature"     :todo-state "IDEA")
                    ("optimization"  :keys "o" :headline "Optimization")
                    ("miscellaneous" :keys "m" :headline "Miscellaneous")
                    ("security"      :keys "s" :headline "Security")))
              ("Play"
                :keys "p"
                :id "be517275-3779-477f-93cb-ebfe0204b614"
                :hook +org-capture-todo
                :template "%(wikinforg-capture \"game\")")
              ("Read"
                :keys "r"
                :template "%(wikinforg-capture \"book\")"
                :hook +org-capture-todo
                :children
                  (("fiction"
                    :keys "f"
                    :id "0be106fc-a920-4ab3-8585-77ce3fb793e8")
                   ("non-fiction"
                    :keys "n"
                    :id "73c29c94-fb19-4012-ab33-f51158c0e59b")))
              ("Say"
               :keys "s"
               :children (("word" :keys "w"
                           :id "55e43a15-5523-49a6-b16c-b6fbae337f05"
                           :template ("* %^{Word}" "%?"))
                          ("Phrase" :keys "p"
                           :id "c3dabe22-db69-423a-9737-f90bfc47238a"
                           :template ("* %^{Phrase}" "%?"))
                          ("Quote" :keys "q"
                           :id "8825807d-9662-4d6c-a28f-6392d3c4dbe2"
                           :template ("* %^{Quote}" "%^{Quotee}p"))))
              ("Todo" :keys "t"
                :id "0aeb95eb-25ee-44de-9ef5-2698514f6208"
                :hook (lambda ()
                        (+org-capture-property-drawer)
                        ;;swallow org-todo quit so we don't abort the whole capture
                        (condition-case nil (org-todo) (quit nil)))
                :properties ((Created "%U"))
                :template ("* %^{description} %^g" "%?"))
              ("use-package" :keys "u"
               :file ,(expand-file-name "init.org" user-emacs-directory)
               :function
                 ,(defun +my/org-capture-use-package-form ()
                    "place point for use-package capture template."
                    (org-fold-show-all)
                    (goto-char (org-find-entry-with-id "f8affafe-3a4c-490c-a066-006aeb76f628"))
                    (org-narrow-to-subtree)
                    ;;popping off parent headline, evil and general.el since they are order dependent.
                    (when-let* ((name (read-string "package name: "))
                                (headlines (nthcdr 4 (caddr (org-element-parse-buffer 'headline 'visible))))
                                (packages (mapcar (lambda (headline) (cons (plist-get (cadr headline) :raw-value)
                                                                           (plist-get (cadr headline) :contents-end)))
                                                  headlines))
                                (target (let ((n (downcase name)))
                                          (cdr
                                           (cl-some (lambda (package) (and (string-greaterp n (downcase (car package))) package))
                                                    (nreverse packages))))))
                      ;;put name on template's doct plist
                      (setq org-capture-plist
                            (plist-put org-capture-plist :doct
                                       (plist-put (org-capture-get :doct) :use-package name)))
                      (goto-char target)
                      (org-end-of-subtree)
                      (open-line 1)
                      (forward-line 1)))
               :type plain
               :empty-lines-after 1
               :template ("** %(doct-get :use-package)"
                          "#+begin_quote"
                          "%(read-string \"package description:\")"
                          "#+end_quote"
                          "#+begin_src emacs-lisp"
                          "(use-package %(doct-get :use-package)%?)"
                          "#+end_src"))
              ("Watch":keys "w"
               :template "%(wikinforg-capture \"%{entity}\")"
               :hook +org-capture-todo
               :children
                 (("Film" :keys "f" :id "a730a2db-7033-40af-82c1-9b73528ab7d9" :entity "film")
                  ("TV" :keys "t" :id "4a18a50e-909e-4d36-aa7a-b09e8c3b01f8" :entity "show")
                  ("Presentation" :keys "p" :id "343fe4f4-867a-4033-b31a-8b57aba0345e"
                    :template "* %^{Title} %^g %^{Year}p"))))))

    ;; ews
    (push
      '(("f" "Fleeting note [EWS]"
          item
          (file+headline org-default-notes-file "Notes")
          "- %?")
        ("t" "New task" entry
          (file+headline org-default-notes-file "Tasks")
          "* TODO %i%?"))
      org-capture-templates)


    (define-advice org-capture-fill-template (:around (fn &rest args) comma-for-crm)
      (advice-add #'completing-read-multiple :around #'+my/org-tags-crm)
      (apply fn args))

    (when (or (bound-and-true-p ce-example-use-evil-escape)
              (bound-and-true-p prot-emacs-load-evil))
        (add-hook 'org-capture-mode-hook #'evil-insert-state))

    (defun +my/org-capture-delete-frame (&rest _args)
      "Delete frame with a name frame-parameter set to \"capture\""
      (when (and (daemonp) (string= (frame-parameter (selected-frame) 'name) "capture"))
          (delete-frame)))
    (add-hook 'org-capture-after-finalize-hook #'+my/org-capture-delete-frame 100)

    (defun +my/org-capture-make-frame ()
      "Create a new frame and run org-capture."
      (interactive)
      (select-frame-by-name "capture")
      (delete-other-windows)
      (cl-letf (((symbol-function 'switch-to-buffer-other-window) #'switch-to-buffer))
        (condition-case err
            (org-capture)
          ;; "q" signals (error "Abort") in `org-capture'
          ;; delete the newly created frame in this scenario.
          (user-error (when (string= (cadr err) "Abort") (delete-frame)))))))
;;; }}} *** org-capture

;;; {{{ *** org-expiry
(use-feature org-expiry
  :after (org)
  ;; Chronological entries with org-expiry

  ;; org-brain doesn’t add any information on when entries are created, so it is hard get a list of your entries in chronological order. I’ve managed to use org-expiry (part of org-plus-contrib) to add a CREATED property to all org-brain headline entries. Then we can use org-agenda to show the entries in chronological order.

  ;; Setup org-expiry and define a org-agenda function to compare timestamps
  :custom
    (org-expiry-inactive-timestamps t))
;;; }}} *** org-expiry

;;; {{{ *** org-fragtog
(use-feature org-fragtog
  :after (org)
  :custom
    (org-format-latex-options
      '(:foreground default :background default :scale 1.0
        :html-foreground "Black" :html-background "Transparent" :html-scale 1.0
        :matchers ("begin" "$1" "$" "$$" "\\(" "\\[")))
      ;; (plist-put org-format-latex-options :background 'auto)
      ;; (plist-put org-format-latex-options :foreground 'auto)
      ;; (plist-put org-format-latex-options :scale 2))
  :config
    (add-hook 'org-mode-hook        #'org-fragtog-mode))
;;; }}} *** org-fragtog

;;; {{{ *** org-habit
(use-feature org-habit
  :after (org)
  :custom
    (org-habit-completed-glyph #x2713)
    (org-habit-following-days 1)
    (org-habit-graph-column 3)
    (org-habit-preceding-days 29)
    (org-habit-show-habits-only-for-today nil)
    (org-habit-today-glyph #x1f4c5)
  :config
    (defun +my/org-habit-graph-on-own-line (graph)
      "Place org habit consitency graph below the habit."
      (let* ( (count 0)
              icon)
        (save-excursion
          (beginning-of-line)
          (while (and (eq (char-after) ? ) (not (eolp)))
            (when (get-text-property (point) 'display) (setq icon t))
            (setq count (1+ count))
            (forward-char)))
        (add-text-properties
          (+ (line-beginning-position) count)
          (line-end-position)
          `(display ,(concat
                      (unless icon "  ")
                      (string-trim-left (thing-at-point 'line))
                      (make-string (or org-habit-graph-column 0) ? )
                      (string-trim-right (propertize graph 'mouse-face 'inherit)))))))

    (defun +my/org-habit-insert-consistency-graphs (&optional line)
      "Insert consistency graph for any habitual tasks."
      (let (  (inhibit-read-only t)
              (buffer-invisibility-spec '(org-link))
              (moment (time-subtract nil (* 3600 org-extend-today-until))))
        (save-excursion
          (goto-char (if line (line-beginning-position) (point-min)))
          (while (not (eobp))
            (let ((habit (get-text-property (point) 'org-habit-p)))
              (when habit
                  (let
                    ((graph (org-habit-build-graph
                      habit
                      (time-subtract moment (days-to-time org-habit-preceding-days))
                      moment
                      (time-add moment (days-to-time org-habit-following-days)))))
                    (+my/org-habit-graph-on-own-line graph))))
            (forward-line)))))

    (advice-add #'org-habit-insert-consistency-graphs
      :override #'+my/org-habit-insert-consistency-graphs))
;;; }}} *** org-habit

;;; {{{ *** org-indent
(use-feature org-indent
  :after (org)
  :init
    (setopt +org-max-refile-level 20)
  :custom
    (+org-max-refile-level 20)
    (org-agenda-files '("~/nc/org/agenda/todo.org"))
    (org-agenda-text-search-extra-files '(agenda-archives))
    (org-confirm-babel-evaluate nil)
    (org-duration-format '(("h" . nil) (special . 2)))      ;;(org-duration-format  '(h:mm))
    (org-enforce-todo-dependencies t)
    (org-file-apps '((auto-mode . emacs) ("\\.mm\\'" . default) ("\\.mp[[:digit:]]\\'" . "/usr/bin/mpv --force-window=yes %s") ("\\.x?html?\\'" . "/usr/bin/bash -c '$BROWSER  %s'") ("\\.pdf\\'" . default)))
    (org-fold-catch-invisible-edits 'show-and-error)
    (org-hide-emphasis-markers t)
    (org-hierarchical-todo-statistics nil)
    (org-log-done 'time)
    (org-log-reschedule t)
    (org-outline-path-complete-in-steps nil)
    (org-refile-allow-creating-parent-nodes 'confirm)
    (org-refile-targets `((org-agenda-files :maxlevel . ,+org-max-refile-level) (+org-files-list  :maxlevel . ,+org-max-refile-level)))
    (org-refile-use-outline-path 'file)
    (org-return-follows-link t)
    (org-reverse-note-order t)
    (org-src-tab-acts-natively t)
  :config
    (add-hook 'org-mode-hook        #'org-indent-mode)
    (define-advice org-indent-refresh-maybe (:around (fn &rest args) "when-buffer-visible")
      "Only refresh indentation when buffer's window is visible.
Speeds up `org-agenda' remote operations."
        (when (get-buffer-window (current-buffer) t) (apply fn args)))

    (defun +my/org-files-list ()
      "Returns a list of the file names for currently open Org files"
      (delq nil
            (mapcar (lambda (buffer)
                      (when-let* ((file-name (buffer-file-name buffer))
                                  (directory (file-name-directory file-name)))
                          (unless (string-suffix-p "archives/" directory)
                              file-name)))
                    (org-buffer-list 'files t)))))
;;; }}} *** org-indent

;;; {{{ **** ox-latex
(use-feature ox-latex
  :after (org)
  :custom
    ;; Clean temporary files after export
    (org-latex-logfiles-extensions
      (quote ("lof" "lot" "tex~" "aux" "idx" "log" "out"
              "toc" "nav" "snm" "vrb" "dvi" "fdb_latexmk"
              "blg" "brf" "fls" "entoc" "ps" "spl" "bbl"
              "tex" "bcf")))
    ;; Multiple LaTeX passes for bibliographies
    (org-latex-pdf-process
      '("pdflatex -interaction nonstopmode -output-directory %o %f"
        "bibtex %b"
        "pdflatex -shell-escape -interaction nonstopmode -output-directory %o %f"
        "pdflatex -shell-escape -interaction nonstopmode -output-directory %o %f"))
  :config
    ;; CRC Publishing template
    (add-to-list
      'org-latex-classes
      '("crc"
          "\\documentclass[krantz2]{krantz}
           \\usepackage{lmodern}
           \\usepackage[authoryear]{natbib}
           \\usepackage{nicefrac}
           \\usepackage[bf,singlelinecheck=off]{caption}
           \\captionsetup[table]{labelsep=space}
           \\captionsetup[figure]{labelsep=space}
           \\usepackage{Alegreya}
           \\usepackage[scale=.8]{sourcecodepro}
           \\usepackage[breaklines=true]{minted}
           \\usepackage{rotating}
           \\usepackage[notbib, nottoc,notlot,notlof]{tocbibind}
           \\usepackage{amsfonts, tikz, tikz-layers}
           \\usetikzlibrary{fadings, quotes, shapes, calc, decorations.markings}
           \\usetikzlibrary{patterns, shadows.blur}
           \\usetikzlibrary{shapes,shapes.geometric,positioning}
           \\usetikzlibrary{arrows, arrows.meta, backgrounds}
           \\usepackage{imakeidx} \\makeindex[intoc]
           \\renewcommand{\\textfraction}{0.05}
           \\renewcommand{\\topfraction}{0.8}
           \\renewcommand{\\bottomfraction}{0.8}
           \\renewcommand{\\floatpagefraction}{0.75}
           \\renewcommand{\\eqref}[1]{(Equation \\ref{#1})}
           \\renewcommand{\\LaTeX}{LaTeX}"
        ("\\chapter{%s}" . "\\chapter*{%s}")
        ("\\section{%s}" . "\\section*{%s}")
        ("\\subsection{%s}" . "\\subsection*{%s}")
        ("\\subsubsection{%s}" . "\\paragraph*{%s}"))))
;;; }}} **** ox-latex
;;; }}} *** org

;;; {{{ *** paren
;; I want to have matching delimiters highlighted when point is on them so that I
;; can make sure they're balanced easily.
(use-feature paren
  :config (show-paren-mode t))
;;; }}} *** paren

;;; {{{ *** pulse-line
(use-feature pulse-line
  :config
    ;; add visual pulse when changing focus, like beacon but built-in
    ;; from from https://karthinks.com/software/batteries-included-with-emacs/
    (defun +my/pulse-line (&rest _)
      "Pulse the current line."
      (pulse-momentary-highlight-one-line (point)))

    (dolist
      (command
        '(other-window
          recenter-top-bottom
          scroll-down-command
          scroll-up-command))
      (advice-add command :after #'+my/pulse-line)))
;;; }}} *** pulse-line

;;; {{{ *** re-builder (regular expressions)
;; Emacs has a horrible regexp syntax. A tool called re-builder allows you to
;; live preview regular expressions. This variable reduces some of the escaping
;; necessary when building regular expressions.
(use-feature re-builder
  :custom
    (reb-re-syntax 'rx)
  :commands (re-builder))
;;; }}} *** re-builder (regular expressions)

;;; {{{ *** recentf mode
(use-feature recentf
  :custom
    (recentf-max-menu-items 1000 "Offer more recent files in menu")
    (recentf-max-saved-items 1000 "Save more recent files")
    (recentf-save-file (no-littering-expand-var-file-name "recentf") "no-littering `recentf-save-file'")
  ;; :bind (
  ;;   ("C-c w r"      . recentf-open))
  :config
    (add-to-list 'recentf-exclude (recentf-expand-file-name no-littering-etc-directory))
    (add-to-list 'recentf-exclude (recentf-expand-file-name no-littering-var-directory))
    (recentf-mode t))
;;; }}} *** recentf mode

;;; {{{ *** save-place
(use-feature saveplace
  :custom
    (save-place-file (no-littering-expand-var-file-name "places") "no-littering `save-place-file'")
  :config
    (save-place-mode t))
;;; }}} *** save-place

;;; {{{ *** savehist-mode for command history
(use-feature savehist
  :custom
    (savehist-autosave-interval (* 5 60))
    (savehist-file (no-littering-expand-var-file-name "history") "no-littering `savehist-file'")
    (savehist-save-minibuffer-history t)
  :config
    (add-to-list 'savehist-additional-variables 'kill-ring)
    (add-to-list 'savehist-additional-variables 'regexp-search-ring)
    (add-to-list 'savehist-additional-variables 'register-alist)
    (add-to-list 'savehist-additional-variables 'search-ring)
    (savehist-mode t))
;;; }}} *** savehist-mode for command history

;;; {{{ *** sendmail
(use-feature sendmail
  :custom
    (send-mail-function 'smtpmail-send-it "inform emacs-bug-report how we want to send mail"))
;;; }}} *** sendmail

;;; {{{ *** server
(use-feature server
  :demand t
  :config
    ;; If you are a dedicated Emacs user, you should set up the Emacs server so that new requests are handled by the original process. This means that almost no time is spent in handling the request (assuming an Emacs process is already running). For this to work, you need to set your EDITOR environment variable to ‘emacsclient’. The code below, supplied by Francois Pinard, can then be used in your .emacs file to enable the server:

    ;; (defvar server-buffer-clients)
    ;; (when (and (fboundp 'server-start) (string-equal (getenv "TERM") 'xterm))
    ;;     (server-start)
    ;;     (defun +my/kill-server-with-buffer-routine ()
    ;;       (and server-buffer-clients (server-done)))
    ;;     (add-hook 'kill-buffer-hook   #'+my/kill-server-with-buffer-routine))

    ;; You can also set the value of this editor via the commmand-line option ‘-editor’ or in your ipythonrc file. This is useful if you wish to use specifically for IPython an editor different from your typical default (and for Windows users who tend to use fewer environment variables).

    (defun +my/server-started-p ()
      "Return non-nil if this Emacs has a server started."
      (and (boundp server-process) server-process))

    (defun +my/frame-title ()
      "Set a custom frame title."
      (setq frame-title-format
            (concat "%b %f"
                    (when (or (+my/server-started-p) (daemonp))
                        (concat " " server-name)))))

    (unless (or (+my/server-started-p) (daemonp))
        (add-hook 'elpaca-after-init-hook       'server-start))

    ;; Run the hook to call the function while starting
    (add-hook 'elpaca-after-init-hook   ;;'emacs-startup-hook
              (lambda ()
                "Functions to call after loading init files."
                (+my/frame-title)))

    ;; Call the function after entering or leaving 'server-mode'
    (add-hook 'server-mode-hook
              (lambda ()
                "Functions to apply after entering or leaving 'server-mode'."
                (+my/frame-title)))

    ;; {{{ **** signal-restart-server
    ;; + Isolated server, impossible to connect
    ;;
    ;; There are unfortunate possibilities of being unable to connect to a
    ;; running server>.
    ;; This has been observed as:
    ;; 1) the server being stopped and then all visible frames closed
    ;;     (e.g. server-force-delete + ssh disconnect);
    ;; 2) the server socket file being deleted. There may be other examples.
    ;;
    ;; It may be possible to connect to the process with gdb and then call some
    ;; function to execute lisp code to restart the server.
    ;; If anyone knows how to do that, please insert that information here.
    ;;
    ;; We don’t know how to re-connect to the running server in vanilla emacs but
    ;; here is a workaround, which sets up a signal handler to restart the server.
    ;; Add the following to your emacs startup elisp:
    (defun +my/signal-restart-server ()
      "Handler for SIGUSR1 signal, to (re)start an emacs server.\n\nCan be tested from within emacs with:\n  `(signal-process     (emacs-pid) 'sigusr1)'\n\n or from the command line with:\n  `$ kill -USR1 <emacs-pid>'\n  `$ emacsclient -c'"
      (interactive)
      (server-force-delete)
      (server-start))

    (define-key special-event-map [sigusr1] #'+my/signal-restart-server)
    ;; Once that code has been loaded, sending a USR1 to the emacs process will
    ;; restart the server. You can now reconnect. Joy.
    ;; }}} **** signal-restart-server

    ;;; {{{ **** modified-buffers-exist
    (defun +my/modified-buffers-exist-p()
      "This function will check to see if there are any buffers that have been modified.\n  It will return `t'rue if there are and `nil' otherwise.\n  Buffers that have buffer-offer-save set to nil are ignored."
      (let ((modified-found nil))
        (dolist (buffer (buffer-list))
          (when (and (buffer-live-p buffer)
                  (buffer-modified-p buffer)
                  (not (buffer-base-buffer buffer))
                  (or (buffer-file-name buffer)
                    (progn
                      (set-buffer buffer)
                      (and buffer-offer-save (> (buffer-size) 0)))))
              (setq modified-found t)))
        modified-found))
    ;;; }}} **** modified-buffers-exist

    ;;; {{{ **** client-save-kill-emacs
    ;; If you would like emacs to prompt if there are unsaved buffers
    ;; or existing clients/frames, you can add the following functions to your
    ;; .emacs file then use the command:

    ;;     emacsclient -e '(client-save-kill-emacs)'

    ;; The display on which the new frame should be opened can optionally, be
    ;; specified.
    ;; If a prompt is required, this function will always open a frame as an X
    ;; window.

    (defun +my/client-save-kill-emacs(&optional display)
      "This is a function that can bu used to save buffers and shutdown the emacs daemon.\n It should be called using\n     `emacsclient -e '(client-save-kill-emacs)''. \nThis function will check to see if there are any modified buffers, active     clients or frame. \nIf so, an x window will be opened and the user will be prompted."
      (let (new-frame modified-buffers active-clients-or-frames)
        ;; Check if there are modified buffers, active clients or frames.
        (setq modified-buffers (modified-buffers-exist-p))
        (setq active-clients-or-frames ( or (> (length server-clients) 1)
                                            (> (length (frame-list)) 1)))

        ;; Create a new frame if prompts are needed.
        (when (or modified-buffers active-clients-or-frames)
            (when (not (eq window-system 'x))
                (message "Initializing x windows system.")
                (x-initialize-window-system))
            (when (not display) (setq display (getenv "DISPLAY")))
            (message "Opening frame on display: %s" display)
            (select-frame (make-frame-on-display display '((window-system . x)))))

        ;; Save the current frame.
        (setq new-frame (selected-frame))

        ;; When displaying the number of clients and frames:
        ;; subtract 1 from clients (this client).
        ;; subtract 2 from frames (the frame just created and the default frame.)
        (when (or (not active-clients-or-frames)
                  (yes-or-no-p
                    (format "There are currently %d clients and %d frames. Exit anyway?"
                            (- (length server-clients) 1)
                            (- (length (frame-list)) 2))))
            ;; If the user quits during the save dialog then don't exit emacs.
            ;; Still close the terminal though.
            (let ((inhibit-quit t))
              ;; Save buffers
              (with-local-quit
                (save-some-buffers))
              (if quit-flag
                  (setq quit-flag nil)
                  ;; Kill all remaining clients
                  (progn
                    (dolist (client server-clients)
                      (server-delete-client client))
                      ;; Exit emacs
                    (kill-emacs)))))

        ;; If we made a frame then kill it.
        (when (or modified-buffers active-clients-or-frames)
            (delete-frame new-frame)))))
    ;;; }}} **** client-save-kill-emacs
;;; }}} *** server

;;; {{{ *** shr
(use-feature shr
  :defer t
  :custom
    (shr-cookie-policy nil)
    (shr-discard-aria-hidden t)
    (shr-image-animate t)
    (shr-max-image-proportion 0.6)
    (shr-max-width fill-column)
    (shr-use-colors t)                    ;; t is bad for accessibility
    (shr-use-fonts t)
    (shr-width fill-column)
    (url-cookie-uness-url-face 'link))
;;; }}} *** shr

;;; {{{ *** shr-color
(use-feature shr-color
  :custom
    (shr-color-visible-luminance-min 85 "For clearer email/eww rendering of bg/fg colors")
    (shr-use-colors nil "Don't use colors (for HTML email legibility)"))
;;; }}} *** shr-color

;;; {{{ ** simple
(use-feature simple
  :custom
    (eval-expression-debug-on-error nil)
    (fill-column 120 "Wrap at 120 columns."))
;;; }}} ** simple

;;; {{{ *** smtpmail
(use-feature smtpmail
  :custom
    (smtpmail-queue-mail nil))
;;; }}} *** smtpmail

;;; {{{ *** speedbar
(use-feature speedbar
  :custom
    ;;; Look & Feel
    ;; Auto-update when the attached frame changes directory
    (speedbar-update-flag t)
    ;; Disable icon images, instead use text
    (speedbar-use-images t)     ;; nil)
    ;; Customize Speedbar Frame
    (speedbar-frame-parameters
      '((name . "speedbar")
        (title . "speedbar")
        (border-width . 2)
        (left-fringe . 10)
        (menu-bar-lines . 0)
        (minibuffer . nil)
        (tool-bar-lines . 0)
        (unsplittable . t)))
  :config
    ;;; Keybindings
    (defun +my/speedbar-switch-to-quick-buffers ()
      "Temporarily switch to quick-buffers expansion list.
Useful for quickly switching to an open buffer."
      (interactive)
      (speedbar-change-initial-expansion-list "quick buffers"))

    ;; map switch-to-quick-buffers in speedbar-mode
    (keymap-set speedbar-mode-map "b" #'+my/speedbar-switch-to-quick-buffers)

    ;;; File Extensions
    (speedbar-add-supported-extension
      (list
        ;;;; General Lisp Languages
        ".cl"
        ".li?sp"
        ;;;; Lua/Fennel (Lisp that transpiles to lua)
        ".fennel"
        ".fnl"
        ".lua"
        ;;;; JVM languages (Java, Kotlin, Clojure)
        ".cljs?"
        ".gradle"
        ".kt"
        ".mvn"
        ".properties"
        ;;;; shellscript
        ".bash"
        ".sh"
        ;;;; Web Languages and Markup/Styling
        ".css"
        ".html?"
        ".less"
        ".php"
        ".sass"
        ".scss"
        ".ts"
        ;;;; Makefile
        "MAKEFILE"
        "Makefile"
        "makefile"
        ;;;; Data formats
        ".json"
        ".toml"
        ".yaml"
        ;;;; Notes and Markup
        ".markdown"
        ".md"
        ".org"
        ".txt"
        "README")))
;;; }}} *** speedbar

;;; {{{ *** speedo-review
(use-feature speedo-review
  :bind (
    :map speedo-review-mode-map
      ("C-c C-c" . speedo-review-quit)
      ("C-c C-k" . speedo-review-quit)
      ("C-c C-n" . speedo-review-next)
      ("C-c C-p" . speedo-review-previous)
      ("C-c C-r" . speedo-review-retry)
      ("C-c C-s" . speedo-review-suspend)
      ("C-c C-u" . speedo-review-unsuspend)
      ("C-c C-v" . speedo-review-verify)
      ("C-c C-w" . speedo-review-wrong)
      ("C-c C-x" . speedo-review-exit)
      ("C-c C-z" . speedo-review-suspend)
      ("C-c C-SPC" . speedo-review-toggle-remember))
  :config
    (evil-make-intercept-map speedo-review-mode-map))
;;; }}} *** speedo-review

;;; {{{ *** speedo-edit
(use-feature speedo-edit
  :config
    (evil-make-intercept-map speedo-edit-mode-map))
;;; }}} *** speedo-edit

;;; {{{ *** tab-bar
(use-feature tab-bar
  :init
    (defun +my/tab-bar-move-tab-left (arg)
      "Move selected tab left."
      (interactive "p")
      (tab-bar-move-tab (- arg)))
    (defun +my/tab-bar-move-tab-right (arg)
      "Move selected tab left."
      (interactive "p")
      (tab-bar-move-tab (arg)))
  :custom
    (tab-bar-close-button-show nil "Dont' show the x button on tabs")
    (tab-bar-new-button-show   nil)
    (tab-bar-show   1 "only show tab bar when more than one tab")
  ;; :bind (
  ;;   :map tab-bar-mode-map
  ;;     ("C-x C-#"    . tab-bar-select-tab-by-number)
  ;;     ("C-x C-~"    . tab-bar-select-tab-by-name)
  ;;     ("C-x C-b"    . tab-bar-history-back)
  ;;     ("C-x C-d"    . tab-bar-close-tab)
  ;;     ("C-x C-f"    . tab-bar-history-forward)
  ;;     ;;("C-x C-H"    . +my/tab-bar-move-tab-left arg)
  ;;     ("C-x C-h"    . tab-bar-switch-to-prev-tab)
  ;;     ;;("C-x C-L"    . +my/tab-bar-move-tab-right arg)
  ;;     ("C-x C-l"    . tab-bar-switch-to-next-tab)
  ;;     ("C-x C-N"    . tab-bar-new-tab-to)
  ;;     ("C-x C-n"    . tab-bar-switch-to-next-tab)
  ;;     ("C-x C-O"    . tab-bar-close-other-tabs)
  ;;     ("C-x C-o"    . tab-bar-close-tab-other)
  ;;     ("C-x C-p"    . tab-bar-switch-to-prev-tab)
  ;;     ("C-x C-r"    . tab-bar-rename-tab)
  ;;     ("C-x C-T"    . tab-bar-switch-to-tab)
  ;;     ("C-x C-t"    . tab-bar-new-tab)
  ;;     ("C-x C-u"    . tab-bar-undo-close-tab)
  ;;     ("C-x C-W"    . tab-bar-move-tab-to-frame)
  ;;     ("C-x C-w"    . tab-bar-close-tab))
  )
;;; }}} *** tab-bar

;;; {{{ *** tab-line
(use-feature tab-line
  :custom
    (tab-line-close-button-show nil)
    (tab-line-new-button-show   nil))
;;; }}} *** tab-line

;;; {{{ *** text-mode
(use-feature text-mode
  :init
    (delete-selection-mode t)
  :custom
    (save-interprogram-paste-before-kill t)
    (scroll-error-top-bottom t)
  :hook (
    (text-mode-hook   . visual-line-mode)))
;;; }}} *** text-mode

;;; {{{ *** time
;; I like to see the date and time in my mode line.
;; I use doom-modeline for the rest of my mode line configuration.
(use-feature time
  :custom
    (display-time-format "%FT%Tz%z")
    ;;;; Covered by `display-time-format'
    (display-time-day-and-date t "Show date, day, and time")
    (display-time-default-load-average nil)
    (display-time-24hr-format t)
    (display-time-interval 1)
    ;; NOTE 2022-09-21: For all those, I have implemented my own solution
    ;; that also shows the number of new items, although it depends on
    ;; notmuch: the `notmuch-indicator' package.
    (display-time-mail-directory nil)
    (display-time-mail-face nil)
    (display-time-mail-function nil)
    (display-time-mail-string nil)
    (display-time-use-mail-icon nil)
    ;; I don't need the load average and the mail indicator, so let this
    ;; be simple:
    (display-time-string-forms
      '((propertize
          (format-time-string display-time-format now)
          'face 'mode-line-highlight
          'help-echo (format-time-string "%a %b %e %Y %Z" now))
          " "))
  :config
    (setq-default display-time-format "%F%t%R %z")
    (display-time-mode t)
    (display-time))
;;; }}} *** time

;;; {{{ *** tramp
(use-feature tramp
  :custom
    (debug-ignored-errors (cons 'remote-file-error debug-ignored-errors))
    (tramp-connection-timeout (* 10 60))
    (tramp-terminal-type "tramp"))
;; ;;; }}} *** tramp

;;; {{{ *** treesit
(use-feature treesit
  ;; :mode (("\\.tsx\\'" . tsx-ts-mode))
  :config
    (defun +my/ide--configure-tree-sitter-pre-29 ()
      "Configure tree-sitter for Emacs 28 or earlier."

      (defun +my/tree-sitter-load (lang-symbol)
        "Setup tree-sitter for a language.

This must be called in the user's configuration to configure
tree-sitter for LANG-SYMBOL.

Example: `(+my/tree-sitter-load 'python)'"
        (tree-sitter-require lang-symbol)
        (let ((mode-hook-name
               (intern (format "%s-mode-hook" (symbol-name lang-symbol)))))
          (add-hook mode-hook-name #'tree-sitter-mode))))

    (defun +my/ide--configure-tree-sitter (opt-in-only)
      "Configure tree-sitter for Emacs 29 or later.

OPT-IN-ONLY is a list of symbols of language grammars to
auto-install instead of all grammars."
      ;; only attempt to use tree-sitter when Emacs was built with it.
      (when (member "TREE_SITTER" (split-string system-configuration-features))
          (when (require 'treesit-auto nil :noerror)
              ;; add all items of opt-in-only to the `treesit-auto-langs'.
              (when opt-in-only
                  ;; (mapc (lambda (e) (add-to-list 'treesit-auto-langs e)) opt-in-only)
                  (if (listp opt-in-only)
                      (customize-set-variable 'treesit-auto-langs opt-in-only)
                    (customize-set-variable 'treesit-auto-langs (list opt-in-only))))
              (add-to-list 'treesit-extra-load-path (expand-file-name (no-littering-expand-etc-file-name "treesitter/")))
              (delete 'janet treesit-auto-langs)
              (delete 'latex treesit-auto-langs)
              ;; prefer tree-sitter modes
              (global-treesit-auto-mode t)
              ;; install all the tree-sitter grammars
              (treesit-auto-install-all)
              ;; configure `auto-mode-alist' for tree-sitter modes relying on
              ;; `fundamental-mode'
              (treesit-auto-add-to-auto-mode-alist))
          (when (locate-library "combobulate")
              ;; perhaps too gross of an application, but the *-ts-modes
              ;; eventually derive from this mode.
              (add-hook 'prog-mode-hook #'combobulate-mode))))

    (defun +my/ide-configure-tree-sitter (&optional opt-in-only)
      "Configure tree-sitter.

Requires a C compiler (gcc, cc, c99) installed on the system.
Note that OPT-IN-ONLY only affects setups with Emacs 29 or later.

For Emacs 29 or later:
Requires Emacs to be built using \"--with-tree-sitter\".
All language grammars are auto-installed unless they are a member
of OPT-IN-ONLY, in which case *only* those grammars are
installed."
      (if (version< emacs-version "29")
          (+my/ide--configure-tree-sitter-pre-29)
        (+my/ide--configure-tree-sitter opt-in-only)))

    ;; The first time you run Emacs with this enabled, the Rust tree
    ;; sitter parser will be installed for you automatically.
    (+my/ide-configure-tree-sitter))
;;; }}} *** treesit

;;; {{{ *** url
(use-feature url
  :custom
    (url-configuration-directory (no-littering-expand-etc-file-name "url") "no-littering `url-configuration-directory'")
    (url-cookie-file (no-littering-expand-var-file-name "url/cookies") "no-littering `url-cookie-file'"))
;;; }}} *** url

;;; {{{ *** vc-hooks
;; You probably want this 99% of the time and it will skip an annoying prompt.
(use-feature vc-hooks
  :custom
    (vc-follow-symlinks t "Visit real file when editing a symlink without prompting."))
;;; }}} *** vc-hooks

;;; {{{ *** winner
;; Turning on `winner-mode' provides an "undo" function for resetting
;; your window layout.  We bind this to `C-c w u' for winner-undo and
;; `C-c w r' for winner-redo (see below).
(use-feature winner
  :bind (
    :map winner-mode-map
      ("C-c w r" . winner-redo)
      ("C-c w u" . winner-undo))
  :config
    (winner-mode t))
;; ;;; }}} *** winner

;;; {{{ *** window
(use-feature window
  :custom
    (switch-to-buffer-obey-display-actions t)
    (switch-to-prev-buffer-skip-regexp '("\\*Help\\*" "\\*Calendar\\*" "\\*mu4e-last-update\\*" "\\*Messages\\*" "\\*scratch\\*" "\\magit-.*"))
  :init
    (defgroup +my/windows '()
      "Window related configuration for Crafted Emacs."
      :tag "Crafted Windows"
      :group 'my)

    (defcustom +my/windows-prefix-key "C-c w"
      "Configure the prefix key for window movement bindings.

Movement commands provided by `windmove' package, `winner-mode'
also enables undo functionality if the window layout changes."
      :group '+my/windows
      :type 'string)

    ;; Window configuration for special windows.
    (add-to-list 'display-buffer-alist
                  '("\\*Completions\\*"
                    (display-buffer-reuse-window display-buffer-pop-up-window)
                    (inhibit-same-window . t)
                    (window-height . 10)))
    (add-to-list 'display-buffer-alist
                  '("^\\*Dictionary\\*"
                    (display-buffer-in-side-window)
                    (side . left)
                    (window-width . 70)))
    (add-to-list 'display-buffer-alist
                  '("\\*Help\\*"
                    (display-buffer-reuse-window display-buffer-pop-up-window)
                    (inhibit-same-window . t)))
)
;;; }}} *** window

;;; }}} ** features


;; start every frame maximized
(add-to-list 'default-frame-alist '(fullscreen . maximized))
;; start every frame maximized
(add-to-list 'initial-frame-alist '(fullscreen . maximized))

;;
;; (elpaca-wait)
;;; }}} * Configuration phase


;;; _
(provide 'init)
;;; init.el ends here
