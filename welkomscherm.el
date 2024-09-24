
(defgroup welkomscherm ()
  ""
  :group 'tools)

(defface welkomscherm-muted-face '((t (:inherit 'font-lock-comment-face ))) ""
  :group 'welkomscherm)


(defun welkomscherm-insert-muted (x)
  (insert (propertize x 'face 'welkomscherm-muted-face))
  )

(defcustom welkomscherm-buffer-name "*welkomscherm*"
  ""
  :type 'string
  :group 'welkomscherm)

(defun welkomscherm ()
  (interactive)
  (let ((buf (get-buffer-create welkomscherm-buffer-name)))
    (with-current-buffer welkomscherm-buffer-name
      (read-only-mode -1)
      (welkomscherm-insert-muted welkomscherm-buffer-name)
      (center-line)
      (insert "\n")
      (read-only-mode 1)
      )
    (switch-to-buffer welkomscherm-buffer-name)
    )
  )

