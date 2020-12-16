(defun update-all-autoloads ()
  (interactive)
  (let ((generated-autoload-file "~/.emacs.d/lisp/loaddefs.el"))
    (when (not (file-exists-p generated-autoload-file))
      (with-current-buffer (find-file-noselect generated-autoload-file)
        (insert ";;") ;; create the file with non-zero size to appease autoload
        (save-buffer)))
    (update-directory-autoloads "~/.emacs.d/lisp")))

(add-to-list 'load-path "~/.emacs.d/lisp/")
(load-file "~/.emacs.d/lisp/loaddefs.el")
(add-hook 'kill-emacs-hook 'update-all-autoloads)

; Don't grab from elsewhere.
(setq package-archives nil)
(setq vc-follow-symlinks t)

;; Misc
(setq scroll-conservatively 100)
(setq compilation-scroll-output t)
(setq column-number-mode t)
(setq rfc-mode-directory (expand-file-name "~/go/src/salsa.debian.org/debian/doc-rfc"))
(setq elfeed-sort-order 'ascending)
(global-set-key (kbd "M-y") 'consult-yank-pop)

;; Bookmarks
(setq bookmark-save-flag 1)
(global-set-key (kbd "<f2>") 'consult-bookmark)

;; Completion
(setq completion-in-region-function 'consult-completion-in-region)

;; Buffers
(global-set-key (kbd "C-x C-b") 'ibuffer)
;; purges unused buffers at midnight
(require 'midnight)
(global-auto-revert-mode)

;; Eshell
(add-hook 'eshell-mode-hook
          (lambda ()
            (define-key eshell-mode-map (kbd "C-r") 'consult-history)))

;; TODO(https://github.com/minad/consult/issues/48)
(add-hook 'eshell-mode-hook
          (lambda ()
            (setq completion-in-region-function 'completion--in-region)))

;; Flymake
(add-hook 'prog-mode-hook 'flymake-mode)
(add-hook 'prog-mode-hook 'flymake-aspell-setup)
(add-hook 'text-mode-hook 'flymake-mode)
(add-hook 'text-mode-hook 'flymake-aspell-setup)

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

;; Regex

(defun reb-visual-replace (to-string)
      "Replace current RE from point with `query-replace-regexp'."
      (interactive
       (progn (barf-if-buffer-read-only)
              (list (query-replace-read-to (reb-target-binding reb-regexp)
                                           "Query replace"  t))))
      (with-current-buffer reb-target-buffer
        (query-replace-regexp (reb-target-binding reb-regexp) to-string)))

(with-eval-after-load "re-builder"
  (define-key reb-mode-map "\C-c\C-v" 'reb-visual-replace))

;; Server
(add-hook 'after-init-hook 'server-start)

;; Shell
(with-eval-after-load "shell"
  (define-key shell-mode-map (kbd "C-r") 'consult-history))

;; Themes
;; 3sf, close enough.
(setq calendar-latitude -33.8)
(setq calendar-longitude 151)
(setq circadian-themes '((:sunrise . modus-operandi)
                         (:sunset . modus-vivendi)))
(circadian-setup)

;; VC
(add-hook 'log-edit-hook 'turn-on-auto-fill)
(add-hook 'log-edit-hook 'log-edit-show-diff)
(global-diff-hl-mode)

;; Windows
(windmove-default-keybindings)
;; C-c left, to undo window configurations.
(winner-mode)

(load (system-name))
(provide 'init)
