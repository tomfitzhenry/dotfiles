(defun my-system-type-is-nixos ()
  (file-exists-p "/etc/NIXOS"))

(add-to-list 'load-path "~/.emacs.d/lisp/")

; Don't grab from elsewhere.
(setq package-archives nil)

(eval-when-compile
  (require 'use-package))

;; prefer distro provided packages, for security/compatibility
(setq use-package-always-pin "manual")
(recentf-mode 1)
(global-hl-line-mode t)
; Reduce frequency of auto-revert interval from 5s to 20 minutes, to save battery. inotify will do most reverts anyway.
(setq auto-revert-interval (* 60 20))
(setq vc-follow-symlinks t)
(setq focus-follows-mouse t)
(setq mouse-autoselect-window t)
(global-auto-revert-mode t)
(setq make-backup-files nil)
(setq scroll-step            1
      scroll-conservatively  10000)
(setq column-number-mode t)

(use-package server
  :config
  (add-hook 'after-init-hook 'server-start t))

(goto-address-mode)

(require 'evil)
(evil-mode 1)

(use-package dired-async
  :config
  ; Useful for async copy commands, especially when copying over TRAMP
  (dired-async-mode))

;; No key bindings because avy can be used from swiper, by pressing C-'
(use-package avy)

(use-package beacon
  :config
  (beacon-mode 1))

(use-package bookmark
  :config
  (setq bookmark-save-flag 1)
  (global-set-key (kbd "<f2>") (lambda () (interactive) (counsel-bookmark))))

(use-package counsel)

(use-package desktop
  :config
  (setq desktop-dirname "~/.emacs.d")
  (desktop-save-mode 1))

(use-package eglot)

(use-package elfeed
  :config
  (add-to-list 'evil-emacs-state-modes 'elfeed-search-mode)
  (add-to-list 'evil-emacs-state-modes 'elfeed-show-mode))

(use-package flymake
  :config
  (define-key flymake-mode-map (kbd "M-n") 'flymake-goto-next-error)
  (define-key flymake-mode-map (kbd "M-p") 'flymake-goto-prev-error))

(use-package geiser)

(use-package ibuffer
  :config
  (global-set-key (kbd "C-x C-b") 'ibuffer))

(use-package ibuffer-project
  :config
 (add-hook 'ibuffer-hook
  (lambda ()
    (setq ibuffer-filter-groups (ibuffer-project-generate-filter-groups)))))

(use-package ivy
  :diminish
  :config
  (ivy-mode 1))

(use-package magit)

;; purges unused buffers at midnight
(use-package midnight)

(use-package nix-mode
  :if (my-system-type-is-nixos))

(use-package org
  :init
  (setq org-replace-disputed-keys t)
  :config
  (global-set-key "\C-cc" 'org-capture))

(use-package org-agenda
  :config
  (global-set-key (kbd "<f1>") (lambda () (interactive) (org-agenda nil "n")))
  (setq org-agenda-skip-scheduled-if-done t)
  (setq org-agenda-skip-deadline-if-done t)
  (setq org-agenda-show-future-repeats 'next)
  (setq org-agenda-todo-ignore-scheduled 'future)
  (global-set-key "\C-ca" 'org-agenda))

(use-package package-lint-flymake
  :config
  (add-hook 'emacs-lisp-mode-hook #'package-lint-flymake-setup))


(use-package project
  :config
  (global-set-key (kbd "C-c p f") 'project-find-file)
  (global-set-key (kbd "C-c p s") 'project-find-regexp))

(use-package rfc-mode)

(use-package shell
  :config
  (add-to-list 'evil-emacs-state-modes 'shell-mode)
  (global-set-key (kbd "C-c s") 'shell)
  :bind (:map shell-mode-map ("C-r" . counsel-shell-history)))

(use-package swiper
  :config
  (global-set-key "\C-s" 'swiper))

(use-package undo-tree
  :diminish
  :config
  (setq undo-tree-visualizer-timestamps t)
  (setq undo-tree-visualizer-diff t))

(use-package weechat
  :config
  (add-to-list 'evil-emacs-state-modes 'weechat-mode))

(use-package windmove
  :config
  (windmove-default-keybindings))

;; C-c left, to undo window configurations.
(use-package winner
  :config
  (winner-mode))

(use-package zenburn-theme
  :config
  (load-theme 'zenburn t))

(load (system-name))
