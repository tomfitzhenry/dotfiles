(add-to-list 'load-path "~/.config/emacs/user-lisp/") ;; Remove when Emacs 31 is released.
(if window-system
    (tool-bar-mode -1))
(menu-bar-mode -1)
(setq bookmark-save-flag 1)
(setq make-backup-files nil)
(setq auto-save-default nil)
(icomplete-vertical-mode)
(setq icomplete-show-matches-on-no-input t)
(add-hook 'after-init-hook 'server-start)
(load-theme 'modus-vivendi t)

;; Editing
(setq column-number-mode t)
(add-hook 'prog-mode-hook 'eglot-ensure)
(add-hook 'text-mode-hook 'flymake-mode)

;; Tree-sitter. Emacs 31 should remove the need for this list.
(require 'json-ts-mode)
(require 'go-ts-mode)
(if (require 'markdown-ts-mode nil 'noerror)
    (add-to-list 'auto-mode-alist '("\\.md\\'" . markdown-ts-mode)))
(if (require 'nix-ts-mode nil 'noerror)
    (add-to-list 'auto-mode-alist '("\\.nix\\'" . nix-ts-mode)))
(require 'nushell-ts-mode nil 'noerror)
(require 'rust-ts-mode)
(require 'yaml-ts-mode)

;; Shell-ish
(add-hook 'vterm-mode-hook 'with-editor-export-editor)

(load (system-name))
(provide 'init)
