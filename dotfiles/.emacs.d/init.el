(add-to-list 'load-path "~/.emacs.d/lisp/")

;; Misc
(setq bookmark-save-flag 1)
(setq make-backup-files nil)
(setq auto-save-default nil)
(fido-vertical-mode)
(add-hook 'after-init-hook 'server-start)
(load-theme 'modus-operandi t)
(setq native-comp-async-report-warnings-errors 'silent)

;; Editing
(setq column-number-mode t)
(setq mouse-drag-and-drop-region t)
(add-hook 'prog-mode-hook 'flymake-mode)
(add-hook 'text-mode-hook 'flymake-mode)
(add-hook 'sh-mode-hook 'flymake-shellcheck-load)
(add-hook 'flymake-diagnostic-functions 'package-lint-flymake)
(add-hook 'c-mode-common-hook 'google-set-c-style)
(global-diff-hl-mode)
(direnv-mode)

;; Shell-ish
(add-hook 'eshell-mode-hook 'detached-shell-mode)
(add-hook 'eshell-mode-hook 'fish-completion-mode)
(add-hook 'eshell-mode-hook 'with-editor-export-editor)
(add-hook 'eshell-mode-hook (lambda ()
			      (define-key eshell-mode-map (kbd "C-r") 'consult-history)))
(setq fish-completion-fallback-on-bash-p t)

(load (system-name))
(provide 'init)
