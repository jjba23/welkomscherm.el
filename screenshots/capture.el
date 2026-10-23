;;; capture.el --- Dump welkomscherm's rendered screen as JSON -*- lexical-binding: t -*-

;; Renders the real welcome screen with `welkomscherm/render-to-screen' in a
;; batch Emacs, and writes the result -- text, styling runs and all -- to JSON,
;; so that a small renderer can turn it into a PNG/GIF that shows exactly what
;; the package draws.
;;
;;   emacs -Q --batch -L . -l screenshots/capture.el screenshots/out

;;; Code:

(require 'json)
(require 'recentf)   ; declares `recentf-list' as special before we set it

(add-to-list 'load-path (expand-file-name "."))
(require 'welkomscherm)

(defconst wsc--demo-dir
  (expand-file-name "files" temporary-file-directory)
  "Scratch directory whose files stand in for recent files.")

(defun wsc--make-demo-files ()
  "Create a few files so that the recent files section has something to show."
  (make-directory wsc--demo-dir t)
  (let ((files '("notes.org" "journal.org" "init.el" "todo.org" "README.md")))
    (mapcar (lambda (name)
              (let ((path (expand-file-name name wsc--demo-dir)))
                (unless (file-exists-p path) (write-region "" nil path))
                path))
            files)))

(defun wsc--demo-config ()
  "Return the list of options that shape the screen for the screenshots."
  (list
   :centered t
   :fill-column 76
   :top-title-list '("While any editor can save your files"
                     "only Emacs can save your soul !")
   :work-list '((("acme-webapp" . "~/Work/acme-webapp/")
                 ("handbook" . "~/Work/handbook/")))
   :bookmarks-list '((("notes" . "~/org/notes.org")
                      ("journal" . "~/org/journal.org")
                      ("dotfiles" . "~/Dev/dotfiles/"))
                     (("emacs config" . "~/Dev/dotfiles/init.el")
                      ("recipes" . "~/org/recipes.org")))
   :actions-list '((("*scratch*" . ignore)
                    ("*Messages*" . ignore)
                    ("new note" . ignore))
                   (("re-render me" . ignore)))))

(defun wsc--face-at (pos)
  "Return the styling name that POS is drawn with."
  (cond
   ((eq (get-text-property pos 'face) 'welkomscherm/muted-face) "muted")
   ((button-at pos) "button")
   ((eq (get-text-property pos 'face) 'link) "button")
   (t "default")))

(defun wsc--line-runs (beg end)
  "Return the runs of text between BEG and END as a list of plists.
Runs merge neighbouring characters that carry the same style, so a line
becomes a handful of (FACE . TEXT) pieces rather than one per character."
  (let (runs)
    (save-excursion
      (goto-char beg)
      (while (< (point) end)
        (let ((face (wsc--face-at (point)))
              (char (buffer-substring-no-properties (point) (1+ (point)))))
          (if (and runs (equal face (plist-get (car runs) :face)))
              (setcar runs (list :face face
                                 :text (concat (plist-get (car runs) :text)
                                               char)))
            (push (list :face face :text char) runs))
          (forward-char 1))))
    (nreverse runs)))

(defun wsc--dump-region ()
  "Return the current buffer's contents as a JSON-ready plist."
  (let (rows)
    (save-excursion
      (goto-char (point-min))
      (while (< (point) (point-max))
        (let* ((beg (point))
               (end (line-end-position))
               (line (buffer-substring-no-properties beg end)))
          (push (if (equal line "\f")
                    (list :type "rule")
                  (list :type "text" :runs (vconcat (wsc--line-runs beg end))))
                rows))
        (forward-line 1)))
    (list :cols fill-column :rows (vconcat (nreverse rows)))))

(defun wsc--render (options)
  "Render the screen with OPTIONS and return its JSON-ready description."
  (let ((welkomscherm/centered (plist-get options :centered))
        (fill-column (plist-get options :fill-column))
        (welkomscherm/top-title-list (plist-get options :top-title-list))
        (welkomscherm/work-list (plist-get options :work-list))
        (welkomscherm/bookmarks-list (plist-get options :bookmarks-list))
        (welkomscherm/actions-list (plist-get options :actions-list))
        (welkomscherm/show-init-time nil)
        (welkomscherm/show-system-details (plist-get options :system-details))
        (welkomscherm/show-recent-files (plist-get options :recent-files))
        (welkomscherm/use-separator (plist-get options :separator))
        (welkomscherm/separator ?─)
        (welkomscherm/separator-width nil))
    (setq recentf-list (wsc--make-demo-files))
    (with-temp-buffer
      (setq-local indent-tabs-mode nil)
      (welkomscherm/render-to-screen)
      (wsc--dump-region))))

(let* ((outdir (or (car (last command-line-args-left)) "."))
       (base (wsc--demo-config))
       (default (wsc--render base))
       (full (wsc--render (append base
                                  (list :separator t
                                        :system-details t
                                        :recent-files t)))))
  (make-directory outdir t)
  (write-region (json-serialize default) nil
                (expand-file-name "default.json" outdir))
  (write-region (json-serialize full) nil
                (expand-file-name "full.json" outdir))
  (princ (format "wrote %s and %s\n" (expand-file-name "default.json" outdir)
                 (expand-file-name "full.json" outdir))))

;;; capture.el ends here
