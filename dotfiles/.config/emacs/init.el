;; -*- lexical-binding: t; -*-
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
;; disable copy via text selection
(setq select-active-regions nil)

(global-set-key (kbd "C-S-C") 'kill-ring-save)
(global-set-key (kbd "C-S-V") 'yank)

;; Editing
(setq column-number-mode t)
(setq treesit-enabled-modes t)
(add-hook 'prog-mode-hook 'eglot-ensure)
(add-hook 'text-mode-hook 'flymake-mode)

;; Shell-ish
(add-hook 'vterm-mode-hook 'with-editor-export-editor)
(defun vterm-project ()
    (interactive)
    (defvar vterm-buffer-name)
    (let* ((default-directory (project-root (project-current t)))
           (vterm-buffer-name (project-prefixed-buffer-name "vterm"))
           (vterm-buffer (get-buffer vterm-buffer-name)))
      (if (and vterm-buffer (not current-prefix-arg))
          (pop-to-buffer vterm-buffer (bound-and-true-p display-comint-buffer-action))
        (vterm-other-window t))))
(with-eval-after-load 'project
  (keymap-set project-prefix-map "t" #'vterm-project)
  (add-to-list 'project-switch-commands '(vterm-project "Vterm" ?t)))

(provide 'init)
