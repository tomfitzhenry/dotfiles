(defun my-system-type-is-nixos ()
  (file-exists-p "/etc/NIXOS"))

(add-to-list 'load-path "~/.emacs.d/lisp/")

(require 'package)
; Don't grab from elsewhere.
(setq package-archives nil)

(eval-when-compile
  (require 'use-package))

(global-auto-revert-mode t)
(setq scroll-conservatively  100)
(setq column-number-mode t)

(setq focus-follows-mouse t)
(setq mouse-autoselect-window t)
(setq mouse-drag-and-drop-region t)

(goto-address-mode)

(defun my/completing-kill-ring ()
  (interactive)
  (insert
   (completing-read "Yank: " kill-ring)))

(global-set-key (kbd "C-c y") 'my/completing-kill-ring)

;; Set visual fill modein Log-Edit
(add-hook 'log-edit-hook 'turn-on-auto-fill)
(add-hook 'log-edit-hook 'log-edit-show-diff)

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

(use-package company
  :config
  (global-company-mode))

(use-package compile
  :config
  (setq compilation-scroll-output t))

(use-package diff-hl
  :config
  (global-diff-hl-mode))

(use-package elfeed
  :config
  (setq elfeed-sort-order 'ascending))

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

(use-package nov
  :config
  (add-hook 'nov-mode-hook
	    (lambda ()
	      (text-scale-increase 2)
	      (setq-local line-spacing 5)))
  (add-to-list 'auto-mode-alist '("\\.epub\\'" . nov-mode)))

;; an fzf-like completion-style
(use-package orderless
  :init (icomplete-mode)
  :custom (completion-styles '(orderless)))

(use-package org
  :init
  (setq org-startup-folded nil)
  (setq org-replace-disputed-keys t)
  (setq org-catch-invisible-edits 'smart)
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

(use-package org-mouse)

(use-package org-roam)

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

(defun reb-visual-replace (to-string)
      "Replace current RE from point with `query-replace-regexp'."
      (interactive
       (progn (barf-if-buffer-read-only)
              (list (query-replace-read-to (reb-target-binding reb-regexp)
                                           "Query replace"  t))))
      (with-current-buffer reb-target-buffer
        (query-replace-regexp (reb-target-binding reb-regexp) to-string)))

(use-package re-builder
  :config
  (define-key reb-mode-map "\C-c\C-v" 'reb-visual-replace))

(use-package rfc-mode
  :config
  (setq rfc-mode-directory (expand-file-name "~/go/src/salsa.debian.org/debian/doc-rfc")))

(use-package rofi)

(use-package server
  :config
  (add-hook 'after-init-hook 'server-start t))

(defun my/comint-history ()
  (interactive)
  (let ((b (completing-read "Shell history: " (ring-elements comint-input-ring))))
    (insert b)))

(use-package shell
  :config
  (global-set-key (kbd "C-c s") 'shell)
  :bind (:map shell-mode-map ("C-r" . 'my/comint-history)))

(use-package vc
  :config
  (setq vc-follow-symlinks t))

(use-package windmove
  :config
  (windmove-default-keybindings))

;; C-c left, to undo window configurations.
(use-package winner
  :config
  (winner-mode))

(use-package zenburn-theme
  :config
  (setq zenburn-use-variable-pitch t)
  (setq zenburn-scale-org-headlines t)
  (load-theme 'zenburn t))

(load (system-name))

(provide 'init)
