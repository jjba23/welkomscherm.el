
(defgroup welkomscherm ()
  ""
  :group 'tools)

(defface welkomscherm-muted-face '((t (:inherit 'font-lock-comment-face ))) ""
  :group 'welkomscherm)


(defun welkomscherm-insert-muted (x)
  (insert (propertize x 'face 'welkomscherm-muted-face)))

(defun welkomscherm-insert-new-line () (insert "\n"))

(defcustom welkomscherm-buffer-name "*welkomscherm*"
  ""
  :type 'string
  :group 'welkomscherm)

(defcustom welkomscherm-top-title '("While any editor can save your files" "only Emacs can save your soul !")
  ""
  :type '(list string)
  :group 'welkomscherm)

(defcustom welkomscherm-bookmarks '("~/.emacs.d/init.el"
                                    "~/.ssh/config")
  ""
  :type '(list string)
  :group 'welkomscherm)

(defun welkomscherm-insert ()
  ""
  (dolist (x welkomscherm-top-title)
    (welkomscherm-insert-muted x)
    (center-line)
    (welkomscherm-insert-new-line)
    )
  
  (center-line)
  (welkomscherm-insert-new-line)
  (welkomscherm-insert-new-line)
  (dolist (x welkomscherm-bookmarks)
    (insert-button x
                   'my-file-path x
                   'action (lambda(btn) (find-file (button-get btn 'my-file-path))))
    (center-line)
    (welkomscherm-insert-new-line)
    )
  (welkomscherm-insert-new-line)
  )

(defun welkomscherm ()
  (interactive)
  (when (buffer-live-p (get-buffer welkomscherm-buffer-name)) (kill-buffer welkomscherm-buffer-name))
  
  (let ((buf (get-buffer-create welkomscherm-buffer-name)))
    (with-current-buffer welkomscherm-buffer-name
      (read-only-mode -1)
      (setq-local line-spacing 4)
      (welkomscherm-insert)
      (read-only-mode 1)
      )
    (switch-to-buffer welkomscherm-buffer-name)
    )
  )

