(package-initialize)
(add-to-list 'package-archives
	                  '("melpa" . "https://melpa.org/packages/") t)
(unless package-archive-contents
  (package-refresh-contents))

(require 'use-package)
(recentf-mode 1)
(global-hl-line-mode t)
(global-auto-revert-mode t)
(setq make-backup-files nil)
(setq scroll-step            1
      scroll-conservatively  10000)

(use-package org
  :ensure t
  :pin manual
  :config
(use-package magit
  :ensure t
  :pin manual)

(use-package ivy
  :ensure t
  :pin melpa
  :config
  (ivy-mode 1))

(use-package evil
  :ensure t
  :pin manual
  :config
  (evil-mode 1))

(use-package projectile
  :ensure t
  :pin manual
  :config
  (projectile-global-mode 1))

(use-package ag
  :ensure t
  :pin melpa)

(use-package swiper
  :ensure t
  :pin melpa
  :config
  (global-set-key "\C-s" 'swiper))

(use-package which-key
  :ensure t
  :pin manual
  :config
  (which-key-setup-side-window-right-bottom)
  (which-key-mode 1))

(use-package elfeed
  :ensure t
  :pin manual
  :config
  (add-to-list 'evil-emacs-state-modes 'elfeed-search-mode)
  (add-to-list 'evil-emacs-state-modes 'elfeed-show-mode)
  (elfeed-load-opml "~/sync/Misc/feeds.opml"))

(use-package json-mode
  :ensure t
  :pin melpa)

; Useful for async copy commands, especially when copying over TRAMP
(use-package nix-mode
  :ensure t
  :pin melpa)

(use-package dired-async
  :ensure t
  :pin manual
  :config
  (dired-async-mode))
(add-to-list 'load-path "~/.emacs.d/lisp")
(use-package work)
