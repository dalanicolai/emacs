;; -*- lexical-binding: t; -*-

(require 'image-mode)
(require 'svg)
(require 'cl-lib)

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

(defcustom book-scroll-fraction 32
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

(defmacro book-current-overlays () '(image-mode-window-get 'overlays))
(defmacro book-image-sizes () '(image-mode-window-get 'image-sizes))
(defmacro book-image-positions () '(image-mode-window-get 'image-positions))

(defun book-create-image-positions (image-sizes)
  (let ((sum 0)
        (positions (list 0)))
    (dolist (s image-sizes)
      (setq sum (+ sum (cdr s)))
      (push sum positions))
    (nreverse positions)))

(defun book-create-overlays-list (winprops)
  "Create list of overlays spread out over the buffer contents.
Pass non-nil value for include-first when the buffer text starts with a match."
  ;; first overlay starts at 1
  (setq contents-end-pos (goto-char (point-max)))
  (let (overlays)
    (insert " ")
    (push (make-overlay (1- (point)) (point)) overlays)
    (let ((overlays-list (dotimes (p (1- (length image-sizes)) (nreverse overlays))
                          (insert "\n")
                          ;; (insert (number-to-string (+ p 2)))
                          (insert " ")
                          (push (make-overlay (1- (point)) (point)) overlays))))
      (mapcar (lambda (o) (overlay-put o 'window (get-buffer-window))) overlays-list)
      (image-mode-window-put 'overlays overlays-list winprops)))
  (goto-char (point-min)))

(defun book-create-empty-page (size)
  (pcase-let* ((`(,w . ,h) size))
    (svg-image (svg-create w h))))

(defun book-create-placeholders ()
  (let* ((constant-size (cl-every #'eql image-sizes (cdr image-sizes)))
         (ph (when constant-size (book-create-empty-page (car image-sizes)))))
    (dotimes (i (length image-sizes))
      ;; (let ((p (1+ i)));; shift by 1 to match with page numbers
      ;; (overlay-put (nth i overlays-list) 'display (or ph (book-create-empty-page (nth i image-sizes)))))))
      (overlay-put (nth i (book-current-overlays)) 'display (or ph (book-create-empty-page (nth i image-sizes)))))))

(defun book-image-size (&optional page)
  (nth (- (or page (doc-view-current-page)) 1) (book-image-sizes)))

(defun book-current-page ()
  (interactive)
  (let ((i 0)
        (cur-pos (window-vscroll nil t)))
    (while (<= (nth (1+ i) (book-image-positions)) (+ cur-pos (/ (window-pixel-height) 2)))
      (setq i (1+ i)))
    (1+ i)))

(defun book-page-triplet (page)
  (pcase (doc-view-last-page-number)
    (1 '(1))
    (2 '(1 2))
    (_ (pcase page
         (1 '(1 2))
         ((pred (= number-of-pages)) (list page (- page 1)))
         (p (list (- p 1) p (+ p 1)))))))

(defun book-scroll-to-page (page)
  (interactive "n")
  ;; (book-update-page-triplet page)
  (let* ((elt (1- page)))
    (set-window-vscroll nil (nth elt (book-image-positions)) t)))

(defun book-scroll-up ()
  ;; (defun pdf-view-next-line-or-next-page ()
  (interactive)
  ;; because pages could have different heights, we calculate the step size on each scroll
  ;; TODO define constant scroll size if doc has single page height
  (let* ((scroll-step-size (/ (cdr (book-image-size)) book-scroll-fraction))
         (page-end (nth (doc-view-current-page) (book-image-positions)))
         (new-vscroll (image-set-window-vscroll (+ (window-vscroll nil t) scroll-step-size))))
    (when (> (+ new-vscroll (/ (window-pixel-height) 2)) page-end)
      (cl-incf (doc-view-current-page))
      (dolist (p (book-page-triplet (doc-view-current-page)))
        (doc-view-insert-image (doc-view-page-file-name p)
                               p
                               :width doc-view-image-width
                               :pointer 'arrow
                               :relief 4))))
                               ;; :ascent (if doc-view-full-continuous 0 50)))))
  (sit-for 0))

(defun book-scroll-down ()
  ;; (defun pdf-view-next-line-or-next-page ()
  (interactive)
  ;; because pages could have different heights, we calculate the step size on each scroll
  ;; TODO define constant scroll size if doc has single page height
  (let* ((scroll-step-size (/ (cdr (book-image-size)) book-scroll-fraction))
         (page-beg (nth (1- (doc-view-current-page)) (book-image-positions)))
         (new-vscroll (image-set-window-vscroll (- (window-vscroll nil t) scroll-step-size))))
    (when (< (+ new-vscroll (/ (window-pixel-height) 2)) page-beg)
      (cl-decf (doc-view-current-page))
      (dolist (p (book-page-triplet (doc-view-current-page)))
        (doc-view-insert-image (doc-view-page-file-name p)
                               p
                               :width doc-view-image-width
                               :pointer 'arrow
                               :relief 4))))
                               ;; :ascent (if doc-view-full-continuous 100 50)))))
  (sit-for 0))

(when (boundp 'evil-version)
  (evil-define-key 'evilified doc-view-mode-map "j" 'book-scroll-up)
  (evil-define-key 'evilified doc-view-mode-map "k" 'book-scroll-down))

(provide 'book-mode)
