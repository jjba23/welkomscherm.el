
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

(defvar welkomscherm-bookmarks '("~/Ontwikkeling/Persoonlijk/dotfiles/users/joe/emacs/init.el"
                                 "~/Ontwikkeling/Persoonlijk/welkomscherm.el/welkomscherm.el")
  ""  )

(defun welkomscherm ()
  (interactive)
  (kill-buffer welkomscherm-buffer-name)
  (let ((buf (get-buffer-create welkomscherm-buffer-name)))
    (with-current-buffer welkomscherm-buffer-name
      (read-only-mode -1)
      (welkomscherm-insert-muted welkomscherm-buffer-name)
      (center-line)
      (insert "\n")
      (dolist (el welkomscherm-bookmarks)
        (print el)
        (insert-button el '(:action '(find-file el)))
        (insert "\n")
        )
      (insert "\n")
      (read-only-mode 1)
      )
    (switch-to-buffer welkomscherm-buffer-name)
    )
  )

