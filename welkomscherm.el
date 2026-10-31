;;; welkomscherm.el --- Simple welcome screen / dashboard -*- lexical-binding: t -*-

;; Copyright © Josep Bigorra <jjbigorra@gmail.com>

;; Version: 1.2.4
;; Author: Josep Bigorra <jjbigorra@gmail.com>
;; Maintainer: Josep Bigorra <jjbigorra@gmail.com>
;; URL: https://codeberg.org/jjba23/welkomscherm.el
;; Keywords: splash dashboard faces
;; Package: welkomscherm
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
;; The package needs no external library to run, not even to draw the
;; horizontal rules that separate sections: `welkomscherm/use-separator'
;; draws them from ordinary Emacs text (see `welkomscherm/separator').
;;
;; Every part of the screen is a *section*: a self-contained, reusable
;; unit built with `welkomscherm/make-section'.  A section knows its own
;; heading, its own visibility condition and how to draw its body, so
;; sections can be added, removed or reordered by only touching the
;; `welkomscherm/sections' list; the shared framing lives in one place,
;; `welkomscherm/render-section'.
;;

;;; Code:

(require 'cl-lib)

(defgroup welkomscherm nil
  "Simple welcome screen / dashboard for Emacs."
  :group 'tools)

(defface welkomscherm/muted-face
  '((t (:inherit font-lock-comment-face)))
  "Face used to draw headers and titles."
  :group 'welkomscherm)


;;; User options

(defcustom welkomscherm/centered t
  "Whether the renderer should center text lines."
  :type 'boolean :group 'welkomscherm)

(defcustom welkomscherm/buffer-name "*welkomscherm*"
  "Name of the welkomscherm buffer."
  :type 'string
  :group 'welkomscherm)

(defcustom welkomscherm/top-title-list
  '("While any editor can save your files"
    "only Emacs can save your soul !")
  "Text lines to show as the top title banner."
  :type '(repeat string)
  :group 'welkomscherm)

(defcustom welkomscherm/bookmarks-name "Bookmarks ♥"
  "Title shown above the personal bookmark section."
  :type 'string :group 'welkomscherm)

(defcustom welkomscherm/work-name "Work ♠"
  "Title shown above the work bookmark section."
  :type 'string :group 'welkomscherm)

(defcustom welkomscherm/actions-name "Actions ♦"
  "Title shown above the action buttons."
  :type 'string :group 'welkomscherm)

(defcustom welkomscherm/recent-files-name "Recent ♣"
  "Title shown above the recent files section."
  :type 'string :group 'welkomscherm)

(defcustom welkomscherm/system-details-name "System ⚙"
  "Title shown above the system details section."
  :type 'string :group 'welkomscherm)

(defcustom welkomscherm/init-time-name "Emacs startup took τ"
  "Title shown above the startup time value."
  :type 'string :group 'welkomscherm)

(define-obsolete-variable-alias 'welkomscherm/use-form-feed
  'welkomscherm/use-separator "1.2.0")

(defcustom welkomscherm/use-separator nil
  "Whether to draw a horizontal rule between sections."
  :type 'boolean :group 'welkomscherm)

(defcustom welkomscherm/separator ?─
  "Character repeated to draw the rule shown by `welkomscherm/use-separator'."
  :type 'character :group 'welkomscherm)

(defcustom welkomscherm/separator-width nil
  "Width, in columns, of the section separator.
When nil the rule follows the content: it spans `fill-column' columns, or
WINDOW when that is narrower.  Either way the rule shares the centring
axis of the text, because centring is done within `fill-column' too."
  :type '(choice (const :tag "Follow the content width" nil) integer)
  :group 'welkomscherm)

(defcustom welkomscherm/use-section-title t
  "Whether to display section headings."
  :type 'boolean :group 'welkomscherm)

(defcustom welkomscherm/show-init-time t
  "Whether to display the startup time section."
  :type 'boolean :group 'welkomscherm)

(defcustom welkomscherm/show-system-details nil
  "Whether to display the system details section."
  :type 'boolean :group 'welkomscherm)

(defcustom welkomscherm/show-recent-files nil
  "Whether to display the recent files section."
  :type 'boolean :group 'welkomscherm)

(defcustom welkomscherm/recent-files-limit 5
  "Maximum number of recent files to show."
  :type 'integer :group 'welkomscherm)

(defcustom welkomscherm/line-spacing 10
  "Extra spacing between lines in the welkomscherm buffer.
An integer is a number of pixels and a float is a fraction of the line
height, as for `line-spacing'.  When nil the buffer keeps the existing
editor default `line-spacing'."
  :type '(choice (const :tag "Use the default `line-spacing'" nil)
                 (integer :tag "Pixels")
                 (float :tag "Fraction of the line height"))
  :group 'welkomscherm)

(defcustom welkomscherm/bookmarks-list
  '((("row0c0" . "~/Dev/row0c0")
     ("row0c1" . "~/Downloads/some-file.pdf"))
    (("row1c0" . "~/Documents/row1c0")))
  "Bookmark alias and path pairs for personal use.

