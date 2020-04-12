(package-initialize)
(add-to-list 'package-archives
	                  '("melpa" . "https://melpa.org/packages/") t)
(unless package-archive-contents
  (package-refresh-contents))

(add-to-list 'load-path "/usr/share/org-mode/lisp")
(add-to-list 'load-path "/usr/share/emacs/site-lisp/emms/")

(require 'use-package)
;; prefer distro provided packages, for security/compatibility
(setq use-package-always-pin "manual")
(recentf-mode 1)
(global-hl-line-mode t)
; Reduce frequency of auto-revert interval from 5s to 20 minutes, to save battery. inotify will do most reverts anyway.
(setq auto-revert-interval (* 60 20))
(global-auto-revert-mode t)
(setq make-backup-files nil)
(setq scroll-step            1
      scroll-conservatively  10000)
(desktop-save-mode 1)
(server-start)

(goto-address-mode)

(use-package evil
  :config
  (evil-mode 1))

(load-theme 'zenburn t)

(setq column-number-mode t)

(use-package dashboard
  ; not in Debian, so let's download if needed
  :ensure t
  :config
  (dashboard-setup-startup-hook)
  (setq dashboard-items '(
                          (projects . 5)
                          (bookmarks . 5)
                          (agenda . 10)
                          (registers . 5)))
  (global-set-key (kbd "<f1>") (lambda () (interactive) (switch-to-buffer (get-buffer "*dashboard*"))))
  (setq dashboard-startup-banner nil)
  (setq dashboard-set-init-info nil)
  (setq dashboard-set-footer nil)
  (add-to-list 'evil-emacs-state-modes 'dashboard-mode)
  (setq initial-buffer-choice (lambda () (get-buffer "*dashboard*"))))

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


(use-package emms-info-libtag
  :config
  (setq emms-info-functions '(emms-info-libtag)))

(use-package emms
  :diminish
  :config
  (emms-all)
  (emms-default-players)
  (global-set-key (kbd "<f5>") 'emms-smart-browse)
  (global-set-key (kbd "<f6>") 'emms-previous)
  (global-set-key (kbd "<f7>") 'emms-pause)
  (global-set-key (kbd "<f8>") 'emms-next)
  ; Show Albums and Artists.
  (add-to-list 'emms-browser-show-display-hook 'emms-browser-expand-to-level-2)
  (setq emms-source-file-default-directory "~/music"))

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

(use-package json-mode
  ; not in Debian, so let's download if needed
  :ensure t)

(use-package nix-mode
  ; not in Debian, so let's download if needed
  :ensure t)

(use-package geiser)

(use-package async
  :config
  ; Useful for async copy commands, especially when copying over TRAMP
  (dired-async-mode))

(use-package go-mode
  :config
  (add-to-list 'auto-mode-alist '("\\.go\\'" . go-mode)))

(add-to-list 'load-path "~/.emacs.d/lisp")
(use-package work)
