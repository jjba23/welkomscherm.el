;;; welkomscherm-checkdoc.el --- Fail when checkdoc reports findings -*- lexical-binding: t -*-

;; Copyright © Josep Bigorra <jjbigorra@gmail.com>

;; SPDX-License-Identifier: MIT

;;; Commentary:

;; Run by maak's `lint' task, from the project root:
;;
;;   emacs -Q --batch -l test/welkomscherm-checkdoc.el
;;
;; Plain `checkdoc-file' only *reports* findings and always exits 0, so
;; the gate would never bite.  Here we count findings ourselves and exit
;; non-zero when there is at least one, turning checkdoc into a real
;; quality gate.  The warnings are still printed, through the original
;; reporting function.

;;; Code:

(require 'checkdoc)

(let ((count 0)
      (original checkdoc-create-error-function))
  (setq checkdoc-create-error-function
        (lambda (text start end &optional unfixable)
          (setq count (1+ count))
          (funcall original text start end unfixable)))
  (checkdoc-file (symbol-name 'welkomscherm.el))
  (if (> count 0)
      (progn
        (message "checkdoc: %d finding(s) in welkomscherm.el" count)
        (kill-emacs 1))
    (message "checkdoc: clean")))

;;; welkomscherm-checkdoc.el ends here
