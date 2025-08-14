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
;;; early-init.el ends here
