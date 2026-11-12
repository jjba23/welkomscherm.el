;;; welkomscherm-test.el --- ERT tests for welkomscherm -*- lexical-binding: t -*-

;; Copyright © Josep Bigorra <jjbigorra@gmail.com>

;; SPDX-License-Identifier: MIT

;;; Commentary:

;; ERT suite for welkomscherm.el.  It checks the section abstraction,
;; the rendering primitives, the two opt-in sections, and that the whole
;; package loads without any external library.
;;
;; Run it with:
;;
;;   emacs -Q --batch -L . -L test -l test/welkomscherm-test.el \
;;         -f ert-run-tests-batch-and-exit
;;
;; or simply `maak' in the project root.

;;; Code:

(require 'ert)
(require 'cl-lib)
(require 'button)
(require 'recentf)   ; built-in; declares `recentf-list' as a special variable

;; Load the package under test, whether we were run from the project root
;; (via -L .) or straight from the test file.
(when (and load-file-name (not (featurep 'welkomscherm)))
  (add-to-list 'load-path
               (expand-file-name ".." (file-name-directory load-file-name))))
(require 'welkomscherm)

(defconst welkomscherm-test--test-dir
  (file-name-directory (or load-file-name buffer-file-name))
  "Directory holding this test file.")

(defconst welkomscherm-test--source
  (expand-file-name "../welkomscherm.el" welkomscherm-test--test-dir)
  "Absolute path of the package source under test.")

(defun welkomscherm-test--body (thunk)
  "Run THUNK in a temp buffer with centering off and return its contents."
  (with-temp-buffer
    (let ((welkomscherm/centered nil))
      (funcall thunk))
    (buffer-string)))


;;; Package surface

(ert-deftest welkomscherm-test/provides-feature ()
  "The package loads and provides its feature."
  (should (featurep 'welkomscherm)))

(ert-deftest welkomscherm-test/group-and-face-exist ()
  "The customization group and muted face are defined."
  (should (get 'welkomscherm 'custom-group))
  (should (facep 'welkomscherm/muted-face))
  (should (custom-variable-p 'welkomscherm/centered)))

(ert-deftest welkomscherm-test/muted-face-inherits-font-lock ()
  "The muted face inherits `font-lock-comment-face' correctly.

This guards the old bug where the inherit value was the quoted symbol
`(quote font-lock-comment-face)' instead of the face itself."
  (should (eq (face-attribute 'welkomscherm/muted-face :inherit)
              'font-lock-comment-face)))

(ert-deftest welkomscherm-test/no-external-libraries ()
  "The package requires no external library, not even to draw rules."
  (let ((source (with-temp-buffer
                  (insert-file-contents welkomscherm-test--source)
                  (buffer-string))))
    (should-not (string-match-p "page-break-lines" source))
    (should (string-match-p "welkomscherm/separator-glyphs" source))))

(ert-deftest welkomscherm-test/buffer-name-default ()
  "The default buffer name is the documented one."
  (should (equal welkomscherm/buffer-name "*welkomscherm*")))

(ert-deftest welkomscherm-test/default-sections-are-composable ()
  "Every default section is a section record or a plain function."
  (should (cl-every (lambda (section)
                      (or (welkomscherm/section-p section)
                          (functionp section)))
                    welkomscherm/sections)))

(ert-deftest welkomscherm-test/default-sections-include-new-sections ()
  "The default section list includes the opt-in sections."
  (should (memq welkomscherm/system-details welkomscherm/sections))
  (should (memq welkomscherm/recent-files-section welkomscherm/sections))
  (should (memq welkomscherm/agenda-section welkomscherm/sections)))

(ert-deftest welkomscherm-test/new-sections-are-opt-in ()
  "Both new sections default to off."
  (should-not welkomscherm/show-system-details)
  (should-not welkomscherm/show-recent-files))


;;; The section abstraction

(ert-deftest welkomscherm-test/make-section-defaults ()
  "A fresh section is visible, has no heading and renders nothing."
  (let ((section (welkomscherm/make-section)))
    (should (welkomscherm/section-p section))
    (should (null (welkomscherm/section-name section)))
    (should (null (welkomscherm/section-heading section)))
    (should (welkomscherm/section-visible-p section))))

(ert-deftest welkomscherm-test/section-heading-from-string ()
  "A string heading is returned as-is."
  (should (equal (welkomscherm/section-heading
                  (welkomscherm/make-section :name "Links"))
                 "Links")))

(ert-deftest welkomscherm-test/section-heading-follows-function ()
  "A function heading is resolved each time, tracking customization."
  (let* ((title "One")
         (section (welkomscherm/make-section :name (lambda () title))))
    (should (equal (welkomscherm/section-heading section) "One"))
    (setq title "Two")
    (should (equal (welkomscherm/section-heading section) "Two"))))

(ert-deftest welkomscherm-test/section-visibility-condition ()
  "A condition hides a section when it returns nil."
  (let ((shown nil))
    (let ((section (welkomscherm/make-section
                    :condition (lambda () shown))))
      (should-not (welkomscherm/section-visible-p section))
      (setq shown t)
      (should (welkomscherm/section-visible-p section)))))

(ert-deftest welkomscherm-test/render-section-frames-heading ()
  "Rendering a section draws its heading and then its body."
  (let ((text (welkomscherm-test--body
               (lambda ()
                 (let ((welkomscherm/use-section-title t)
                       (welkomscherm/use-form-feed nil))
                   (welkomscherm/render-section
                    (welkomscherm/make-section
                     :name "Heading"
                     :render (lambda () (insert "body")))))))))
    (should (string-match-p "Heading" text))
    (should (string-match-p "body" text))))

(ert-deftest welkomscherm-test/render-section-without-heading ()
  "A section with no heading omits the heading block."
  (let ((text (welkomscherm-test--body
               (lambda ()
                 (welkomscherm/render-section
                  (welkomscherm/make-section
                   :render (lambda () (insert "body"))))))))
    (should (equal text "body"))))

(ert-deftest welkomscherm-test/render-section-honors-condition ()
  "A section hidden by its condition draws nothing at all."
  (let ((text (welkomscherm-test--body
               (lambda ()
                 (welkomscherm/render-section
                  (welkomscherm/make-section
                   :name "Hidden"
                   :condition (lambda () nil)
                   :render (lambda () (insert "body"))))))))
    (should (equal text ""))))

(ert-deftest welkomscherm-test/render-section-accepts-plain-function ()
  "A bare function is still accepted as a section."
  (let ((text (welkomscherm-test--body
               (lambda ()
                 (welkomscherm/render-section
                  (lambda () (insert "plain")))))))
    (should (equal text "plain"))))

(ert-deftest welkomscherm-test/render-section-rejects-garbage ()
  "Rendering something that is not a section signals an error."
  (should-error (with-temp-buffer (welkomscherm/render-section 42))))

(ert-deftest welkomscherm-test/sections-can-be-reordered ()
  "Reordering `welkomscherm/sections' reorders the screen."
  (let ((text (welkomscherm-test--body
               (lambda ()
                 (let ((welkomscherm/use-section-title t)
                       (welkomscherm/use-form-feed nil)
                       (welkomscherm/sections
                        (list (welkomscherm/make-section
                               :name "Second"
                               :render (lambda () (insert "2")))
                              (welkomscherm/make-section
                               :name "First"
                               :render (lambda () (insert "1"))))))
                   (welkomscherm/render-to-screen))))))
    (should (< (string-match-p "Second" text)
               (string-match-p "First" text)))))


;;; Rendering primitives

(ert-deftest welkomscherm-test/insert-new-line ()
  "`welkomscherm/insert-new-line' inserts a single newline."
  (should (equal (welkomscherm-test--body #'welkomscherm/insert-new-line)
                 "\n")))

(ert-deftest welkomscherm-test/insert-separator ()
  "`welkomscherm/insert-separator' inserts the marker and ends the line."
  (should (equal (welkomscherm-test--body #'welkomscherm/insert-separator)
                 "\f\n")))

(ert-deftest welkomscherm-test/separator-columns ()
  "The separator width honours the option and the content width."
  (let ((welkomscherm/separator-width 12))
    (should (= (welkomscherm/separator-columns) 12)))
  (let ((welkomscherm/separator-width nil)
        (fill-column 10))
    (should (= (welkomscherm/separator-columns) 10))))

(ert-deftest welkomscherm-test/separator-glyphs ()
  "The separator draws as many glyphs as it has columns."
  (let ((welkomscherm/separator-width 4))
    (let ((entry (welkomscherm/separator-glyphs)))
      (should (vectorp entry))
      (should (= (length entry) 4))
      (should (cl-every #'identity entry)))))

(ert-deftest welkomscherm-test/obsolete-form-feed-names-still-work ()
  "The old form-feed names remain as aliases, for a gentle migration."
  (should (eq (indirect-variable 'welkomscherm/use-form-feed)
              'welkomscherm/use-separator))
  (should (equal (indirect-function 'welkomscherm/insert-form-feed)
                 (indirect-function 'welkomscherm/insert-separator)))
  (should (equal (indirect-function 'welkomscherm/maybe-form-feed)
                 (indirect-function 'welkomscherm/maybe-separator))))

(ert-deftest welkomscherm-test/insert-spacer ()
  "`welkomscherm/insert-spacer' inserts two spaces."
  (should (equal (welkomscherm-test--body #'welkomscherm/insert-spacer)
                 "  ")))

(ert-deftest welkomscherm-test/insert-muted-adds-face ()
  "`welkomscherm/insert-muted' inserts text carrying the muted face."
  (with-temp-buffer
    (let ((welkomscherm/centered nil))
      (welkomscherm/insert-muted "hello"))
    (should (equal (buffer-string) "hello"))
    (should (eq (get-text-property (point-min) 'face)
                'welkomscherm/muted-face))))

(ert-deftest welkomscherm-test/maybe-separator-respects-option ()
  "The horizontal rule is only drawn when the option is enabled."
  (with-temp-buffer
    (let ((welkomscherm/use-separator nil))
      (welkomscherm/maybe-separator))
    (should (equal (buffer-string) ""))
    (let ((welkomscherm/use-separator t))
      (welkomscherm/maybe-separator))
    (should (equal (buffer-string) "\f\n"))))

(ert-deftest welkomscherm-test/render-section-draws-separator ()
  "A section inserts the separator marker when separators are enabled."
  (let ((text (welkomscherm-test--body
               (lambda ()
                 (let ((welkomscherm/use-separator t))
                   (welkomscherm/render-section
                    (welkomscherm/make-section
                     :name "Heading"
                     :render (lambda () (insert "body")))))))))
    (should (string-match-p "\f" text))
    (should (string-match-p "body" text))))

(ert-deftest welkomscherm-test/separators-show-as-rules ()
  "The welcome buffer maps its separator marker to a rule of glyphs."
  (save-window-excursion
    (unwind-protect
        (let ((welkomscherm/use-separator t)
              (welkomscherm/separator-width 7))
          (welkomscherm)
          (welkomscherm/update-separator-display)
          (with-current-buffer welkomscherm/buffer-name
            (should (string-match-p "\f" (buffer-string)))
            (let ((entry (aref buffer-display-table ?\f)))
              (should (vectorp entry))
              (should (= (length entry) 7)))))
      (when (buffer-live-p (get-buffer welkomscherm/buffer-name))
        (kill-buffer welkomscherm/buffer-name)))))

(ert-deftest welkomscherm-test/separators-reflow-on-resize-hooks ()
  "The separator display is refreshed when windows change."
  (should (memq 'welkomscherm/update-separator-display
                window-size-change-functions))
  (should (memq 'welkomscherm/update-separator-display
                window-configuration-change-hook)))

(ert-deftest welkomscherm-test/maybe-centered-respects-option ()
  "Centering is skipped when disabled and attempted when enabled."
  (with-temp-buffer
    (insert "hello")
    (let ((welkomscherm/centered nil))
      (welkomscherm/maybe-centered))
    (should (equal (buffer-string) "hello"))
    (should (null (let ((welkomscherm/centered t))
                    (welkomscherm/maybe-centered))))))

(ert-deftest welkomscherm-test/render-rows-creates-bookmark-buttons ()
  "`welkomscherm/render-rows' creates buttons with the right properties."
  (with-temp-buffer
    (let ((welkomscherm/centered nil))
      (welkomscherm/render-rows '((("a" . "/tmp/a") ("b" . "/tmp/b")))))
    (let ((first (button-at (point-min))))
      (should first)
      (should (equal (button-get first 'welkomscherm/alias) "a"))
      (should (equal (button-get first 'welkomscherm/path) "/tmp/a"))
      (should (eq (button-get first 'action) 'welkomscherm/on-bookmark-click)))
    (goto-char (point-min))
    (forward-button 1)
    (let ((second (button-at (point))))
      (should (equal (button-get second 'welkomscherm/alias) "b"))
      (should (equal (button-get second 'welkomscherm/path) "/tmp/b")))))

(ert-deftest welkomscherm-test/render-action-rows-creates-action-buttons ()
  "`welkomscherm/render-action-rows' attaches the given action."
  (let ((action (lambda (btn) (ignore btn))))
    (with-temp-buffer
      (let ((welkomscherm/centered nil))
        (welkomscherm/render-action-rows (list (list (cons "go" action)))))
      (let ((button (button-at (point-min))))
        (should (equal (button-label button) "go"))
        (should (eq (button-get button 'action) action))))))

(ert-deftest welkomscherm-test/on-bookmark-click-opens-file ()
  "Clicking a bookmark button visits its file."
  (let ((file (make-temp-file "welkomscherm-click" nil ".txt")))
    (unwind-protect
        (progn
          (with-temp-buffer
            (welkomscherm/on-bookmark-click
             (insert-button "x" 'welkomscherm/path file)))
          (should (buffer-live-p (get-file-buffer file))))
      (when (get-file-buffer file)
        (kill-buffer (get-file-buffer file)))
      (delete-file file))))

(ert-deftest welkomscherm-test/render-system-details ()
  "System detail rows render labels and resolve function values."
  (with-temp-buffer
    (let ((welkomscherm/centered nil)
          (welkomscherm/system-details-list
           '(("A" . "1") ("B" . (lambda () "2")))))
      (welkomscherm/render-system-details))
    (should (string-match-p "A: 1" (buffer-string)))
    (should (string-match-p "B: 2" (buffer-string)))))

(ert-deftest welkomscherm-test/render-to-screen-calls-every-section ()
  "`welkomscherm/render-to-screen' calls each section, in order."
  (let (calls)
    (let ((welkomscherm/sections (list (lambda () (push 'a calls))
                                       (lambda () (push 'b calls))
                                       (lambda () (push 'c calls)))))
      (welkomscherm/render-to-screen))
    (should (equal (nreverse calls) '(a b c)))))


;;; System details section

(ert-deftest welkomscherm-test/system-emacs-version ()
  "The reported Emacs version matches the running one."
  (should (string= (welkomscherm/system-emacs-version)
                   (format "%d.%d" emacs-major-version emacs-minor-version))))

(ert-deftest welkomscherm-test/system-user-name ()
  "The reported user name is a non-empty string."
  (let ((name (welkomscherm/system-user-name)))
    (should (stringp name))
    (should (> (length name) 0))))

(ert-deftest welkomscherm-test/system-description ()
  "The system description mentions the `system-type'."
  (should (string-match-p (regexp-quote (symbol-name system-type))
                          (welkomscherm/system-description))))

(ert-deftest welkomscherm-test/system-details-section-off-by-default ()
  "The system details section renders nothing when disabled."
  (let ((text (welkomscherm-test--body
               (lambda ()
                 (let ((welkomscherm/show-system-details nil))
                   (welkomscherm/render-section welkomscherm/system-details))))))
    (should (equal text ""))))

(ert-deftest welkomscherm-test/system-details-section-on ()
  "The system details section renders values when enabled."
  (let ((text (welkomscherm-test--body
               (lambda ()
                 (let ((welkomscherm/show-system-details t))
                   (welkomscherm/render-section welkomscherm/system-details))))))
    (should (string-match-p "Emacs: " text))
    (should (string-match-p (regexp-quote (welkomscherm/system-emacs-version))
                            text))))


;;; Recent files section

(ert-deftest welkomscherm-test/recent-files-limits-and-filters ()
  "Recent files are limited and files missing from disk are dropped."
  (let ((file-a (make-temp-file "welkomscherm-recent-a"))
        (file-b (make-temp-file "welkomscherm-recent-b"))
        (file-c (make-temp-file "welkomscherm-recent-c"))
        (gone (expand-file-name "welkomscherm-gone-does-not-exist"
                                temporary-file-directory)))
    (unwind-protect
        (let ((recentf-list (list file-a gone file-b file-c))
              (welkomscherm/recent-files-limit 2))
          (let ((result (welkomscherm/recent-files)))
            (should (= (length result) 2))
            (should (equal (mapcar #'cdr result) (list file-a file-b)))
            (should (equal (caar result)
                           (file-name-nondirectory file-a)))))
      (delete-file file-a)
      (delete-file file-b)
      (delete-file file-c))))

(ert-deftest welkomscherm-test/recent-files-empty ()
  "No recent files yields no rows."
  (let ((recentf-list nil))
    (should (null (welkomscherm/recent-files)))))

(ert-deftest welkomscherm-test/recent-files-section-off-by-default ()
  "The recent files section renders nothing when disabled."
  (let ((file (make-temp-file "welkomscherm-recent")))
    (unwind-protect
        (let ((recentf-list (list file))
              (text (welkomscherm-test--body
                     (lambda ()
                       (let ((welkomscherm/show-recent-files nil))
                         (welkomscherm/render-section
                          welkomscherm/recent-files-section))))))
          (should (equal text "")))
      (delete-file file))))

(ert-deftest welkomscherm-test/recent-files-section-on ()
  "The recent files section renders the recent files when enabled."
  (let ((file (make-temp-file "welkomscherm-recent")))
    (unwind-protect
        (let ((recentf-list (list file)))
          (with-temp-buffer
            (let ((welkomscherm/centered nil)
                  (welkomscherm/show-recent-files t))
              (welkomscherm/render-section welkomscherm/recent-files-section))
            (should (string-match-p
                     (regexp-quote (file-name-nondirectory file))
                     (buffer-string)))
            (should (next-button (point-min)))))
      (delete-file file))))


;;; Recent files layout

(ert-deftest welkomscherm-test/recent-files-one-per-line-with-directory ()
  "Each recent file gets its own line, with the directory it lives in.
Two files called the same name in different directories are told apart
by the muted directory, and centring keeps that column aligned."
  (let* ((dir-a (make-temp-file "welkomscherm-dir-a" t))
         (dir-b (make-temp-file "welkomscherm-dir-b" t))
         (file-a (expand-file-name "a.org" dir-a))
         (file-b (expand-file-name "much-longer.org" dir-b)))
    (unwind-protect
        (progn
          (write-region "" nil file-a)
          (write-region "" nil file-b)
          (let ((recentf-list (list file-a file-b)))
            (with-temp-buffer
              (let ((welkomscherm/centered t)
                    (fill-column 72))
                (welkomscherm/render-recent-files))
              (let ((lines (split-string (buffer-string) "\n" t)))
                (should (= (length lines) 2))
                (should (string-match-p (regexp-quote dir-a) (nth 0 lines)))
                (should (string-match-p (regexp-quote dir-b) (nth 1 lines)))
                (should (= (string-match (regexp-quote dir-a) (nth 0 lines))
                           (string-match (regexp-quote dir-b)
                                         (nth 1 lines))))))))
      (delete-directory dir-a t)
      (delete-directory dir-b t))))


;;; Agenda section

(require 'org)
(require 'org-agenda)

(defmacro welkomscherm-test--with-agenda (contents &rest body)
  "Evaluate BODY with `org-agenda-files' on a temp file holding CONTENTS."
  (declare (indent 1))
  `(let ((welkomscherm-test--agenda-file
          (make-temp-file "welkomscherm-agenda" nil ".org")))
     (unwind-protect
         (progn
           (with-temp-file welkomscherm-test--agenda-file
             (insert ,contents))
           (let ((org-agenda-files (list welkomscherm-test--agenda-file)))
             ,@body))
       (when-let* ((buffer (find-buffer-visiting
                            welkomscherm-test--agenda-file)))
         (kill-buffer buffer))
       (delete-file welkomscherm-test--agenda-file))))

(defun welkomscherm-test--org-day (offset)
  "Return the YYYY-MM-DD date OFFSET days from today."
  (format-time-string "%Y-%m-%d" (time-add nil (days-to-time offset))))

(defun welkomscherm-test--agenda-texts ()
  "Return the text of every entry the agenda currently has."
  (mapcar (lambda (entry) (plist-get entry :text))
          (welkomscherm/agenda-entries)))

(ert-deftest welkomscherm-test/agenda-entries-follow-the-days-option ()
  "The agenda collects today's entries and the days ahead, no further."
  (let ((contents (format "* TODO Call the bank\n  SCHEDULED: <%s>\n* TODO File the taxes\n  DEADLINE: <%s>\n"
                          (welkomscherm-test--org-day 0)
                          (welkomscherm-test--org-day 2))))
    (welkomscherm-test--with-agenda contents
      (let ((welkomscherm/agenda-days 7))
        (should (equal (welkomscherm-test--agenda-texts)
                       '("TODO Call the bank" "TODO File the taxes"))))
      (let ((welkomscherm/agenda-days 2))
        (should (equal (welkomscherm-test--agenda-texts)
                       '("TODO Call the bank")))))))

(ert-deftest welkomscherm-test/agenda-entries-skip-done-and-strip-tags ()
  "Finished tasks stay out of the agenda and tags stay out of the text."
  (let ((contents (format "* DONE Old thing\n  SCHEDULED: <%s>\n* TODO Tagged thing :work:urgent:\n  SCHEDULED: <%s>\n"
                          (welkomscherm-test--org-day 0)
                          (welkomscherm-test--org-day 0))))
    (welkomscherm-test--with-agenda contents
      (let ((welkomscherm/agenda-days 1))
        (should (equal (welkomscherm-test--agenda-texts)
                       '("TODO Tagged thing")))))))

(ert-deftest welkomscherm-test/agenda-entries-empty-without-files ()
  "Without agenda files there is nothing to show."
  (let ((org-agenda-files nil))
    (should (null (welkomscherm/agenda-entries)))))

(ert-deftest welkomscherm-test/agenda-section-is-opt-in ()
  "The agenda section is off by default and draws nothing when off."
  (should-not welkomscherm/show-agenda)
  (welkomscherm-test--with-agenda (format "* TODO Call the bank\n  SCHEDULED: <%s>\n"
                                          (welkomscherm-test--org-day 0))
    (let ((text (welkomscherm-test--body
                 (lambda ()
                   (let ((welkomscherm/show-agenda nil))
                     (welkomscherm/render-section
                      welkomscherm/agenda-section))))))
      (should (equal text "")))))

(ert-deftest welkomscherm-test/agenda-section-groups-by-day ()
  "The agenda section labels each day and offers a button per entry."
  (let ((contents (format "* TODO Call the bank\n  SCHEDULED: <%s>\n* TODO File the taxes\n  DEADLINE: <%s>\n"
                          (welkomscherm-test--org-day 0)
                          (welkomscherm-test--org-day 1))))
    (welkomscherm-test--with-agenda contents
      (with-temp-buffer
        (let ((welkomscherm/centered nil)
              (welkomscherm/show-agenda t)
              (welkomscherm/agenda-days 7))
          (welkomscherm/render-section welkomscherm/agenda-section))
        (should (string-match-p "Today" (buffer-string)))
        (should (string-match-p "Tomorrow" (buffer-string)))
        (let ((button (next-button (point-min))))
          (should button)
          (should (equal (button-label button) "TODO Call the bank"))
          (should (markerp (button-get button 'welkomscherm/marker))))))))

(ert-deftest welkomscherm-test/agenda-section-hides-when-empty ()
  "An enabled agenda with no entries leaves no empty heading behind."
  (welkomscherm-test--with-agenda "* A plain heading with no date\n"
    (let ((text (welkomscherm-test--body
                 (lambda ()
                   (let ((welkomscherm/show-agenda t))
                     (welkomscherm/render-section
                      welkomscherm/agenda-section))))))
      (should (equal text "")))))

(ert-deftest welkomscherm-test/agenda-click-visits-the-heading ()
  "Clicking an agenda button visits the Org heading it came from."
  (welkomscherm-test--with-agenda (format "* TODO Call the bank\n  SCHEDULED: <%s>\n"
                                          (welkomscherm-test--org-day 0))
    (save-window-excursion
      (with-temp-buffer
        (let ((welkomscherm/centered nil)
              (welkomscherm/agenda-days 1))
          (welkomscherm/render-agenda)
          (welkomscherm/on-agenda-click (next-button (point-min))))
        (should (equal (buffer-substring-no-properties
                        (line-beginning-position) (line-end-position))
                       "* TODO Call the bank"))))))


;;; Whole-buffer rendering

(ert-deftest welkomscherm-test/renders-a-read-only-buffer ()
  "`welkomscherm' produces a populated, read-only buffer."
  (save-window-excursion
    (unwind-protect
        (progn
          (welkomscherm)
          (should (buffer-live-p (get-buffer welkomscherm/buffer-name)))
          (with-current-buffer welkomscherm/buffer-name
            (should buffer-read-only)
            (should (> (buffer-size) 0))
            (should (string-match-p
                     "While any editor can save your files"
                     (buffer-string)))))
      (when (buffer-live-p (get-buffer welkomscherm/buffer-name))
        (kill-buffer welkomscherm/buffer-name)))))

(ert-deftest welkomscherm-test/opens-at-the-first-line ()
  "The dashboard is shown from its first line, not scrolled to the bottom.

Rendering ends with point at the end of the buffer, which used to leave
the freshly displayed window scrolled down to its last line."
  (save-window-excursion
    (unwind-protect
        (progn
          (welkomscherm)
          (with-current-buffer welkomscherm/buffer-name
            ;; Point is on the first line, and that line is the top title
            ;; (possibly indented, since centring is on by default).
            (should (= (point) (point-min)))
            (should (string-match-p
                     (regexp-quote (car welkomscherm/top-title-list))
                     (thing-at-point 'line t)))
            ;; The window showing it starts at the top of the buffer.
            (should (= (window-start (get-buffer-window))
                       (point-min)))))
      (when (buffer-live-p (get-buffer welkomscherm/buffer-name))
        (kill-buffer welkomscherm/buffer-name)))))

(ert-deftest welkomscherm-test/renders-twice-without-error ()
  "Rendering again simply replaces the previous buffer."
  (save-window-excursion
    (unwind-protect
        (progn
          (welkomscherm)
          (welkomscherm)
          (should (buffer-live-p (get-buffer welkomscherm/buffer-name))))
      (when (buffer-live-p (get-buffer welkomscherm/buffer-name))
        (kill-buffer welkomscherm/buffer-name)))))

(ert-deftest welkomscherm-test/render-hooks-run ()
  "The pre- and post-render hooks both run, in order."
  (let (calls)
    (save-window-excursion
      (unwind-protect
          (let ((welkomscherm/pre-render-hook
                 (list (lambda () (push 'pre calls))))
                (welkomscherm/post-render-hook
                 (list (lambda () (push 'post calls)))))
            (welkomscherm))
        (when (buffer-live-p (get-buffer welkomscherm/buffer-name))
          (kill-buffer welkomscherm/buffer-name))))
    (should (equal (nreverse calls) '(pre post)))))


;;; Major mode
(defun welkomscherm-test--in-dashboard (thunk)
  "Render the dashboard, then call THUNK with its buffer current."
  (save-window-excursion
    (unwind-protect
        (progn
          (welkomscherm)
          (with-current-buffer welkomscherm/buffer-name
            (funcall thunk)))
      (when (buffer-live-p (get-buffer welkomscherm/buffer-name))
        (kill-buffer welkomscherm/buffer-name)))))


(ert-deftest welkomscherm-test/tab-moves-to-the-first-button ()
  "Pressing `TAB' on the first line of a new buffer moves the point to the first button."
  (welkomscherm-test--in-dashboard
   (lambda ()
     (goto-char (point-min))
     (should-not (button-at (point)))
     (call-interactively (key-binding (kbd "TAB")))
     (should (= (point) (button-start (next-button (point-min))))))))

(ert-deftest welkomscherm-test/uses-the-major-mode ()
  "The dashboard buffer runs `welkomscherm-mode', a `special-mode'."
  (welkomscherm-test--in-dashboard
   (lambda ()
     (should (eq major-mode 'welkomscherm-mode))
     (should (derived-mode-p 'special-mode)))))

(ert-deftest welkomscherm-test/line-spacing-follows-the-option ()
  "The buffer uses `welkomscherm/line-spacing' as its `line-spacing'."
  (dolist (spacing '(4 0.5))
    (let ((welkomscherm/line-spacing spacing))
      (welkomscherm-test--in-dashboard
       (lambda () (should (equal line-spacing spacing)))))))

(ert-deftest welkomscherm-test/line-spacing-nil-keeps-the-default ()
  "With `welkomscherm/line-spacing' nil the buffer keeps the default."
  (let ((welkomscherm/line-spacing nil))
    (welkomscherm-test--in-dashboard
     (lambda () (should-not (local-variable-p 'line-spacing))))))

(ert-deftest welkomscherm-test/pre-render-hook-locals-survive ()
  "Buffer-local values set by the pre-render hook outlive the major mode."
  (let ((welkomscherm/pre-render-hook
         (list (lambda () (setq-local fill-column 42)))))
    (welkomscherm-test--in-dashboard
     (lambda () (should (= fill-column 42))))))

(provide 'welkomscherm-test)

;;; welkomscherm-test.el ends here
