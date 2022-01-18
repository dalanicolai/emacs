(require 'image-mode)


(defvaralias 'book-mode-winprops-alist 'image-mode-winprops-alist)

(defvaralias 'book-mode-new-window-functions 'image-mode-new-window-functions)

(defalias 'book-mode-winprops 'image-mode-winprops)
(defalias 'book-mode-window-get 'image-mode-window-get)
(defalias 'book-mode-window-put 'image-mode-window-put)
(defalias 'book-set-window-vscroll 'image-set-window-vscroll)
(defalias 'book-set-window-hscroll 'image-set-window-hscroll)
(defalias 'book-mode-reapply-winprops 'image-mode-reapply-winprops)
(defalias 'book-mode-setup-winprops 'image-mode-setup-winprops)

(define-derived-mode book-mode special-mode "Book"
  (book-mode-setup-winprops))
