;;; welkomscherm.el --- Proportionally sized faces -*- lexical-binding: t -*-

;; Copyright (C) 2024 Josep Bigorra

;; Version: 0.1.1
;; Author: Josep Bigorra <jjbigorra@gmail.com>
;; Maintainer: Josep Bigorra <jjbigorra@gmail.com>
;; URL: https://github.com/jjba23/tekengrootte.el
;; Keywords: faces
;; Package: tekengrootte
;; Package-Requires: ((emacs "25.1"))


;; welkomscherm is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; welkomscherm is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; TODO

;;; Code:

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
  "Start a new Welkomscherm."
  (interactive)
  (when (buffer-live-p (get-buffer welkomscherm-buffer-name)) (kill-buffer welkomscherm-buffer-name))
  
  (let ((buf (get-buffer-create welkomscherm-buffer-name)))
    (with-current-buffer buf
      (read-only-mode -1)
      (setq-local line-spacing 4)
      (welkomscherm-insert)
      (read-only-mode 1)
      )
    (switch-to-buffer buf)
    )
  )


(provide 'welkomscherm)

;;; welkomscherm.el ends here
