(require 'image-mode)
(require 'svg)

;; TODO remove helper snippets
(dotimes (i 3)
  (set (intern (format "im%s" (1+ i))) (let* ((w 800)
                                              (h 1600)
                                              (svg (svg-create w h)))
                                         (svg-rectangle svg 0 0 w h :fill-color (pcase i
                                                                                  (0 "red")
                                                                                  (1 "green")
                                                                                  (2 "blue")))
                                         (svg-image svg))))

(defvaralias 'book-mode-winprops-alist 'image-mode-winprops-alist)

(defvaralias 'book-mode-new-window-functions 'image-mode-new-window-functions)

(defalias 'book-mode-winprops 'image-mode-winprops)
(defalias 'book-mode-window-get 'image-mode-window-get)
(defalias 'book-mode-window-put 'image-mode-window-put)
(defalias 'book-set-window-vscroll 'image-set-window-vscroll)
(defalias 'book-set-window-hscroll 'image-set-window-hscroll)
(defalias 'book-mode-reapply-winprops 'image-mode-reapply-winprops)
(defalias 'book-mode-setup-winprops 'image-mode-setup-winprops)

;;;###autoload
(define-derived-mode book-mode special-mode "Book"
  ;; (add-hook 'book-mode-new-window-functions
	;;           #'doc-view-new-window-function nil t)
  (book-mode-setup-winprops)
  (let ((contents-end (point-max))
        (inhibit-read-only t))
    (goto-char (point-max))
    ;; (insert "\n")
    (insert "1")
    (let ((ol (make-overlay (point-min) contents-end))
          (ol2 (make-overlay (1- (point-max)) (point-max))))
      (insert "\n2")
      (let ((ol3 (make-overlay (1- (point-max)) (point-max))))
        (overlay-put ol 'invisible t)
        (overlay-put ol2 'display im1)
        (overlay-put ol3 'display im2)))))
