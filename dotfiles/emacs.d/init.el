(require 'package)
(package-initialize)
(add-to-list 'package-archives '("melpa" . "http://melpa.milkbox.net/packages/") t)
(add-to-list 'package-archives 
    '("marmalade" .
      "http://marmalade-repo.org/packages/"))

(require 'use-package)

(global-linum-mode 1)

(use-package ido
  :config
  (ido-mode 1)
  (setq ido-enable-flex-matching t
        ido-everywhere t))

(setq inhibit-startup-message t
      inhibit-startup-echo-message t)

(use-package no-easy-keys
  :config
  (no-easy-keys 1))

(use-package org
  :config
  (define-key global-map "\C-cl" 'org-store-link)
  (define-key global-map "\C-ca" 'org-agenda)
  (setq org-log-done t))

(menu-bar-mode -1)
(toggle-scroll-bar -1)
(tool-bar-mode -1)
(scroll-bar-mode -1)

(defun make-shell (name)
  "Create a shell buffer named NAME."
  (interactive "sName: ")
  (setq name (concat "$" name))
  (eshell)
  (rename-buffer name))


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
  (setq irfc-directory "~/.cache/emacs/rfcs/")
  (setq irfc-assoc-mode t))

(use-package god-mode
  :config
  (global-set-key (kbd "<escape>") 'god-local-mode))

(use-package uniquify)

(defalias 'yes-or-no-p 'y-or-n-p)

;; execute-extended-command is M-x
(global-set-key "\C-x\C-m" 'execute-extended-command)
(global-set-key "\C-c\C-m" 'execute-extended-command)
