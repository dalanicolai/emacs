(require 'image-mode)
(require 'svg)

;; TODO remove test code
(dotimes (i 3)
  (set (intern (format "im%s" (1+ i))) (let* ((w 800)
                                              (h 1600)
                                              (svg (svg-create w h)))
                                         (svg-rectangle svg 0 0 w h :fill-color (pcase i
                                                                                  (0 "red")
                                                                                  (1 "green")
                                                                                  (2 "blue")))
                                         (svg-image svg))))

;;;###autoload
(define-derived-mode book-mode fundamental-mode "Book"
  ;; (add-hook 'book-mode-new-window-functions
  ;;           #'doc-view-new-window-function nil t)
  (image-mode-setup-winprops)
  (let ((ol (make-overlay (point-min) (point-max)))
        (contents-end (goto-char (point-max)))
        overlays)
    (insert "1")
    (push (make-overlay (1- (point)) (point)) overlays)
    (let ((overlays-list (dotimes (p 2 (nreverse overlays))
                           (insert "\n")
                           (insert (number-to-string (+ p 2)))
                           (push (make-overlay (1- (point)) (point)) overlays))))
      (overlay-put ol 'invisible t)
      (overlay-put (car overlays-list) 'display im1)
      (overlay-put (cadr overlays-list) 'display im2))))

;; end test code


(defgroup book-mode nil
  "Bookroll sutomizations.")

(defcustom book-scroll-fraction 16
  "Set the scroll step size in 1/fraction of page.")

(defvar-local overlays-list nil)
(defvar-local image-sizes nil)
;; (defvar-local image-sizes nil)
(defvar-local image-positions nil)
;; (defvar-local image-positions nil)
(defvar-local number-of-pages 0)
(defvar-local contents-end-pos 0)


;; We start with the simplest solution (if this gives performance issues then we
;; can optimize/modify it later), that is always display a page triplet around
;; the currently viewed page, except for the first and last pages where we
;; display only a doublet.
(defvar-local currently-displayed-pages nil)
;; TODO maybe add back aliases
;; (defvaralias 'book-mode-winprops-alist 'image-mode-winprops-alist)

;; (defvaralias 'book-mode-new-window-functions 'image-mode-new-window-functions)

;; (defalias 'book-mode-winprops 'image-mode-winprops)
;; (defalias 'book-mode-window-get 'image-mode-window-get)
;; (defalias 'book-mode-window-put 'image-mode-window-put)
;; (defalias 'book-set-window-vscroll 'image-set-window-vscroll)
;; (defalias 'book-set-window-hscroll 'image-set-window-hscroll)
;; (defalias 'book-mode-reapply-winprops 'image-mode-reapply-winprops)
;; (defalias 'book-mode-setup-winprops 'image-mode-setup-winprops)

(defun book-image-positions (image-sizes)
  (let ((sum 0)
        (positions (list 0)))
    (dolist (s image-sizes)
      (setq sum (+ sum (cdr s)))
      (push sum positions))
    (nreverse positions)))

(defun book-create-overlays-list ()
  "Create list of overlays spread out over the buffer contents.
Pass non-nil value for include-first when the buffer text starts with a match."
  ;; first overlay starts at 1
  (setq contents-end-pos (goto-char (point-max)))
  (let(overlays)
    (insert " ")
    (push (make-overlay (1- (point)) (point)) overlays)
    (setq overlays-list (dotimes (p (1- (length image-sizes)) (nreverse overlays))
                          (insert "\n")
                          ;; (insert (number-to-string (+ p 2)))
                          (insert " ")
                          (push (make-overlay (1- (point)) (point)) overlays))))
  (goto-char (point-min)))

(defun book-create-empty-page (size)
  (pcase-let* ((`(,w . ,h) size))
    (svg-image (svg-create w h))))

(defun book-create-placeholders ()
  (let* ((constant-size (cl-every #'eql image-sizes (cdr image-sizes)))
         (ph (when constant-size (book-create-empty-page (car image-sizes)))))
    (dotimes (i (length image-sizes))
      ;; (let ((p (1+ i)));; shift by 1 to match with page numbers
      (overlay-put (nth i overlays-list) 'display (or ph (book-create-empty-page (nth i image-sizes)))))))

(defun book-scroll-to-page (page)
  (interactive "n")
  ;; (br-update-page-triplet page)
  (let* ((elt (1- page)))
    (set-window-vscroll nil (nth elt image-positions) t)))

(provide 'book-mode)
