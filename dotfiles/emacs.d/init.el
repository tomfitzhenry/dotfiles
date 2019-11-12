(package-initialize)
(add-to-list 'package-archives
	                  '("melpa" . "https://melpa.org/packages/") t)
(unless package-archive-contents
  (package-refresh-contents))

(add-to-list 'load-path "/usr/share/org-mode/lisp")
(add-to-list 'load-path "/usr/share/emacs/site-lisp/emms/")

(require 'use-package)
(recentf-mode 1)
(global-hl-line-mode t)
(global-auto-revert-mode t)
(setq make-backup-files nil)
(setq scroll-step            1
      scroll-conservatively  10000)
(server-start)

(load-theme 'zenburn t)

(winner-mode)

(use-package org
  :ensure t
  :pin manual
  :config
  (setq org-agenda-files '("~/sync/Misc"))
  (setq org-agenda-skip-scheduled-if-done t)
  (setq org-agenda-skip-deadline-if-done t)
  (setq org-habit-show-habits-only-for-today nil)
  (setq org-modules '(org-habit))
  (setq org-todo-keywords '("TODO" "WAIT" "DONE"))
  (global-set-key "\C-cl" 'org-store-link)
  (global-set-key "\C-ca" 'org-agenda)
  (global-set-key "\C-cc" 'org-capture)
  (global-set-key "\C-cb" 'org-switchb))


(use-package emms-info-libtag
  :config
  (setq emms-info-functions '(emms-info-libtag)))

(use-package emms
  :config
  (emms-all)
  (emms-default-players)
  ; Show Albums and Artists.
  (add-to-list 'emms-browser-show-display-hook 'emms-browser-expand-to-level-2)
  (setq emms-source-file-default-directory "~/music"))

(use-package beacon
  :ensure t
  :pin manual
  :config
  (beacon-mode 1))

(use-package notmuch
  :ensure t
  :pin manual)

(use-package magit
  :ensure t
  :pin manual)

(use-package ivy
  :ensure t
  :pin manual
  :config
  (ivy-mode 1))

(use-package counsel
  :ensure t
  :pin manual)

(use-package evil
  :ensure t
  :pin manual
  :config
  (evil-mode 1))

(use-package projectile
  :ensure t
  :pin manual
  :config
  (projectile-global-mode 1)
  (define-key projectile-mode-map (kbd "C-c p") 'projectile-command-map))

(use-package ag
  :ensure t
  :pin manual)

(use-package swiper
  :ensure t
  :pin manual
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

(use-package nix-mode
  :ensure t
  :pin melpa)

(use-package async
  :ensure t
  :pin manual
  :config
  ; Useful for async copy commands, especially when copying over TRAMP
  (dired-async-mode))

(use-package notifications)

(use-package weechat
  :ensure t
  :pin manual
  :after (notifications)
  :init
  (setq weechat-modules '(weechat-button weechat-complete weechat-notifications))
  :config
  (add-to-list 'evil-emacs-state-modes 'weechat-mode))

(use-package go-mode
  :ensure t
  :pin manual
  :config
  (add-hook 'before-save-hook 'gofmt-before-save))

(add-to-list 'load-path "~/.emacs.d/lisp")
(use-package work)