A list of rows; each row is a list of (ALIAS . PATH) pairs.  Clicking an
alias opens its path."
  :type 'alist
  :group 'welkomscherm)

(defcustom welkomscherm/work-list
  '((("work-project-1" . "~/Work/work-project-1/")
     ("wiki-work" . "~/Work/wiki-work/")))
  "Bookmark alias and path pairs for work.

A list of rows; each row is a list of (ALIAS . PATH) pairs."
  :type 'alist
  :group 'welkomscherm)

(defcustom welkomscherm/actions-list
  '((("*scratch*" . (lambda(btn) (switch-to-buffer "*scratch*")))
     ("*Messages*" . (lambda(btn) (switch-to-buffer "*Messages*")))
     ("re-render me" . (lambda(btn) (welkomscherm)))))
  "Buttons and their actions.

A list of rows; each row is a list of (LABEL . FUNCTION) pairs, where
FUNCTION is called with the clicked button as its only argument."
  :type 'alist
  :group 'welkomscherm)

(defcustom welkomscherm/system-details-list
  '(("Emacs" . welkomscherm/system-emacs-version)
    ("System" . welkomscherm/system-description)
    ("Host" . system-name)
    ("User" . welkomscherm/system-user-name))
  "Labels and values shown in the system details section.

Each entry is a cons cell whose car is a label string and whose cdr is
either a string or a function of no arguments returning a string."
  :type '(alist :key-type string
                :value-type (choice string function))
  :group 'welkomscherm)

