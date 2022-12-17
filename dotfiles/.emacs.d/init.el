(add-to-list 'load-path "~/.emacs.d/lisp/")

(defun add-hooks (hook &rest functions)
  (dolist (function functions)
    (add-hook hook function)))

;; Misc
(setq bookmark-save-flag 1)
(setq make-backup-file nil)
(fido-vertical-mode)
(add-hook 'after-init-hook 'server-start)
(global-set-key (kbd "M-g i") 'imenu) ;; emacs-devel "Proposal: add a binding for `imenu' under M-g"
(load-theme 'modus-operandi t)

;; Editing
(setq column-number-mode t)
(setq mouse-drag-and-drop-region t)
(add-hook 'prog-mode-hook 'flymake-mode)
(add-hook 'text-mode-hook 'flymake-mode)
(add-hook 'sh-mode-hook 'flymake-shellcheck-load)
(add-hook 'flymake-diagnostic-functions 'package-lint-flymake)
(global-diff-hl-mode)

;; Shell-ish
(add-hooks 'eshell-mode-hook
	   'detached-eshell-mode
	   'fish-completion-mode
	   'with-editor-export-editor
	   (lambda ()
	     (define-key eshell-mode-map (kbd "C-r") 'consult-history)))

(add-hooks 'shell-mode-hook
	   'detached-shell-mode
	   'with-editor-export-editor)

(with-eval-after-load "shell"
  (define-key shell-mode-map (kbd "C-r") 'consult-history))

(add-hooks 'vterm-mode-hook
	   'with-editor-export-editor)

(setq fish-completion-fallback-on-bash-p t)

(load (system-name))
(provide 'init)
