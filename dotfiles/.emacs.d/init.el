(add-to-list 'load-path "~/.emacs.d/lisp/")

(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/") t)
(setq vc-follow-symlinks t)

;; Misc
(setq scroll-conservatively 100)
(setq compilation-scroll-output t)
(setq column-number-mode t)
(setq rfc-mode-directory (expand-file-name "~/go/src/salsa.debian.org/debian/doc-rfc"))
(setq consult-preview-key nil) ;; slow with TRAMP

;; Bookmarks
(setq bookmark-save-flag 1)
(global-set-key (kbd "<f2>") 'consult-bookmark)

;; Completion
(setq completion-in-region-function 'consult-completion-in-region)

;; Buffers
(global-set-key (kbd "C-x C-b") 'ibuffer)
(global-auto-revert-mode)

;; Eshell
(add-hook 'eshell-mode-hook
          (lambda ()
            (define-key eshell-mode-map (kbd "C-r") 'consult-history)))

;; Flymake
(add-hook 'prog-mode-hook 'flymake-mode)
(add-hook 'text-mode-hook 'flymake-mode)
(add-hook 'sh-mode-hook 'flymake-shellcheck-load)
(add-hook 'flymake-diagnostic-functions 'package-lint-flymake)

;; imenu
(global-set-key (kbd "C-c i") 'consult-imenu)

;; Minibuffer
(icomplete-mode)
(icomplete-vertical-mode)
(require 'orderless)
(setq completion-styles '(orderless))

;; Mouse
(setq focus-follows-mouse t)
(setq mouse-autoselect-window t)
(setq mouse-drag-and-drop-region t)

;;; Org
(global-set-key (kbd "C-c a") #'org-agenda)
(with-eval-after-load "org"
  (setq org-startup-folded nil)
  (setq org-replace-disputed-keys t)
  (setq org-catch-invisible-edits 'smart)
  (setq org-agenda-skip-scheduled-if-done t)
  (setq org-agenda-skip-deadline-if-done t)
  (setq org-agenda-show-future-repeats 'next)
  (setq org-agenda-todo-ignore-scheduled 'future)
  (require 'org-mouse))

;; pcomplete
(add-hook 'eshell-mode-hook 'fish-completion-mode)
(setq fish-completion-fallback-on-bash-p t)

;; Project
(add-hook
  'ibuffer-hook
  (lambda ()
    (setq ibuffer-filter-groups (ibuffer-project-generate-filter-groups))))

;; Server
(add-hook 'after-init-hook 'server-start)

;; Shell
(with-eval-after-load "shell"
  (define-key shell-mode-map (kbd "C-r") 'consult-history))

;; Themes
(load-theme 'modus-operandi t)

;; VC
(add-hook 'log-edit-hook 'turn-on-auto-fill)
(add-hook 'log-edit-hook 'log-edit-show-diff)
(global-diff-hl-mode)

(load (system-name))
(provide 'init)
