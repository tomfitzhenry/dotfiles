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
(setq backup-directory-alist `(("." . "~/.saves")))

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
  (helm-mode)
  (global-set-key (kbd "M-x") 'helm-M-x)
  (global-set-key (kbd "C-x b") 'helm-mini)
  (setq helm-buffers-fuzzy-matching t
	helm-recentf-fuzzy-match    t)
  (global-set-key (kbd "C-x C-f") 'helm-find-files)
  )

(use-package magit)

(use-package projectile)

(use-package helm-projectile
  :config
  (projectile-global-mode)
  (setq projectile-completion-system 'helm)
  (helm-projectile-on)
  (setq projectile-switch-project-action 'projectile-vc))

(use-package ace-jump-mode)

(use-package gnus
  :config
  (setq gnus-select-method '(nntp "news.gmane.org")
        gnus-summary-line-format "%U%R %&user-date;   %-20,20n   %B%-80,80S\n"
        gnus-user-date-format-alist '((t . "%Y-%m-%d %H:%M"))
        gnus-summary-thread-gathering-function 'gnus-gather-threads-by-references
        gnus-thread-sort-functions '(gnus-thread-sort-by-date)
        gnus-sum-thread-tree-false-root ""
        gnus-sum-thread-tree-indent " "
        gnus-sum-thread-tree-leaf-with-other "├► "
        gnus-sum-thread-tree-root ""
        gnus-sum-thread-tree-single-leaf "╰► "
        gnus-sum-thread-tree-vertical "│"))
