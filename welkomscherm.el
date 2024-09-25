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

(defun welkomscherm-insert-spacer () (insert "   "))

(defcustom welkomscherm-buffer-name "*welkomscherm*"
  ""
  :type 'string
  :group 'welkomscherm)

(defcustom welkomscherm-top-title '("While any editor can save your files" "only Emacs can save your soul !")
  ""
  :type '(list string)
  :group 'welkomscherm)


(defcustom welkomscherm-bookmarks-top-name "bookmarks: "
  "" :type 'string :group 'welkomscherm)

(defcustom welkomscherm-bookmarks-middle-name "actions: "
  "" :type 'string :group 'welkomscherm)

(defcustom welkomscherm-bookmarks-bottom-name "work: "
  "" :type 'string :group 'welkomscherm)

(defcustom welkomscherm-bookmarks-top
  '((("row0c0" . "~/Dev/row0c0")
     ("row0c1" . "~/Downloads/some-file.pdf")
     )
    (("row1c0" . "~/Documents/row1c0")
     ))
  "Bookmark alias and path pairs shown up top."
  :type 'alist
  :group 'welkomscherm)


(defcustom welkomscherm-bookmarks-bottom
  '((("work-project-1" . "~/Work/work-project-1/")
     ("wiki-work" . "~/Work/wiki-work/"))    
    )
  "Bookmark alias and path pairs shown down below."
  :type 'alist
  :group 'welkomscherm)

(defcustom welkomscherm-middle-buttons
  '((("*scratch*" . (lambda(btn) (switch-to-buffer "*scratch*")))
     ("*Messages*" . (lambda(btn) (switch-to-buffer "*Messages*")))
     ("re-render me" . (lambda(btn) (welkomscherm)))
     )
    
    )
  "Buttons with desired actions in the middle."
  :type 'alist
  :group 'welkomscherm)

(defun welkomscherm-on-button-click (btn)
  (let (
        (welkomscherm-path (button-get btn 'welkomscherm-path))
        )
    
    (find-file welkomscherm-path)))

(defun welkomscherm-insert ()
  "Render a new Welkomscherm."

  (dolist (x welkomscherm-top-title)
    (welkomscherm-insert-muted x)
    (center-line)
    (welkomscherm-insert-new-line))
  
  (welkomscherm-insert-new-line)
  (welkomscherm-insert-new-line)

  (welkomscherm-insert-muted welkomscherm-bookmarks-top-name)
  (welkomscherm-insert-new-line)

  (dolist (row welkomscherm-bookmarks-top)
    (dolist (x row)
      (insert-button (car x)
                     'welkomscherm-alias (car x)
                     'welkomscherm-path (cdr x)
                     'action 'welkomscherm-on-button-click)
      (welkomscherm-insert-spacer))
    (welkomscherm-insert-new-line))
  

  (welkomscherm-insert-new-line)
  (welkomscherm-insert-muted welkomscherm-bookmarks-middle-name)
  (welkomscherm-insert-new-line)
  (dolist (row welkomscherm-middle-buttons)
    (dolist (x row)
      (insert-button (car x)
                     'action (cdr x))
      (welkomscherm-insert-spacer))
    (welkomscherm-insert-new-line))



  (welkomscherm-insert-new-line)
  (welkomscherm-insert-muted welkomscherm-bookmarks-bottom-name)
  (welkomscherm-insert-new-line)
  (dolist (row welkomscherm-bookmarks-bottom)
    (dolist (x row)
      (insert-button (car x)
                     'welkomscherm-alias (car x)
                     'welkomscherm-path (cdr x)
                     'action 'welkomscherm-on-button-click)
      (welkomscherm-insert-spacer))
    (welkomscherm-insert-new-line))
  
  
  (welkomscherm-insert-new-line))

(defun welkomscherm ()
  "Start a new Welkomscherm killing any live previous instances."
  (interactive)
  (when (buffer-live-p (get-buffer welkomscherm-buffer-name)) (kill-buffer welkomscherm-buffer-name))
  
  (let ((buf (get-buffer-create welkomscherm-buffer-name)))
    (with-current-buffer buf
      (read-only-mode -1)
      (setq line-spacing 12)
      (welkomscherm-insert)
      (read-only-mode 1))
    (switch-to-buffer buf)))


(provide 'welkomscherm)

;;; welkomscherm.el ends here

