;;; welkomscherm.el --- Simple welcome screen / dashboard -*- lexical-binding: t -*-

;; Copyright (C) 2024 Josep Bigorra

;; Version: 0.1.2
;; Author: Josep Bigorra <jjbigorra@gmail.com>
;; Maintainer: Josep Bigorra <jjbigorra@gmail.com>
;; URL: https://github.com/jjba23/tekengrootte.el
;; Keywords: faces
;; Package: welkomscherm
;; Package-Requires: ((emacs "25.1") (page-break-lines "0.15"))


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

(require 'page-break-lines)

(defgroup welkomscherm nil
  "Simple welcome screen / dashboard for Emacs."
  :group 'tools)

(defface welkomscherm-muted-face
  '((t (:inherit 'font-lock-comment-face )))
  "Face used to draw headers and titles."
  :group 'welkomscherm)

(defun welkomscherm-insert-muted (x)
  "Insert muted text X into the welkomscherm buffer with optional centering."
  (insert (propertize x 'face 'welkomscherm-muted-face))
  (when welkomscherm-centered (center-line)))

(defun welkomscherm-insert-new-line ()
  "Insert new line into the welkomscherm buffer."
  (insert "\n"))

(defun welkomscherm-insert-form-feed ()
  "Insert new form feed (hr) into the welkomscherm buffer."
  (insert "\f"))

(defun welkomscherm-insert-spacer ()
  "Insert a spacer into the welkomscher buffer."
  (insert "  "))

(defcustom welkomscherm-buffer-name "*welkomscherm*"
  "Name of the welkomscherm buffer."
  :type 'string
  :group 'welkomscherm)

(defcustom welkomscherm-top-title
  '("While any editor can save your files"
    "only Emacs can save your soul !")
  "Text lines to show as top title banner."
  :type '(list string)
  :group 'welkomscherm)


(defcustom welkomscherm-bookmarks-personal-name "bookmarks: "
  "Title to show in personal bookmark section."
  :type 'string :group 'welkomscherm)

(defcustom welkomscherm-actions-name "actions: "
  "Title to show for action buttons."
  :type 'string :group 'welkomscherm)

(defcustom welkomscherm-bookmarks-work-name "work: "
  "Title to show for work bookmark section."
  :type 'string :group 'welkomscherm)

(defcustom welkomscherm-use-form-feed nil
  "User option to enable use of form feeds to separate sections."
  :type 'boolean :group 'welkomscherm)

(defcustom welkomscherm-centered t
  "User option to enable use of centered text."
  :type 'boolean :group 'welkomscherm)

(defcustom welkomscherm-use-section-title t
  "User option to enable display of section titles."
  :type 'boolean :group 'welkomscherm)

(defcustom welkomscherm-bookmarks-personal
  '((("row0c0" . "~/Dev/row0c0")
     ("row0c1" . "~/Downloads/some-file.pdf"))
    (("row1c0" . "~/Documents/row1c0")))
  "Bookmark alias and path pairs for personal."
  :type 'alist
  :group 'welkomscherm)

(defcustom welkomscherm-bookmarks-work
  '((("work-project-1" . "~/Work/work-project-1/")
     ("wiki-work" . "~/Work/wiki-work/")))
  "Bookmark alias and path pairs for work."
  :type 'alist
  :group 'welkomscherm)

(defcustom welkomscherm-buttons-actions
  '((("*scratch*" . (lambda(btn) (switch-to-buffer "*scratch*")))
     ("*Messages*" . (lambda(btn) (switch-to-buffer "*Messages*")))
     ("re-render me" . (lambda(btn) (welkomscherm)))
     ))
  "Buttons with desired actions in the middle."
  :type 'alist
  :group 'welkomscherm)

(defun welkomscherm-on-bookmark-click (btn)
  "Action to perform upon clicking a bookmark BTN in welkomscherm."
  (let ((welkomscherm-path (button-get btn 'welkomscherm-path)))
    (find-file welkomscherm-path)))

(defun welkomscherm-insert-bookmark-rows (rows)
  "Render ROWS of bookmarks."
  (dolist (row rows)
    (dolist (x row)
      (insert-button (car x)
                     'welkomscherm-alias (car x)
                     'welkomscherm-path (cdr x)
                     'action 'welkomscherm-on-bookmark-click)
      (welkomscherm-insert-spacer))
    (welkomscherm-maybe-centered)
    (welkomscherm-insert-new-line)))

(defun welkomscherm-maybe-form-feed ()
  "Insert a form feed character based on user preference."
  (when welkomscherm-use-form-feed (welkomscherm-insert-form-feed)))

(defun welkomscherm-maybe-centered ()
  "Center current line based on user preference."
  (when welkomscherm-centered (center-line)))

(defun welkomscherm-insert ()
  "Render a new Welkomscherm."
  
  (dolist (x welkomscherm-top-title)
    (welkomscherm-insert-muted x)
    (welkomscherm-maybe-centered)
    (welkomscherm-insert-new-line))
  (welkomscherm-insert-new-line)

  (welkomscherm-maybe-form-feed)
  (when welkomscherm-use-section-title
    (welkomscherm-insert-muted welkomscherm-bookmarks-personal-name))
  (welkomscherm-insert-new-line)
  (welkomscherm-insert-bookmark-rows welkomscherm-bookmarks-personal)

  (welkomscherm-maybe-form-feed)
  (welkomscherm-insert-new-line)
  (when welkomscherm-use-section-title
    (welkomscherm-insert-muted welkomscherm-actions-name))
  (welkomscherm-insert-new-line)
  
  (dolist (row welkomscherm-buttons-actions)
    (dolist (x row)
      (insert-button (car x)
                     'action (cdr x))
      (welkomscherm-insert-spacer))
    (welkomscherm-maybe-centered)
    (welkomscherm-insert-new-line))


  (welkomscherm-maybe-form-feed)
  (welkomscherm-insert-new-line)
  (when welkomscherm-use-section-title
    (welkomscherm-insert-muted welkomscherm-bookmarks-work-name))

  (welkomscherm-insert-new-line)
  (welkomscherm-insert-bookmark-rows welkomscherm-bookmarks-work)
  (welkomscherm-maybe-form-feed))

(defun welkomscherm ()
  "Start a new Welkomscherm killing any live previous instances."
  (interactive)
  
  (when (buffer-live-p (get-buffer welkomscherm-buffer-name))
    (kill-buffer welkomscherm-buffer-name))
  
  (let ((buf (get-buffer-create welkomscherm-buffer-name)))
    (with-current-buffer buf
      (read-only-mode -1)
      (setq line-spacing 12)
      (welkomscherm-insert)
      (read-only-mode 1)
      (page-break-lines-mode))
    (switch-to-buffer buf)
    (setq fringe-indicator-alist '((truncation nil)))))


(provide 'welkomscherm)

;;; welkomscherm.el ends here


