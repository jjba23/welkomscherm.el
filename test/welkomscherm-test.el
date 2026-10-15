;;; welkomscherm-test.el --- ERT tests for welkomscherm -*- lexical-binding: t -*-

;; Copyright © Josep Bigorra <jjbigorra@gmail.com>

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

;; ERT suite for welkomscherm.el.  It checks three things: that the
;; package loads without any external library, that every rendering
;; primitive writes what it promises, and that the optional system
;; details and recent files sections stay off until they are asked for.
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

(ert-deftest welkomscherm-test/page-break-lines-is-optional ()
  "The package does not force an external library on its users."
  (let ((source (with-temp-buffer
                  (insert-file-contents welkomscherm-test--source)
                  (buffer-string))))
    (should (string-match-p "(require 'page-break-lines nil t)" source))
    (should-not (string-match-p "Package-Requires:.*page-break-lines" source))))

(ert-deftest welkomscherm-test/buffer-name-default ()
  "The default buffer name is the documented one."
  (should (equal welkomscherm/buffer-name "*welkomscherm*")))

(ert-deftest welkomscherm-test/default-sections-include-new-sections ()
  "The default section list includes the two new opt-in sections."
  (should (member welkomscherm/system-details welkomscherm/sections))
  (should (member welkomscherm/recent-files-section welkomscherm/sections))
  (should (cl-every #'functionp welkomscherm/sections)))

(ert-deftest welkomscherm-test/new-sections-are-opt-in ()
  "Both new sections default to off."
  (should-not welkomscherm/show-system-details)
  (should-not welkomscherm/show-recent-files))


;;; Rendering primitives

(ert-deftest welkomscherm-test/insert-new-line ()
  "`welkomscherm/insert-new-line' inserts a single newline."
  (with-temp-buffer
    (welkomscherm/insert-new-line)
    (should (equal (buffer-string) "\n"))))

(ert-deftest welkomscherm-test/insert-form-feed ()
  "`welkomscherm/insert-form-feed' inserts a form feed character."
  (with-temp-buffer
    (welkomscherm/insert-form-feed)
    (should (equal (buffer-string) "\f"))))

(ert-deftest welkomscherm-test/insert-spacer ()
  "`welkomscherm/insert-spacer' inserts two spaces."
  (with-temp-buffer
    (welkomscherm/insert-spacer)
    (should (equal (buffer-string) "  "))))

(ert-deftest welkomscherm-test/insert-muted-adds-face ()
  "`welkomscherm/insert-muted' inserts text carrying the muted face."
  (with-temp-buffer
    (let ((welkomscherm/centered nil))
      (welkomscherm/insert-muted "hello"))
    (should (equal (buffer-string) "hello"))
    (should (eq (get-text-property (point-min) 'face)
                'welkomscherm/muted-face))))

(ert-deftest welkomscherm-test/maybe-form-feed-respects-option ()
  "Form feeds are only inserted when the option is enabled."
  (with-temp-buffer
    (let ((welkomscherm/use-form-feed nil))
      (welkomscherm/maybe-form-feed))
    (should (equal (buffer-string) ""))
    (let ((welkomscherm/use-form-feed t))
      (welkomscherm/maybe-form-feed))
    (should (equal (buffer-string) "\f"))))

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
  (with-temp-buffer
    (let ((welkomscherm/centered nil)
          (welkomscherm/show-system-details nil))
      (funcall welkomscherm/system-details))
    (should (= (buffer-size) 0))))

(ert-deftest welkomscherm-test/system-details-section-on ()
  "The system details section renders values when enabled."
  (with-temp-buffer
    (let ((welkomscherm/centered nil)
          (welkomscherm/show-system-details t))
      (funcall welkomscherm/system-details))
    (should (string-match-p "Emacs: " (buffer-string)))
    (should (string-match-p (regexp-quote (welkomscherm/system-emacs-version))
                            (buffer-string)))))


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
        (let ((recentf-list (list file)))
          (with-temp-buffer
            (let ((welkomscherm/centered nil)
                  (welkomscherm/show-recent-files nil))
              (funcall welkomscherm/recent-files-section))
            (should (= (buffer-size) 0))))
      (delete-file file))))

(ert-deftest welkomscherm-test/recent-files-section-on ()
  "The recent files section renders the recent files when enabled."
  (let ((file (make-temp-file "welkomscherm-recent")))
    (unwind-protect
        (let ((recentf-list (list file)))
          (with-temp-buffer
            (let ((welkomscherm/centered nil)
                  (welkomscherm/show-recent-files t))
              (funcall welkomscherm/recent-files-section))
            (should (string-match-p
                     (regexp-quote (file-name-nondirectory file))
                     (buffer-string)))
            (should (next-button (point-min)))))
      (delete-file file))))


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

(provide 'welkomscherm-test)

;;; welkomscherm-test.el ends here
