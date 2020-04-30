(require 'package)

(defun my-system-type-is-nixos ()
  (file-exists-p "/etc/NIXOS"))

; Don't grab from elsewhere.
(setq package-archives nil)
(package-initialize)

(require 'use-package)
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
(desktop-save-mode 1)
(server-start)

(goto-address-mode)

(use-package bookmark
  :config
  (setq bookmark-save-flag 1)
  (global-set-key (kbd "<f2>") (lambda () (interactive) (counsel-bookmark))))

(use-package evil
  :config
  (evil-mode 1))

(load-theme 'zenburn t)

;; C-c left, to undo window configurations.
(use-package winner
  :config
  (winner-mode))

;; No key bindings because avy can be used from swiper, by pressing C-'
(use-package avy)

(use-package shell
  :config
  (add-to-list 'evil-emacs-state-modes 'shell-mode)
  (global-set-key (kbd "C-c s") 'shell)
  :bind (:map shell-mode-map ("C-r" . counsel-shell-history)))

(use-package flycheck
  :config
  (global-flycheck-mode))

(windmove-default-keybindings)

(use-package undo-tree
  :diminish
  :config
  (setq undo-tree-visualizer-timestamps t)
  (setq undo-tree-visualizer-diff t))

(use-package org
  :init
  (setq org-replace-disputed-keys t)
  :config
  (setq org-agenda-files '("~/sync/Misc"))
  (global-set-key (kbd "<f1>") (lambda () (interactive) (org-agenda nil "n")))
  (setq org-directory "~/docs/org/")
  (setq org-agenda-skip-scheduled-if-done t)
  (setq org-agenda-skip-deadline-if-done t)
  (setq org-todo-keywords '("TODO" "WAIT" "DONE"))
  (setq org-default-notes-file (concat org-directory "/notes.org"))
  (global-set-key "\C-cl" 'org-store-link)
  (global-set-key "\C-ca" 'org-agenda)
  (global-set-key "\C-cc" 'org-capture)
  (global-set-key "\C-cb" 'org-switchb))

;; purges unused buffers at midnight
(use-package midnight)

(use-package beacon
  :config
  (beacon-mode 1))

(use-package magit)

(use-package ivy
  :diminish
  :config
  (ivy-mode 1))

(use-package counsel)


(use-package projectile
  :config
  (projectile-global-mode 1)
  (define-key projectile-mode-map (kbd "C-c p") 'projectile-command-map))

(use-package ag)

(use-package swiper
  :config
  (global-set-key "\C-s" 'swiper))

(use-package which-key
  :diminish
  :config
  (which-key-setup-side-window-right-bottom)
  (which-key-mode 1))

(use-package elfeed
  :config
  (add-to-list 'evil-emacs-state-modes 'elfeed-search-mode)
  (add-to-list 'evil-emacs-state-modes 'elfeed-show-mode)
  (elfeed-load-opml "~/docs/feeds.opml"))

(use-package nix-mode
  :if (my-system-type-is-nixos))

(use-package geiser)

(use-package async
  :config
  ; Useful for async copy commands, especially when copying over TRAMP
  (dired-async-mode))

(use-package go-mode
  :config
  (add-to-list 'auto-mode-alist '("\\.go\\'" . go-mode)))

(use-package weechat
  :config
  (add-to-list 'evil-emacs-state-modes 'weechat-mode))

(add-to-list 'load-path "~/.emacs.d/lisp")
(use-package work)
