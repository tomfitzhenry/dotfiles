(require 'package)
(setq package-archives '(("gnu", "https://elpa.gnu.org/packages/")
                         ("melpa-stable" . "https://stable.melpa.org/packages/")))
(package-initialize)

(require 'use-package)

(use-package better-defaults
  :ensure t)

(use-package gnus
  :config
  (setq gnus-select-method '(nntp "news.gmane.org"))
  (setq gnus-use-cache t))

(use-package evil
  :config)
