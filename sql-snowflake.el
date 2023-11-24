;;; sql-snowflake.el --- Snowflake support for sql.el  -*- lexical-binding: t; -*-

;; Copyright (C) 2023  Elliott Shugerman

;; Author: Elliott Shugerman <eeshugerman@gmail.com>
;; Keywords: data, tools

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; 

;;; Code:


(require 'sql)
(require 'seq)

(defcustom sql-snowflake-program "snowsql"
  "Command to start snowsql by Snowflake."
  :type 'file
  :group 'SQL)

(defcustom sql-snowflake-login-params '(user password server database account warehouse)
  "Login parameters to needed to connect to Snowflake."
  :type 'sql-login-params
  :group 'SQL)

(defcustom sql-snowflake-options
  '("--option" "auto_completion=false"
    "--option" "friendly=false"
    "--option" "progress_bar=false"
    "--option" "wrap=true")
  "List of additional options for `sql-snowflake-program'."
  :type '(repeat string)
  :group 'SQL)


(defun sql-snowflake--build-nullable-cli-params (spec)
  (seq-reduce
   (lambda (acc pair)
     (let ((flag (car pair))
           (val (eval (cdr pair))))
       (if (string= "" val)
           acc
         (cons flag (cons val acc)))))
   spec
   '()))

(defun sql-comint-snowflake (product options &optional buf-name)
  "Connect to Snowflake in a comint buffer."
  (let ((params (append (sql-snowflake--build-nullable-cli-params
                         '(("--username" . sql-user)
                           ("--dbname" . sql-database)
                           ("--host" . sql-server)
                           ("--accountname" . sql-account)
                           ("--warehouse" . sql-warehouse)))
                        options)))
    (with-environment-variables (("SNOWSQL_PWD" sql-password))
      (sql-comint product params buf-name))))

(sql-add-product 'snowflake "Snowflake"
                 :free-software nil
                 :sqli-program 'sql-snowflake-program
                 :prompt-regexp (rx line-start (zero-or-more not-newline) ">")
                 :sqli-login 'sql-snowflake-login-params
                 :sqli-options 'sql-snowflake-options
                 :sqli-comint-func #'sql-comint-snowflake)

(defun sql-snowflake--strip-junk (output-string)
  (thread-last output-string
               (replace-regexp-in-string (rx (= 7 "\r\n")) "")
               (replace-regexp-in-string (rx (= 80 space) "\r\r") "")))
(add-hook 'sql-interactive-mode-hook
          (lambda ()
            (when (eq sql-product 'snowflake)
              (add-hook 'comint-preoutput-filter-functions
                        #'sql-snowflake--strip-junk
                        ;; make it buffer-local
                        nil t))))

(provide 'sql-snowflake)
;;; sql-snowflake.el ends here
