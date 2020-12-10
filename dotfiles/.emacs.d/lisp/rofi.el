;;; rofi --- A rofi user script in elisp.
;;; Commentary:
;;; Code:

(require 'bookmark)

;;;###autoload
(defun rofi (in)
    (if (eq in "")
      (mapconcat 'identity (bookmark-all-names) "\n")
      (progn
        (let ((f (make-frame)))
          (select-frame-set-input-focus f)
          (bookmark-jump in))
        "")))

(provide 'rofi)
;;; rofi.el ends here
