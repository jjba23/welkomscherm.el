;;; welkomscherm.el --- Simple welcome screen / dashboard -*- lexical-binding: t -*-

;; Copyright © Josep Bigorra <jjbigorra@gmail.com>

;; Version: 1.0.0
;; Author: Josep Bigorra <jjbigorra@gmail.com>
;; Maintainer: Josep Bigorra <jjbigorra@gmail.com>
;; URL: https://codeberg.org/jjba23/welkomscherm.el
;; Keywords: splash dashboard faces
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

;; welkomscherm.el is meant to be simple, extensible and performant.
;;
;; A big emphasis is put on being a clean and utilitarian splash page
;; for when you start up Emacs and not be full of items and complexity.
;;
;; If you are looking for a zen dashboard / splash screen with
;; a plain sectioned list of links, for Emacs, look no further.
;;
;; For more advanced dashboards, refer to `dashboard' or `enlight'.
;;

;;; Code:

(require 'page-break-lines)

(defgroup welkomscherm nil
  "Simple welcome screen / dashboard for Emacs."
  :group 'tools)

(defface welkomscherm-muted-face
  '((t (:inherit 'font-lock-comment-face )))
  "Face used to draw headers and titles."
  :group 'welkomscherm)

(defcustom welkomscherm-centered t
  "User option to enable use of centered text."
  :type 'boolean :group 'welkomscherm)

