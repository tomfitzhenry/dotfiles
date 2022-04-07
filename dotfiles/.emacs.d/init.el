(add-to-list 'load-path "~/.emacs.d/lisp/")

(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/") t)
(setq package-selected-packages
      '(consult
        fish-completion
        flymake-shellcheck
        json-mode
        jsonnet-mode
        orderless
	paredit-menu
        rfc-mode
        vterm))
(package-install-selected-packages)

;; Autosave
(setq backup-directory-alist
      `((".*" . ,temporary-file-directory)))
(setq auto-save-file-name-transforms
      `((".*" ,temporary-file-directory t)))

;; Bookmarks
(setq bookmark-save-flag 1)

;; Buffers
(global-auto-revert-mode)
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
(add-hook 'lisp-data-mode-hook 'enable-paredit-mode)
(with-eval-after-load "paredit"
  (require 'paredit-menu))

;; Minibuffer
(icomplete-mode)
(icomplete-vertical-mode)
(require 'orderless)
(setq completion-styles '(orderless))

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
