;;; s-a-c-evil-config.el --- Evil mode configuration -*- lexical-binding: t; -*-

;; Copyright (C) 2024
;; SPDX-License-Identifier: MIT

;; Author: s-a-c

;;; Commentary:

;; Evil mode configuration, for those who prefer `Vim' keybindings.

;;; Code:


;;; {{{ ** evil
(use-package evil
  :init
    (defun crafted-evil-vim-muscle-memory ()
      "Make a more familiar Vim experience.

Take some of the default keybindings for evil mode."
      (setq evil-want-C-i-jump t)
      (setq evil-want-Y-yank-to-eol t)
      (setq evil-want-fine-undo t))
  :custom
    (evil-undo-system 'undo-fu)     ;; 'undo-redo)
    ;; Set some variables that must be configured before loading the package
    (evil-respect-visual-line-mode t)
    (evil-want-C-h-delete t "C-h is backspace in insert state")
    (evil-want-C-i-jump t)
    (evil-want-Y-yank-to-eol t)
    (evil-want-fine-undo t)
    (evil-want-integration t)
    (evil-want-keybinding nil)

  :config
    (evil-mode nil)
    ;; Make evil search more like vim
    (evil-select-search-module 'evil-search-module 'evil-search)
    ;; Turn on Evil Nerd Commenter
    (evilnc-default-hotkeys)
    ;; Make C-g revert to normal state
    (keymap-set evil-insert-state-map "C-g" 'evil-normal-state)
    ;; Rebind `universal-argument' to 'C-M-u' since 'C-u' now scrolls the buffer
    (keymap-global-set "C-M-u" 'universal-argument)
    ;; Use visual line motions even outside of visual-line-mode buffers
    (evil-global-set-key 'motion "j" 'evil-next-visual-line)
    (evil-global-set-key 'motion "k" 'evil-previous-visual-line)

    (defun crafted-evil-discourage-arrow-keys ()
      "Turn on a message to discourage use of arrow keys.

Rebinds the arrow keys to display a message instead."
      (defun crafted-evil-discourage-arrow-keys ()
        (message "Use HJKL keys instead!"))

      ;; Disable arrow keys in normal and visual modes
      (keymap-set evil-normal-state-map "<left>"  #'crafted-evil-discourage-arrow-keys)
      (keymap-set evil-normal-state-map "<right>" #'crafted-evil-discourage-arrow-keys)
      (keymap-set evil-normal-state-map "<down>"  #'crafted-evil-discourage-arrow-keys)
      (keymap-set evil-normal-state-map "<up>"    #'crafted-evil-discourage-arrow-keys)
      (evil-global-set-key 'motion      (kbd "<left>")  #'crafted-evil-discourage-arrow-keys)
      (evil-global-set-key 'motion      (kbd "<right>") #'crafted-evil-discourage-arrow-keys)
      (evil-global-set-key 'motion      (kbd "<down>")  #'crafted-evil-discourage-arrow-keys)
      (evil-global-set-key 'motion      (kbd "<up>")    #'crafted-evil-discourage-arrow-keys))

    (with-eval-after-load 'magit
      ;; optional: this is the evil state that evil-magit will use
      ;; (setq evil-magit-state 'normal)
      ;; optional: disable additional bindings for yanking text
      ;; (setq evil-magit-use-y-for-yank nil)
      (require 'evil-magit))

    ;; Make sure some modes start in Emacs state
    ;; TODO: Split this out to other configuration modules?
    (dolist (mode '(custom-mode
                    eshell-mode
                    term-mode))
      (add-to-list 'evil-emacs-state-modes mode)))
;;; }}} ** evil

;;; {{{ ** evil-anzu
(use-package evil-anzu
  :after (anzu evil))
;;; }}} ** evil-anzu

;;; {{{ ** evil-collection
(use-package evil-collection
  :after (evil)
  :init
    (with-eval-after-load 'crafted-completion-config
      (when (featurep 'vertico)     ;; only if `vertico' is actually loaded.
          (keymap-set vertico-map "C-j" #'vertico-next)
          (keymap-set vertico-map "C-k" #'vertico-previous)
          (keymap-set vertico-map "M-h" #'vertico-directory-up)))
  :config
    (evil-collection-init))
;;; }}} ** evil-collection

;;; {{{ ** evil-escape
(when (bound-and-true-p ce-example-use-evil-escape)
  (use-package evil-escape
      :defer t
      :after (evil)
    :init
      ;; Prevent "jj" from escaping any mode other than insert-mode.
      (defun ce-evil-example/not-insert-state-p ()
        "Inverse of `evil-insert-state-p`"
        (not (evil-insert-state-p)))
    :custom
      ;; Configure `evil-escape' with the preferred key combination "jj".
      (evil-escape-key-sequence (kbd "jj"))

      ;; Allow typing "jj" literally without exiting from insert-mode
      ;; if the keys are pressed 0.2s apart.
      (evil-escape-delay 0.2)

      ;; Prevent "jj" from escaping any mode other than insert-mode.
      (evil-escape-inhibit-functions (list #'ce-evil-example/not-insert-state-p))
    :config
      (evil-escape-mode)))
;;; }}} ** evil-escape

;;; {{{ ** evil-nerd-commenter
(use-package evil-nerd-commenter
  :config
    (evilnc-default-hotkeys))
;;; }}} ** evil-nerd-commenter

;;; {{{ ** evil-org
(use-package evil-org
  :after (evil org)
  :hook (
    (org-mode-hook  . (lambda () evil-org-mode)))
  :config
    (require 'evil-org-agenda)
    (evil-org-agenda-set-keys))
;;; }}} ** evil-org

;;; {{{ ** evil-surround
(use-package evil-surround
  :config
    (global-evil-surround-mode 1))
;;; }}} ** evil-surround

;;; {{{ ** evil-tutor
(use-package evil-tutor
  :after (evil)
  :custom
    (evil-tutor-working-directory (no-littering-expand-var-file-name "evil-tutor") "no-littering `evil-tutor-working-directory'"))
;;; }}} ** evil-tutor


;;; _
(provide 's-a-c-evil-config)
;;; s-a-c-evil-config.el ends here
