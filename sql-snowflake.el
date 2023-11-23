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


(defun sql-comint-snowflake (product options &optional buf-name)
  "Connect to Snowflake in a comint buffer."
  (let ((params (append
                 (if (not (string= "" sql-user))
                     (list "--username" sql-user))
                 (if (not (string= "" sql-database))
                     (list "--dbname" sql-database))
                 (if (not (string= "" sql-server))
                     (list "--host" sql-server))
                 (if (not (string= "" sql-account))
                     (list "--accountname" sql-account))
                 (if (and (boundp 'sql-warehouse) (not (string= "" sql-warehouse)))
                     (list "--warehouse" sql-warehouse))
                 options)))
    (with-environment-variables (("SNOWSQL_PWD" sql-password))
      (sql-comint product params buf-name))))

(sql-add-product 'snowflake "Snowflake"
                 :free-software nil
                 :sqli-program 'sql-snowflake-program
                 :prompt-regexp (rx line-start (zero-or-more not-newline) ">")
                 :sqli-login 'sql-snowflake-login-params
                 :sqli-options 'sql-snowflake-options
                 :sqli-comint-func #'sql-comint-snowflake
                 )

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


;; 2) Define font lock settings.  All ANSI keywords will be
;;    highlighted automatically, so only product specific keywords
;;    need to be defined here.
;; (defvar sql-mode-snowflake-font-lock-keywords
;;   '(("\\b\\(red\\|orange\\|yellow\\)\\b" . font-lock-keyword-face))
;;   "Snowflake SQL keywords used by font-lock.")
;; (sql-set-product-feature 'snowflake :font-lock 'sql-mode-snowflake-font-lock-keywords)

;; ;; 3) Define any special syntax characters including comments and
;; ;;    identifier characters.
;; (sql-set-product-feature 'snowflake
;;                          :syntax-alist ((?# . "_")))

(provide 'sql-snowflake)
;;; sql-snowflake.el ends here