(defcustom welkomscherm/pre-render-hook nil
  "Hook run before the `welkomscherm' buffer is populated."
  :type 'hook
  :group 'welkomscherm)

(defcustom welkomscherm/post-render-hook nil
  "Hook run after the `welkomscherm' buffer is populated."
  :type 'hook
  :group 'welkomscherm)


;;; Sections

(cl-defstruct (welkomscherm/section
               (:constructor welkomscherm/make-section)
               (:copier nil))
  "A self-contained, composable unit of the welcome screen.

A section gathers everything needed to draw one block of the screen:
its heading, the function that draws its body, and the condition that
decides whether it is shown at all.  Build one with
`welkomscherm/make-section' and put it into `welkomscherm/sections'."
  (name nil
        :documentation "Heading string, or a function returning one, or nil.")
  (render #'ignore
          :documentation "Function of no arguments growing the current buffer.")
  (condition nil
             :documentation "Function of no arguments; hides the section when it returns nil."))

(defun welkomscherm/section-visible-p (section)
  "Return non-nil when SECTION passes its own visibility condition.
A section with no condition is always visible."
  (let ((condition (welkomscherm/section-condition section)))
    (or (null condition)
        (not (null (funcall condition))))))

(defun welkomscherm/section-heading (section)
  "Return the heading string of SECTION, or nil when it has none.
The name may be a string or a function returning a string, so that the
heading follows customization made after the section was built."
  (let ((name (welkomscherm/section-name section)))
    (cond
     ((null name) nil)
     ((functionp name) (funcall name))
     (t name))))

(defun welkomscherm/insert-section-heading (name)
  "Insert the heading block for a section named NAME.
A nil NAME means the section has no heading block.  The block honors
`welkomscherm/use-section-title' and `welkomscherm/use-separator'."
  (when name
    (welkomscherm/insert-new-line)
    (welkomscherm/maybe-separator)
    (when welkomscherm/use-section-title
      (welkomscherm/insert-muted name))
    (welkomscherm/insert-new-line)))

(defun welkomscherm/render-section (section)
  "Render SECTION into the current buffer.

SECTION is either a `welkomscherm/section' built with
`welkomscherm/make-section', or a plain function of no arguments, which
is simply called.  A section hidden by its condition renders nothing.
The shared framing (blank line, form feed, heading) is inserted here, so
a section body only ever draws its own content."
  (cond
   ((welkomscherm/section-p section)
    (when (welkomscherm/section-visible-p section)
      (welkomscherm/insert-section-heading
       (welkomscherm/section-heading section))
      (funcall (welkomscherm/section-render section))))
   ((functionp section)
    (funcall section))
   (t (error "Not a welkomscherm section: %S" section))))


;;; Insertion primitives

(defun welkomscherm/insert-muted (x)
  "Insert muted text X into the welkomscherm buffer with optional centering."
  (insert (propertize x 'face 'welkomscherm/muted-face))
  (welkomscherm/maybe-centered))

(defun welkomscherm/insert-new-line ()
  "Insert a new line into the welkomscherm buffer."
  (insert "\n"))

(defconst welkomscherm/separator-marker ?\f
  "Character stored in the buffer to mark a section separator.
It is the page break of a plain text file; the buffer keeps that plain
marker and `welkomscherm/update-separator-display' draws it as a rule.")

(defun welkomscherm/separator-columns (&optional window)
  "Return the number of columns the section separator should span.
The rule follows the content width: `fill-column' columns, or WINDOW when
that is narrower.  WINDOW defaults to the selected window."
  (or welkomscherm/separator-width
      (max 1 (min fill-column (window-max-chars-per-line window)))))

(defun welkomscherm/separator-glyphs (&optional window)
  "Return the display-table entry that draws a separator in WINDOW.
It is a vector of the separator glyph repeated to WINDOW's width, so a
form feed in the buffer shows as a horizontal rule."
  (vconcat (make-list (welkomscherm/separator-columns window)
                      (make-glyph-code welkomscherm/separator
                                       'welkomscherm/muted-face))))

(defun welkomscherm/insert-separator ()
  "Insert a section separator followed by a new line.
The separator is the form feed `welkomscherm/separator-marker', which
`welkomscherm/update-separator-display' draws as a horizontal rule."
  (insert welkomscherm/separator-marker)
  (insert "\n"))

(defun welkomscherm/maybe-separator ()
  "Insert a section separator when `welkomscherm/use-separator' is non-nil."
  (when welkomscherm/use-separator (welkomscherm/insert-separator)))

(defun welkomscherm/update-separator-display-window (window)
  "Make WINDOW draw the welcome screen's separators as horizontal rules.
Leaves a window that does not show the welcome screen untouched."
  (with-current-buffer (window-buffer window)
    (when (and welkomscherm/use-separator
               (equal (current-buffer)
                      (get-buffer welkomscherm/buffer-name)))
      (unless buffer-display-table
        (setq buffer-display-table (make-display-table)))
      (let ((entry (welkomscherm/separator-glyphs window)))
        (unless (equal entry (aref buffer-display-table
                                   welkomscherm/separator-marker))
          (aset buffer-display-table
                welkomscherm/separator-marker entry))))))

(defun welkomscherm/update-separator-display (&optional frame)
  "Draw the welcome screen's separators as horizontal rules.
Called when FRAME is resized or its windows change, so that the rules
re-flow to the window width with no library beyond Emacs itself."
  (when (buffer-live-p (get-buffer welkomscherm/buffer-name))
    (dolist (window (window-list frame 'no-minibuffer))
      (welkomscherm/update-separator-display-window window))))

(add-hook 'window-size-change-functions
          #'welkomscherm/update-separator-display)
(add-hook 'window-configuration-change-hook
          #'welkomscherm/update-separator-display)
(add-hook 'after-setting-font-hook
          #'welkomscherm/update-separator-display)

(defun welkomscherm/insert-spacer ()
  "Insert a spacer into the welkomscherm buffer."
  (insert "  "))

(defun welkomscherm/maybe-centered ()
  "Center the current line when `welkomscherm/centered' is non-nil."
  (when welkomscherm/centered (center-line)))

(define-obsolete-function-alias 'welkomscherm/insert-form-feed
  'welkomscherm/insert-separator "1.2.0")
(define-obsolete-function-alias 'welkomscherm/maybe-form-feed
  'welkomscherm/maybe-separator "1.2.0")


;;; Row rendering

(defun welkomscherm/render-rows (rows)
  "Render ROWS of bookmark buttons.
ROWS is a list of rows; each row is a list of (ALIAS . PATH) pairs."
  (dolist (row rows)
    (dolist (x row)
      (insert-button (car x)
                     'welkomscherm/alias (car x)
                     'welkomscherm/path (cdr x)
                     'action 'welkomscherm/on-bookmark-click)
      (welkomscherm/insert-spacer))
    (welkomscherm/maybe-centered)
    (welkomscherm/insert-new-line)))

(defun welkomscherm/render-action-rows (rows)
  "Render ROWS of action buttons.
ROWS is a list of rows; each row is a list of (LABEL . FUNCTION) pairs."
  (dolist (row rows)
    (dolist (x row)
      (insert-button (car x)
                     'action (cdr x))
      (welkomscherm/insert-spacer))
    (welkomscherm/maybe-centered)
    (welkomscherm/insert-new-line)))

(defun welkomscherm/on-bookmark-click (btn)
  "Open the file stored on bookmark button BTN."
  (find-file (button-get btn 'welkomscherm/path)))


;;; System details

(defun welkomscherm/system-emacs-version ()
  "Return the running Emacs version as a MAJOR.MINOR string."
  (format "%d.%d" emacs-major-version emacs-minor-version))

(defun welkomscherm/system-description ()
  "Return a short description of the system Emacs runs on."
  (format "%s (%s)" system-type (or system-configuration "unknown")))

(defun welkomscherm/system-user-name ()
  "Return the login name of the current user."
  (or (getenv "USER") (getenv "LOGNAME") user-login-name "unknown"))

(defun welkomscherm/render-system-details ()
  "Render the rows of the system details section."
  (dolist (entry welkomscherm/system-details-list)
    (let* ((label (car entry))
           (value (cdr entry))
           (value (if (functionp value) (funcall value) value)))
      (welkomscherm/insert-muted (format "%s: %s" label value))
      (welkomscherm/insert-new-line))))


;;; Recent files

(defun welkomscherm/recent-files ()
  "Return up to `welkomscherm/recent-files-limit' recently visited files.

The list comes from the built-in `recentf-list' that `recentf-mode'
maintains.  Each element is a cons cell of a display name and the file
path.  The result is nil when recentf is unavailable, empty, or when no
recent file still exists on disk."
  (when (require 'recentf nil t)
    (let ((files (and (boundp 'recentf-list) recentf-list))
          (n welkomscherm/recent-files-limit)
          result)
      (dolist (file files)
        (when (and (> n 0) (stringp file) (file-exists-p file))
          (push (cons (file-name-nondirectory (directory-file-name file)) file)
                result)
          (setq n (1- n))))
      (nreverse result))))


;;; Section bodies

(defun welkomscherm/render-top-title ()
  "Render the top title banner."
  (dolist (line welkomscherm/top-title-list)
    (welkomscherm/insert-muted line)
    (welkomscherm/insert-new-line)))

(defun welkomscherm/render-bookmarks ()
  "Render the personal bookmarks."
  (welkomscherm/render-rows welkomscherm/bookmarks-list))

(defun welkomscherm/render-work ()
  "Render the work bookmarks."
  (welkomscherm/render-rows welkomscherm/work-list))

(defun welkomscherm/render-actions ()
  "Render the action buttons."
  (welkomscherm/render-action-rows welkomscherm/actions-list))

(defun welkomscherm/render-recent-files ()
  "Render the recently visited files as clickable rows."
  (welkomscherm/render-rows (list (welkomscherm/recent-files))))

(defun welkomscherm/render-init-time ()
  "Render how long Emacs startup took."
  (welkomscherm/insert-muted (emacs-init-time)))


;;; The default sections

(defcustom welkomscherm/top-title
  (welkomscherm/make-section :render #'welkomscherm/render-top-title)
  "The top title banner section."
  :type 'sexp
  :group 'welkomscherm)

(defcustom welkomscherm/work
  (welkomscherm/make-section
   :name (lambda () welkomscherm/work-name)
   :condition (lambda () welkomscherm/work-list)
   :render #'welkomscherm/render-work)
  "The work bookmarks section."
  :type 'sexp
  :group 'welkomscherm)

(defcustom welkomscherm/bookmarks
  (welkomscherm/make-section
   :name (lambda () welkomscherm/bookmarks-name)
   :condition (lambda () welkomscherm/bookmarks-list)
   :render #'welkomscherm/render-bookmarks)
  "The personal bookmarks section."
  :type 'sexp
  :group 'welkomscherm)

(defcustom welkomscherm/recent-files-section
  (welkomscherm/make-section
   :name (lambda () welkomscherm/recent-files-name)
   :condition (lambda ()
                (and welkomscherm/show-recent-files
                     (welkomscherm/recent-files)))
   :render #'welkomscherm/render-recent-files)
  "The recent files section."
  :type 'sexp
  :group 'welkomscherm)

(defcustom welkomscherm/actions
  (welkomscherm/make-section
   :name (lambda () welkomscherm/actions-name)
   :condition (lambda () welkomscherm/actions-list)
   :render #'welkomscherm/render-actions)
  "The action buttons section."
  :type 'sexp
  :group 'welkomscherm)

(defcustom welkomscherm/system-details
  (welkomscherm/make-section
   :name (lambda () welkomscherm/system-details-name)
   :condition (lambda () welkomscherm/show-system-details)
   :render #'welkomscherm/render-system-details)
  "The system details section."
  :type 'sexp
  :group 'welkomscherm)

(defcustom welkomscherm/init-time
  (welkomscherm/make-section
   :name (lambda () welkomscherm/init-time-name)
   :condition (lambda () welkomscherm/show-init-time)
   :render #'welkomscherm/render-init-time)
  "The startup time section."
  :type 'sexp
  :group 'welkomscherm)

(defcustom welkomscherm/sections
  (list welkomscherm/top-title
        welkomscherm/work
        welkomscherm/bookmarks
        welkomscherm/recent-files-section
        welkomscherm/actions
        welkomscherm/system-details
        welkomscherm/init-time)
  "The sections to render, in order.

Each element is either a section built with `welkomscherm/make-section',
or a plain function of no arguments.  Reorder this list to reorder the
screen, drop a section to hide its default, or build a new section to
add your own."
  :type '(repeat sexp)
  :group 'welkomscherm)


;;; The major mode

(defvar welkomscherm-mode-map
  (let ((map (make-sparse-keymap)))
    (set-keymap-parent map (make-composed-keymap button-buffer-map special-mode-map))
    map)
  "Keymap for `welkomscherm-mode'.")

(define-derived-mode welkomscherm-mode special-mode "Welkomscherm"
  "Major mode for welkomscherm buffers."
  :group 'welkomscherm
  (when welkomscherm/line-spacing
    (setq-local line-spacing welkomscherm/line-spacing))
  (setq-local fringe-indicator-alist '((truncation nil))
              revert-buffer-function (lambda (_ _) (welkomscherm))))

;;; Rendering the screen

(defun welkomscherm/render-to-screen ()
  "Render every section of `welkomscherm/sections', in order."
  (dolist (section welkomscherm/sections)
    (welkomscherm/render-section section)))

;;;###autoload
(defun welkomscherm ()
  "Start a new Welkomscherm killing any live previous instances."
  (interactive)
  (when (buffer-live-p (get-buffer welkomscherm/buffer-name))
    (kill-buffer welkomscherm/buffer-name))

  (let ((buf (get-buffer-create welkomscherm/buffer-name)))
    (with-current-buffer buf
      (welkomscherm-mode)
      (run-hooks 'welkomscherm/pre-render-hook)
      (let ((inhibit-read-only t))
        (erase-buffer)
        (welkomscherm/render-to-screen))
      ;; Rendering ends with point at the end of the buffer, so a freshly
      ;; displayed dashboard would already be scrolled down to its last line.
      ;; Put point back on the first line; the post-render hook still runs
      ;; with the buffer current and is free to move point on purpose.
      (goto-char (point-min))
      (run-hooks 'welkomscherm/post-render-hook))
    (switch-to-buffer buf)
    (welkomscherm/update-separator-display)))


(provide 'welkomscherm)

;;; welkomscherm.el ends here
