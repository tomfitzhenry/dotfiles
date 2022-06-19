(add-to-list 'load-path "~/.emacs.d/lisp/")

(defun add-hooks (hook &rest functions)
  (dolist (function functions)
    (add-hook hook function)))

(with-eval-after-load 'geiser-guile
  (add-to-list 'geiser-guile-load-path "~/src/guix"))
(setq enable-local-variables :safe)

(setq make-backup-file nil)

;; Bookmarks
(setq bookmark-save-flag 1)

;; Buffers
(setq column-number-mode t)


;; Flymake
(add-hook 'prog-mode-hook 'flymake-mode)
(add-hook 'text-mode-hook 'flymake-mode)
(add-hook 'sh-mode-hook 'flymake-shellcheck-load)
(add-hook 'flymake-diagnostic-functions 'package-lint-flymake)

(global-set-key (kbd "M-g i") 'imenu) ;; emacs-devel "Proposal: add a binding for `imenu' under M-g"

;; Gnus
(setq-default
 gnus-select-method '(nnil "")
 gnus-secondary-select-methods '((nntp "news.yhetil.org")
				 (nntp "nntp.lore.kernel.org"))
 gnus-use-adaptive-scoring t
 gnus-summary-line-format "%U%R%z %(%&user-date;  %-15,15f  %B %s%)\n"
 gnus-user-date-format-alist '((t . "%Y-%m-%d %H:%M"))
 gnus-summary-thread-gathering-function 'gnus-gather-threads-by-references
 gnus-thread-sort-functions '(gnus-thread-sort-by-date)
 gnus-sum-thread-tree-false-root ""
 gnus-sum-thread-tree-indent " "
 gnus-sum-thread-tree-leaf-with-other "├► "
 gnus-sum-thread-tree-root ""
 gnus-sum-thread-tree-single-leaf "╰► "
 gnus-sum-thread-tree-vertical "│")

;; Lisp
(electric-pair-mode)

;; Minibuffer
(fido-vertical-mode)

;; Mouse
(setq mouse-drag-and-drop-region t)

;; Server
(add-hook 'after-init-hook 'server-start)

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

;; SMTP
(setq-default
 smtpmail-smtp-server "smtp.fastmail.com"
 smtpmail-smtp-user "tom@tom-fitzhenry.me.uk"
 smtpmail-smtp-service 465
 send-mail-function 'smtpmail-send-it
 smtpmail-stream-type  'ssl
 user-full-name "Tom Fitzhenry"
 user-mail-address "tom@tom-fitzhenry.me.uk")

;; Themes
(load-theme 'modus-operandi t)

;; VC
(global-diff-hl-mode)

(load (system-name))
(provide 'init)
