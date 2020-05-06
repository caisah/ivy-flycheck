;;; ivy-flycheck.el --- Jump to `flycheck' errors using `ivy'-*- lexical-binding: t; -*-

;; Copyright (C) 2020 Vlad Piersec

;; Author: Vlad Piersec <vlad.piersec@protonmail.com>
;; URL: https://github.com/caisah/ivy-flycheck
;; Version: 0.1.0
;; Package-Requires: ((emacs "24.5"))
;; Keywords: flycheck, ivy, errors

;; This file is not part of GNU Emacs.

;;; Commentary:

;;;; Installation

;;;;; Manual

;; Install these required packages:

;; + flycheck
;; + ivy

;; Then put this file in your load-path, and put this in your init
;; file:

;;  (eval-after-load 'flycheck
;;    '(define-key flycheck-mode-map (kbd "C-c ! o") 'ivy-flycheck))

;;;; Usage

;; Run:

;; `ivy-flyecheck'

;;;; Tips

;; You can customize the delimiter in the `ivy-flycheck' group.

;; You can also cusomize some faces: `column-number', `error-type', `warning-type',
;; `info-type' and `text'.

;;;; Credits

;; This package would not have been possible without the following
;; packages: flycheck[1], and ivy[2].
;;
;;  [1] https://github.com/flycheck/flycheck
;;  [2] https://github.com/abo-abo/swiper

;;; License:

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Code:

;;;; Requirements

(require 'ivy)
(require 'flycheck)

(defgroup ivy-flycheck nil
  "Settings for `ivy-flycheck'."
  :link '(url-link "https://github.com/caisah/ivy-flycheck"))

(defgroup ivy-flycheck-faces nil
  "Font-lock faces for `ivy-flyecheck'."
  :group 'faces
  :prefix "ivy-flycheck-")

(defface ivy-flycheck-line-column-number
  '((t :inherit flycheck-error-list-column-number))
  "Face used by ivy-flyecheck for highlighting the line and the column number of the flycheck message")

(defface ivy-flycheck-error-type
  '((t :inherit flycheck-error-list-error))
  "Face used by ivy-flyecheck for highlighting the \"error\" keyword")

(defface ivy-flycheck-warning-type
  '((t :inherit flycheck-error-list-warning))
  "Face used by ivy-flyecheck for highlighting the \"warning\" keyword")

(defface ivy-flycheck-info-type
  '((t :inherit flycheck-error-list-info))
  "Face used by ivy-flyecheck for highlighting the \"info\" keyword")

(defface ivy-flycheck-text
  '((t :inherit default))
  "Face used by ivy-flyecheck for highlighting the message text")

(defcustom ivy-flycheck-delimiter "\n"
  "The text delimiter between ivy candidates."
  :group 'ivy-flycheck
  :type 'string)

(defconst ivy-flycheck--level-asoc '((warning . ivy-flycheck-warning-type)
                                 (error . ivy-flycheck-error-type)
                                 (info . ivy-flyecheck-info-type)))

(defun ivy-flycheck--colorized-type (err)
  "Colorize the ERR flycheck error type accordingly."
  (let ((level (flycheck-error-level err)))
    (ivy--add-face (symbol-name level) (cdr (assoc level ivy-flycheck--level-asoc)))))

(defun ivy-flycheck--colorized-line-column (line col)
  "Colorize the LINE and COL accordingly."
  (ivy--add-face (concat
                  (number-to-string line) ":"
                  (number-to-string col) " ")
                 'ivy-flycheck-line-column-number))

(defun ivy-flycheck--colorized-message (err)
  "Colorize the ERR flyecheck message accordingly."
  (ivy--add-face (flycheck-error-message err) 'ivy-flycheck-text))

(defun ivy-flycheck--safe-line (line)
  "Return a valid buffer line number from LINE."
  (cond ((eq line 0) 1)
        ((null line) 1)
      (t line)))

(defun ivy-flycheck--safe-column (column)
  "Return a valid buffer column number from COLUMN."
  (or column 0))

(defun ivy-flycheck--format-error (err)
  "Formats the ERR flycheck-error into one CAND entry.

Each entry is a cons of the colored text."
  (let ((line (ivy-flycheck--safe-line (flycheck-error-line err)))
        (col (ivy-flycheck--safe-column (flycheck-error-column err))))
    (cons (concat (ivy-flycheck--colorized-type err)
                  " "
                  (ivy-flycheck--colorized-line-column line col)
                  (ivy-flycheck--colorized-message err)
                  ivy-flycheck-delimiter)
          err)))

(defun ivy-flycheck-format-flycheck-errors ()
  "Maps a list of `flycheck' errors to an `ivy-read' CANDS list."
  (when flycheck-current-errors
      (cl-mapcar 'ivy-flycheck--format-error flycheck-current-errors)))

(defun ivy-flycheck-action (entry)
  "Jumps to the error from ENTRY."
  (when (listp entry)
    (let ((err (cdr entry)))
      (flycheck-jump-to-error err))))

;;;###autoload
(defun ivy-flycheck ()
  "Display flycheck errors using `ivy' interface."
  (interactive)
  (ivy-read "Go to:" (ivy-flycheck-format-flycheck-errors)
                 :action 'ivy-flycheck-action
                 :caller 'ivy-flycheck))

;;; ivy-flycheck.el ends here
