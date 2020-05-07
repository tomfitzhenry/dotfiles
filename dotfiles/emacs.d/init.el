(defun my-system-type-is-nixos ()
  (file-exists-p "/etc/NIXOS"))

(add-to-list 'load-path "~/.emacs.d/lisp/")

(require 'package)
; Don't grab from elsewhere.
(setq package-archives nil)

(eval-when-compile
  (require 'use-package))

;; prefer distro provided packages, for security/compatibility
(setq use-package-always-pin "manual")
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

(use-package beacon
  :config
  (beacon-mode 1))

(defun my/bookmark-jump-or-save ()
  (interactive)
  (let ((b (completing-read "Bookmark: " (bookmark-all-names))))
    (if (member b (bookmark-all-names))
	(bookmark-jump b)
      (bookmark-set b))))

(use-package bookmark
  :config
  (setq bookmark-save-flag 1)
  (global-set-key (kbd "<f2>") 'my/bookmark-jump-or-save))

(use-package desktop
  :config
  (setq desktop-dirname "~/.emacs.d")
  (desktop-save-mode 1))

(use-package diff-hl
  :config
  (global-diff-hl-mode))

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

(use-package imenu
  :config
  (global-set-key (kbd "C-c i") 'imenu))

(use-package ibuffer
  :config
  (global-set-key (kbd "C-x C-b") 'ibuffer))

(use-package ibuffer-project
  :config
 (add-hook 'ibuffer-hook
  (lambda ()
    (setq ibuffer-filter-groups (ibuffer-project-generate-filter-groups)))))

(use-package magit)

;; purges unused buffers at midnight
(use-package midnight)

(use-package nix-mode
  :if (my-system-type-is-nixos))

;; an fzf-like completion-style
(use-package orderless
  :init (icomplete-mode)
  :custom (completion-styles '(orderless)))

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

(defun my/project-name (p)
  (file-name-nondirectory (directory-file-name (car (project-roots p)))))

(defun my/project-shell ()
  (interactive)
  (let* ((p (project-current))
	 (sname (concat "sh: " (my/project-name p)))
	 (default-directory (car (project-roots p))))
    (shell sname)))

(use-package project
  :config
  (global-set-key (kbd "C-c p f") 'project-find-file)
  (global-set-key (kbd "C-c p x") 'my/project-shell)
  (global-set-key (kbd "C-c p s") 'project-find-regexp))

(use-package rfc-mode)

(defun my/comint-history ()
  (interactive)
  (let ((b (completing-read "Shell history: " (ring-elements comint-input-ring))))
    (insert b)))

(use-package shell
  :config
  (add-to-list 'evil-emacs-state-modes 'shell-mode)
  (global-set-key (kbd "C-c s") 'shell)
  :bind (:map shell-mode-map ("C-r" . 'my/comint-history)))

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
