(add-to-list 'load-path "~/.emacs.d/lisp/")

(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/") t)
(setq package-selected-packages
      '(consult
        fish-completion
        flymake-shellcheck
        icomplete-vertical
        json-mode
        jsonnet-mode
        orderless
        rfc-mode
        vterm))
(package-install-selected-packages)

;; Misc
(setq ring-bell-function 'ignore)
(setq scroll-conservatively 100)

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

;; imenu
(global-set-key (kbd "C-c i") 'imenu)

;; Minibuffer
(icomplete-mode)
(icomplete-vertical-mode)
(require 'orderless)
(setq completion-styles '(orderless))

;; Mouse
(setq focus-follows-mouse t)
(setq mouse-autoselect-window t)
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

;; Time
(setq display-time-world-list
      '(("America/Los_Angeles" "LAX")
	("UTC" "UTC")
	("Europe/London" "LON")
	("Australia/Sydney" "SYD")))
(setq display-time-world-time-format "%a %F %T %z")

;; VC
(global-diff-hl-mode)

(load (system-name))
(provide 'init)
