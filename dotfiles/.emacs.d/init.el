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

(setq scroll-conservatively 100)
(setq column-number-mode t)

(goto-address-mode)

;; Bookmarks
(setq bookmark-save-flag 1)

(setq compilation-scroll-output t)

;; Completion
(setq completion-in-region-function 'consult-completion-in-region)

(global-set-key (kbd "<f2>") 'consult-bookmark)
(global-set-key	(kbd "M-y") 'consult-yank-pop)

;; elfeed
(setq elfeed-sort-order 'ascending)

;; Buffers
(global-set-key (kbd "C-x C-b") 'ibuffer)
;; purges unused buffers at midnight
(require 'midnight)
(global-auto-revert-mode)

;; imenu
(global-set-key (kbd "C-c i") 'imenu)
(flimenu-global-mode)

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

;; Project
(add-hook
  'ibuffer-hook
  (lambda ()
    (setq ibuffer-filter-groups (ibuffer-project-generate-filter-groups))))

(global-set-key (kbd "C-c p f") 'project-find-file)
(global-set-key (kbd "C-c p x") 'project-shell)
(global-set-key (kbd "C-c p s") 'project-find-regexp)

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

(setq rfc-mode-directory (expand-file-name "~/go/src/salsa.debian.org/debian/doc-rfc"))

;; Server
(add-hook 'after-init-hook 'server-start)

;; Shell
(defun my/comint-history ()
  (interactive)
  (let ((b (completing-read "Shell history: " (ring-elements comint-input-ring))))
    (insert b)))

(with-eval-after-load "shell"
  (define-key shell-mode-map (kbd "C-r") 'my/comint-history))
(define-key global-map (kbd "C-c s") 'shell)

(setq vc-follow-symlinks t)

(defun toggle-dark-mode ()
  (interactive)
  (if (member 'modus-vivendi custom-enabled-themes)
      (load-theme 'modus-operandi t)
      (disable-theme 'modus-vivendi)
    (load-theme 'modus-vivendi t)
    (disable-theme 'modus-operandi)))

(load-theme 'modus-operandi t)

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
