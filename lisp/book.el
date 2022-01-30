;; -*- lexical-binding: t; -*-

(require 'image-mode)
(require 'svg)
(require 'cl-lib)

(defgroup book nil
  "Bookroll customizations.")

(defcustom book-scroll-fraction 32
  "The scroll step size in 1/fraction of page."
  :type 'integer)

(defcustom book-page-vertical-margin 5
  "The size of the vertical margins around a page."
  :type 'integer)

(defvar-local book-number-of-pages 0)
(defvar-local book-contents-end-pos 0)

;; We overwrite the following image-mode function to make it also
;; reapply winprops when the overlay has the 'invisible property
(defun image-get-display-property ()
  (or (get-char-property (point-min) 'display
                         ;; There might be different images for different displays.
                         (if (eq (window-buffer) (current-buffer))
                             (selected-window)))
      (get-char-property (point-min) 'invisible
                         ;; There might be different images for different displays.
                         (if (eq (window-buffer) (current-buffer))
                             (selected-window)))))

;; (defmacro book-current-page (&optional win)
;;   `(image-mode-window-get 'page ,win))
(defmacro book-overlays () '(image-mode-window-get 'overlays))
(defmacro book-image-sizes () '(image-mode-window-get 'image-sizes))
(defmacro book-image-positions () '(image-mode-window-get 'image-positions))
(defmacro book-currently-displayed-pages () '(image-mode-window-get 'displayed-pages))

(defun book-create-image-positions (image-sizes)
  (let ((sum 0)
        (positions (list 0)))
    (dolist (s image-sizes)
      (setq sum (+ sum (cdr s) (* 2 book-page-vertical-margin)))
      (push sum positions))
    (nreverse positions)))

(defun book-create-overlays-list (winprops)
  "Create list of overlays spread out over the buffer contents.
Pass non-nil value for include-first when the buffer text starts with a match."
  ;; first overlay starts at 1
  ;; (setq book-contents-end-pos (goto-char (point-max)))
  (goto-char book-contents-end-pos)
  (let ((eobp (eobp))
        overlays)
    (if eobp
        (insert " ")
      (forward-char))
    (push (make-overlay (1- (point)) (point)) overlays)
    (let ((overlays-list (dotimes (_ (1- (length (book-image-sizes))) (nreverse overlays))
                           (insert "\n")
                           ;; (insert (number-to-string (+ p 2)))
                           (if eobp
                               (insert " ")
                             (forward-char))
                           (push (make-overlay (1- (point)) (point)) overlays))))
      (mapc (lambda (o) (overlay-put o 'window (get-buffer-window))) overlays-list)
      (image-mode-window-put 'overlays overlays-list winprops)))
  (goto-char (point-min))
  (set-buffer-modified-p nil))

(defun book-create-empty-page (size)
  (pcase-let* ((`(,w . ,h) size))
    (svg-image (svg-create w h)
               :margin (cons 0 book-page-vertical-margin))))

(defun book-create-placeholders ()
  (let* ((constant-size (cl-every #'eql (book-image-sizes) (cdr (book-image-sizes))))
         (ph (when constant-size (book-create-empty-page (car (book-image-sizes))))))
    (dotimes (i (length (book-image-sizes)))
      ;; (let ((p (1+ i)));; shift by 1 to match with page numbers
      ;; (overlay-put (nth i overlays-list) 'display (or ph (book-create-empty-page (nth i (book-image-sizes))))))))
      (overlay-put (nth i (book-overlays)) 'display (or ph (book-create-empty-page (nth i (book-image-sizes))))))))

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
         ((pred (= book-number-of-pages)) (list page (- page 1)))
         (p (list (- p 1) p (+ p 1)))))))

(defun book-remove-page-image (page)
  (overlay-put (nth (1- page) (book-overlays))
               'display
               (book-create-empty-page (nth (1- page) (book-image-sizes)))))


(defun book-scroll-to-page (page)
  (interactive "n")
  ;; (book-update-page-triplet page)
  (let* ((elt (1- page)))
    (set-window-vscroll nil (+ (nth elt (book-image-positions)) book-page-vertical-margin) t)))

(when (boundp 'evil-version)
  (evil-define-key 'evilified doc-view-mode-map "j" 'doc-view-scroll-up)
  (evil-define-key 'evilified doc-view-mode-map "k" 'doc-view-scroll-down))

(provide 'book)
