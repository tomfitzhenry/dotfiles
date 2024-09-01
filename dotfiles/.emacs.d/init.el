(add-to-list 'load-path "~/.emacs.d/lisp/")

;; Misc
(setq bookmark-save-flag 1)
(setq make-backup-files nil)
(setq auto-save-default nil)
(icomplete-vertical-mode)
(setq icomplete-show-matches-on-no-input t)
(add-hook 'after-init-hook 'server-start)
(load-theme 'modus-operandi t)
(setq native-comp-async-report-warnings-errors 'silent)
(display-battery-mode t)

;; Editing
(setq column-number-mode t)
(setq mouse-drag-and-drop-region t)
(add-hook 'prog-mode-hook 'flymake-mode)
(add-hook 'text-mode-hook 'flymake-mode)
(add-hook 'sh-mode-hook 'flymake-shellcheck-load)
(add-hook 'flymake-diagnostic-functions 'package-lint-flymake)
(add-hook 'c-mode-common-hook 'google-set-c-style)
(global-diff-hl-mode)

;; Rust
(add-hook 'rust-mode-hook
	  (lambda () (setq indent-tabs-mode nil)))
(setq rust-format-on-save t)
(add-hook 'rust-mode-hook 'eglot-ensure)

(setq tom-log-target "~/archives/log/master.md")
(defun tom-log ()
  (interactive)
  (find-file tom-log-target))
(keymap-global-set "C-c l" 'tom-log)

;; Shell-ish
(keymap-global-set "C-t" 'shell-pop)
(setq comint-prompt-read-only t)
(add-hook 'eshell-mode-hook 'detached-shell-mode)
(add-hook 'eshell-mode-hook 'fish-completion-mode)
(add-hook 'eshell-mode-hook 'with-editor-export-editor)
(add-hook 'eshell-mode-hook (lambda ()
			      (define-key eshell-mode-map (kbd "C-r") 'consult-history)))
(setq fish-completion-fallback-on-bash-p t)

;; Clock
(setq world-clock-list
      '(("America/Los_Angeles" "LAX")
       ("UTC" "UTC")
       ("Europe/London" "LON")
       ("Australia/Sydney" "SYD")))
(setq world-clock-time-format "%a %F %T %z")
(display-time)

(load (system-name))
(provide 'init)
