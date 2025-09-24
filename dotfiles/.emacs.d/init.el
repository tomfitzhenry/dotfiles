(if window-system
    (tool-bar-mode -1))
(menu-bar-mode -1)
(setq bookmark-save-flag 1)
(setq make-backup-files nil)
(setq auto-save-default nil)
(icomplete-vertical-mode)
(setq icomplete-show-matches-on-no-input t)
(add-hook 'after-init-hook 'server-start)
(load-theme 'modus-operandi t)

;; Editing
(setq column-number-mode t)
(add-hook 'prog-mode-hook 'eglot-ensure)
(add-hook 'text-mode-hook 'flymake-mode)
(global-diff-hl-mode)

;; Tree-sitter. Emacs 31 should remove the need for this list.
(require 'json-ts-mode)
(require 'go-ts-mode)
(require 'markdown-ts-mode)
(add-to-list 'auto-mode-alist '("\\.md\\'" . markdown-ts-mode))
(require 'nix-ts-mode)
(add-to-list 'auto-mode-alist '("\\.nix\\'" . nix-ts-mode))
(require 'nushell-ts-mode)
(require 'rust-ts-mode)
(require 'yaml-ts-mode)

(load (system-name))
(provide 'init)
