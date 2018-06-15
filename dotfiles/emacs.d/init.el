(require 'package)
; Disable installation via emacs, since it has poor security
(setq package-archives '())
(package-initialize)

(require 'use-package)
(add-to-list 'exec-path "~/.local/bin")
(recentf-mode 1)
(global-hl-line-mode t)
(setq make-backup-files nil)

(use-package gnus
  :config
  (setq gnus-select-method '(nntp "news.gmane.org"))
  (setq gnus-use-cache t))

(use-package magit)
(use-package ivy
  :config
  (ivy-mode 1))

(use-package evil
  :config
  (evil-mode 1))

(use-package projectile
  :config
  (projectile-global-mode 1))

(use-package ag)

(use-package swiper
  :config
  (global-set-key "\C-s" 'swiper)
  )

(add-to-list 'load-path "~/.emacs.d/lisp")
(use-package work)
