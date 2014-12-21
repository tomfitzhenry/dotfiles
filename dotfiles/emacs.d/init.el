(package-initialize)
(add-to-list 'package-archives '("melpa" . "http://melpa.milkbox.net/packages/") t)
(add-to-list 'package-archives '("marmalade" . "http://marmalade-repo.org/packages/"))

(require 'use-package)

(use-package no-easy-keys
  :config
  (no-easy-keys 1))

(use-package org
  :config
  (define-key global-map "\C-cl" 'org-store-link)
  (define-key global-map "\C-ca" 'org-agenda)
  (setq org-log-done t))

(defalias 'yes-or-no-p 'y-or-n-p)
(setq inhibit-startup-message t
      inhibit-startup-echo-message t)
(global-linum-mode 1)
(menu-bar-mode -1)
(toggle-scroll-bar -1)
(tool-bar-mode -1)
(scroll-bar-mode -1)

(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(custom-enabled-themes (quote (manoj-dark)))
 '(uniquify-buffer-name-style (quote post-forward-angle-brackets) nil (uniquify)))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )

(use-package irfc
  :config
  (setq irfc-directory "~/.cache/emacs/rfcs/"
        irfc-assoc-mode t))

(use-package god-mode
  :config
  (global-set-key (kbd "<escape>") 'god-local-mode))

(use-package uniquify)

(use-package helm
  :config
  (helm-mode))

(use-package magit)

(use-package projectile)

(use-package helm-projectile)

(use-package ace-jump-mode)