(defcustom welkomscherm-buffer-name "*welkomscherm*"
  "Name of the welkomscherm buffer."
  :type 'string
  :group 'welkomscherm)

(defcustom welkomscherm-top-title-list
  '("While any editor can save your files"
    "only Emacs can save your soul !")
  "Text lines to show as top title banner."
  :type '(list string)
  :group 'welkomscherm)

(defcustom welkomscherm-bookmarks-name "Bookmarks ♥"
  "Title to show in personal bookmark section."
  :type 'string :group 'welkomscherm)

(defcustom welkomscherm-actions-name "Actions ♦"
  "Title to show for action buttons."
  :type 'string :group 'welkomscherm)

(defcustom welkomscherm-work-name "Work ♠"
  "Title to show for work bookmark section."
  :type 'string :group 'welkomscherm)

(defcustom welkomscherm-init-time-name "Emacs startup took τ"
  "Title to show for init time section."
  :type 'string :group 'welkomscherm)

(defcustom welkomscherm-use-form-feed nil
  "User option to enable use of form feeds to separate sections."
  :type 'boolean :group 'welkomscherm)

(defcustom welkomscherm-use-section-title t
  "User option to enable display of section titles."
  :type 'boolean :group 'welkomscherm)

(defcustom welkomscherm-show-init-time t
  "User option to enable display of init (startup) time."
  :type 'boolean :group 'welkomscherm)

(defcustom welkomscherm-sections (list welkomscherm-top-title
                                       welkomscherm-work
                                       welkomscherm-bookmarks
                                       welkomscherm-actions
                                       welkomscherm-init-time
                                       )
  "A list of section-generating functions."
  :type 'list
  :group 'welkomscherm)

(defcustom welkomscherm-top-title
  (lambda()
    (dolist (x welkomscherm-top-title-list)
      (welkomscherm-insert-muted x)
      (welkomscherm-maybe-centered)
      (welkomscherm-insert-new-line)))
  "Render the top title."
  :type 'function
  :group 'welkomscherm)

(defcustom welkomscherm-bookmarks
  (lambda()
    (welkomscherm-insert-new-line)
    (welkomscherm-maybe-form-feed)
    (when welkomscherm-use-section-title
      (welkomscherm-insert-muted welkomscherm-bookmarks-name))
    (welkomscherm-insert-new-line)
    (welkomscherm-render-rows welkomscherm-bookmarks-list))
  "Render bookmarks section."
  :type 'function
  :group 'welkomscherm)

(defcustom welkomscherm-work
  (lambda()
    (welkomscherm-insert-new-line)
    (welkomscherm-maybe-form-feed)
    (when welkomscherm-use-section-title
      (welkomscherm-insert-muted welkomscherm-work-name))
    (welkomscherm-insert-new-line)
    (welkomscherm-render-rows welkomscherm-work-list))
  "Render work section."
  :type 'function
  :group 'welkomscherm)

(defcustom welkomscherm-actions
  (lambda()
    (welkomscherm-insert-new-line)
    (welkomscherm-maybe-form-feed)
    (when welkomscherm-use-section-title
      (welkomscherm-insert-muted welkomscherm-actions-name))
    (welkomscherm-insert-new-line)
    (welkomscherm-render-action-rows welkomscherm-actions-list))
  "Render actions/buttons."
  :type 'function
  :group 'welkomscherm)

(defcustom welkomscherm-init-time
  (lambda()
    (when welkomscherm-show-init-time
      (welkomscherm-insert-new-line)
      (welkomscherm-insert-muted welkomscherm-init-time-name)
      (welkomscherm-insert-new-line)
      (welkomscherm-insert-muted (emacs-init-time))))
  "Render init time."
  :type 'function
  :group 'welkomscherm)

(defcustom welkomscherm-bookmarks-list
  '((("row0c0" . "~/Dev/row0c0")
     ("row0c1" . "~/Downloads/some-file.pdf"))
    (("row1c0" . "~/Documents/row1c0")))
  "Bookmark alias and path pairs for personal."
  :type 'alist
  :group 'welkomscherm)

(defcustom welkomscherm-work-list
  '((("work-project-1" . "~/Work/work-project-1/")
     ("wiki-work" . "~/Work/wiki-work/")))
  "Bookmark alias and path pairs for work."
  :type 'alist
  :group 'welkomscherm)

(defcustom welkomscherm-actions-list
  '((("*scratch*" . (lambda(btn) (switch-to-buffer "*scratch*")))
     ("*Messages*" . (lambda(btn) (switch-to-buffer "*Messages*")))
     ("re-render me" . (lambda(btn) (welkomscherm)))))
  "Buttons with desired actions in the middle."
  :type 'alist
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

(defun welkomscherm-on-bookmark-click (btn)
  "Action to perform upon clicking a bookmark BTN in welkomscherm."
  (let ((welkomscherm-path (button-get btn 'welkomscherm-path)))
    (find-file welkomscherm-path)))

(defun welkomscherm-render-rows (rows)
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

(defun welkomscherm-render-action-rows (rows)
  "Render ROWS of actions/buttons."
  (dolist (row rows)
    (dolist (x row)
      (insert-button (car x)
                     'action (cdr x))
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
  (dolist (section-thunk welkomscherm-sections)
    (format "%s" section-thunk)
    (apply section-thunk '())))

(defcustom welkomscherm-post-render-hook nil
  "Hook run after `welkomscherm' buffer is created and populated.
This hook is run with `welkomscherm' buffer as current buffer."
  :type 'hook
  :group 'welkomscherm)

(defcustom welkomscherm-pre-render-hook nil
  "Hook run before `welkomscherm' buffer is created.
This hook is run with `welkomscherm' buffer as current buffer."
  :type 'hook
  :group 'welkomscherm)

(defun welkomscherm ()
  "Start a new Welkomscherm killing any live previous instances."
  (interactive)
  (when (buffer-live-p (get-buffer welkomscherm-buffer-name))
    (kill-buffer welkomscherm-buffer-name))
  
  (let ((buf (get-buffer-create welkomscherm-buffer-name)))
    (with-current-buffer buf
      (run-hooks 'welkomscherm-pre-render-hook)
      (read-only-mode -1)
      (setq line-spacing 12)
      (welkomscherm-insert)
      (read-only-mode 1)
      (page-break-lines-mode)
      (run-hooks 'welkomscherm-post-render-hook))
    (switch-to-buffer buf)
    (setq fringe-indicator-alist '((truncation nil)))))


(provide 'welkomscherm)

;;; welkomscherm.el ends here


