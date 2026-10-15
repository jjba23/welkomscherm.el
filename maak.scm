;; welkomscherm.el

;; Copyright © Josep Bigorra <jjbigorra@gmail.com>

;; welkomscherm.el is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; welkomscherm.el is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with welkomscherm.el.  If not, see <https://www.gnu.org/licenses/>.

(define-module (maak)
  #:declarative? #t
  #:use-module (maak maak))

;; ====== Maak constants ======

;; The Emacs the package is compiled and tested with, overridable with the
;; EMACS environment variable, exactly as one would expect.
(define emacs-command
  (or (getenv "EMACS") "emacs"))

;; The package itself.
(define source-file
  "welkomscherm.el")

;; The ERT suite.
(define test-file
  "test/welkomscherm-test.el")

;; What byte-compilation leaves behind.
(define compiled-files
  '("welkomscherm.elc" "test/welkomscherm-test.elc"))

;; ====== Maak tasks ======

(define (compile)
  "Byte-compile the package and its test suite."
  ($ (list emacs-command "-Q" "--batch" "-L" "." "-L" "test"
           "-f" "batch-byte-compile" source-file test-file)))

(define (test)
  "Run the ERT suite."
  ($ (list emacs-command "-Q" "--batch" "-L" "." "-L" "test" "-l" test-file
           "-f" "ert-run-tests-batch-and-exit")))

(define (lint)
  "Compile with warnings turned into errors, then enforce checkdoc."
  ($ (list emacs-command "-Q" "--batch" "-L" "." "-L" "test"
           "--eval" "'(setq byte-compile-error-on-warn t)'"
           "-f" "batch-byte-compile" source-file test-file))
  ($ (list emacs-command "-Q" "--batch" "-L" "."
           "-l" "test/welkomscherm-checkdoc.el")))

(define (clean)
  "Remove the byte-compiled files."
  (for-each (lambda (file)
              (when (file-exists? file) (delete-file file)))
            compiled-files))

(define (check)
  "The whole quality gate, from a clean tree: lint, then test."
  (clean)
  (lint)
  (test))

(define (repl)
  "Open an Emacs with the package loaded for hacking."
  ($ (list emacs-command "-Q" "-L" "."
           "--eval" "'(progn (require (quote welkomscherm)) (welkomscherm))'")))

(define (tasks)
  "List the available tasks."
  ($ '("maak --list")))

;; `maak' on its own runs `check', that is: the whole gate in one command.
(define (default)
  "Run the full quality gate (lint and tests)."
  (check))

;; Local Variables:
;; mode: scheme
;; End:
