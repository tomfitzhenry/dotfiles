(add-to-list 'load-path "~/.emacs.d/lisp/")

(setq make-backup-file nil)

;; Bookmarks
(setq bookmark-save-flag 1)

;; Buffers
(setq column-number-mode t)

;; Eshell
(add-hook 'eshell-mode-hook
          (lambda ()
            (define-key eshell-mode-map (kbd "C-r") 'consult-history)))

(add-hook 'shell-mode-hook  'with-editor-export-editor)
(add-hook 'term-exec-hook   'with-editor-export-editor)
(add-hook 'eshell-mode-hook 'with-editor-export-editor)
(add-hook 'vterm-mode-hook  'with-editor-export-editor)

;; Flymake
(add-hook 'prog-mode-hook 'flymake-mode)
(add-hook 'text-mode-hook 'flymake-mode)
(add-hook 'sh-mode-hook 'flymake-shellcheck-load)
(add-hook 'flymake-diagnostic-functions 'package-lint-flymake)

;; Lisp
(electric-pair-mode)

;; Minibuffer
(fido-vertical-mode)

;; Mouse
(setq mouse-drag-and-drop-region t)

;; pcomplete
(add-hook 'eshell-mode-hook 'fish-completion-mode)
(setq fish-completion-fallback-on-bash-p t)

;; Server
(add-hook 'after-init-hook 'server-start)

;; Shell
(with-eval-after-load "shell"
  (define-key shell-mode-map (kbd "C-r") 'consult-history))

;; Themes
(load-theme 'modus-operandi t)

;; VC
(global-diff-hl-mode)

(load (system-name))
(provide 'init)
