(require 'package)
(setq package-archives '(("gnu" . "https://elpa.gnu.org/packages/")
                         ("melpa-stable" . "https://stable.melpa.org/packages/")))
(package-initialize)

(require 'use-package)
(add-to-list 'exec-path "/home/tom/.local/bin")
(recentf-mode 1)
(global-hl-line-mode t)

(use-package gnus
  :config
  (setq gnus-select-method '(nntp "news.gmane.org"))
  (setq gnus-use-cache t))

(use-package magit)
(use-package ivy
  :ensure t
  :config
  (ivy-mode 1))

(use-package evil)

(use-package projectile
  :config
  (projectile-mode 1))

(use-package swiper
  :ensure t
  :config
  (global-set-key "\C-s" 'swiper)
  )
