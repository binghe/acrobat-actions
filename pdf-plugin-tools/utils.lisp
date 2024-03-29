;;; -*- Mode: LISP; Syntax: COMMON-LISP; Package: PDF-PLUGIN-TOOLS; Base: 10 -*-

;;; Copyright (c) 2022, Chun Tian (binghe).  All rights reserved.

;;; Redistribution and use in source and binary forms, with or without
;;; modification, are permitted provided that the following conditions
;;; are met:

;;;   * Redistributions of source code must retain the above copyright
;;;     notice, this list of conditions and the following disclaimer.

;;;   * Redistributions in binary form must reproduce the above
;;;     copyright notice, this list of conditions and the following
;;;     disclaimer in the documentation and/or other materials
;;;     provided with the distribution.

;;; THIS SOFTWARE IS PROVIDED BY THE AUTHOR 'AS IS' AND ANY EXPRESSED
;;; OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
;;; WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
;;; ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY
;;; DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
;;; DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE
;;; GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
;;; INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
;;; WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
;;; NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
;;; SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

(in-package :pdf-plugin-tools)

(defun check-plugin-id ()
  "Checks whether *PLUGIN-ID* has a valid value.  Should be called in
delivery script."
  (unless (and (stringp *plugin-id*)
               (= 4 (length *plugin-id*))
               (every (lambda (char)
                        (or (char-not-greaterp #\A char #\Z)
                            (char<= #\0 char #\9)))
                      *plugin-id*))
    (error "Plug-in ID must be a string of four characters each of ~
which is a letter or a digit.")))

(defparameter *plugin-log-template*
  "[~D-~2,'0D-~2,'0DT~2,'0D:~2,'0D:~2,'0D] ")

(defun plugin-log (control-string &rest format-args)
  "Utility function which might be useful for debugging a plug-in.
Writes data to the file denoted by *FM-LOGFILE* unless this value
is NIL.  CONTROL-STRING and FORMAT-ARGS are interpreted as by
FORMAT."
  (declare (type string control-string))
  (when *plugin-logfile*
    (let ((logfile (if (eq *plugin-logfile* t)
                       (merge-pathnames "Adobe/Acrobat/pdf-plugin-tools.log"
                                        (sys:get-folder-path #-:macosx :local-appdata
                                                             #+:macosx :my-appsupport))
                     *plugin-logfile*)))
      (with-open-file (out (ensure-directories-exist logfile)
                           :direction :output
                           :element-type 'lw:simple-char
                           :external-format '(:utf-8 :eol-style :lf)
                           :if-exists :append
                           :if-does-not-exist :create)
        (multiple-value-bind (second minute hour date month year day-of-week
                                     daylight-saving-time-p time-zone)
            (decode-universal-time (get-universal-time))
          (declare (ignore day-of-week daylight-saving-time-p time-zone))
          (apply #'format out
                 (concatenate 'string *plugin-log-template* control-string)
                 year month date hour minute second
                 format-args)
          (finish-output out)))))
  (values))

(defun get-backtrace ()
  "Returns a full backtrace as a string.  To be used in handlers."
  (with-output-to-string (out nil :element-type 'lw:simple-char)
    (let ((dbg::*debugger-stack* (dbg::grab-stack nil :how-many most-positive-fixnum))
          (*debug-io* out)
          (dbg:*debug-print-level* nil)
          (dbg:*debug-print-length* nil))
      (dbg:bug-backtrace nil))))

(defun maybe-log-error (condition &optional function)
  "Logs the condition CONDITION using PLUGIN-LOG if *LOG-ERRORS* is true.
Also logs a backtrace if *LOG-BACKTRACES-P* is true as well."
  (when *log-errors-p*
    (plugin-log "Error~:[ in function ~A~]: ~A~%" function condition)
    (when *log-backtraces-p*
      (plugin-log "Backtrace:~% ~A~%" (get-backtrace)))))

(defun boolean-value (thing)
  "Returns T if THING is not NIL, NIL otherwise."
  (not (not thing)))

(defun set-product-name ()
  "Sets *PRODUCT-NAME* from *PLUGIN-NAME* if it hasn't been set
explicitly."
  (unless *product-name*
    (setq *product-name* *plugin-name*))
  *product-name*)

(defun version-string ()
  "Returns a string representation of the plug-in version."
  (format nil "~{~A~^.~}" *plugin-version*))

(defun convert-line-endings (string)
  "Converts Mac line endings \(carriage returns, used internally
by FileMaker) to line feeds."
  (with-output-to-string (out nil :element-type 'lw:simple-char)
    (loop for char across string
          do (write-char (case char
                           (#.#\Return #\Linefeed)
                           (otherwise char))
                         out))))

(defmacro define-acrobat-function ((name c-name) ver-name version proto hft sel)
  ;; use a gensym for POINTER-NAME that has some resemblance to C-NAME
  (let ((pointer-name (gensym c-name)))
    `(defmacro ,name (&rest args)
       `(cond ((>= ,',ver-name ,',version)
               (fli:with-coerced-pointer (,',pointer-name :type 'hft-entry) ,',hft
                 (fli:incf-pointer ,',pointer-name ,',sel)
                 (,',proto (fli:dereference ,',pointer-name) ,@args)))
              (t
               (error "not implemented"))))))

;; help the LispWorks IDE to find these definitions
(define-form-parser define-acrobat-function (name)
  `(,define-acrobat-function ,(first name)))

(define-dspec-alias define-acrobat-function (name)
  `(defun ,name))

;; setup correct indentation of DEFINE-ACROBAT-FUNCTION
(editor:setup-indent "define-acrobat-function" 2 2 4)

;; This is learnt from CXML web site
(defun write-xml (node &key indent)
  (let ((sink (cxml:make-string-sink
               :canonical nil :indentation indent)))
    (cxml-xmls:map-node sink node :include-namespace-uri nil)))

(defmacro and-plusp (pi-var)
  (let ((var (gensym)))
    `(let ((,var ,pi-var))
       (and ,var (plusp ,var)))))

;; NOTE: this is learnt from CFFI. To make it work, it requires that
;; DEFINE-FOREIGN-CALLABLE takes a symbol (instead of a string) for the
;; foreign function name and pass (:ENCODE :LISP).
#+:lispworks6
(defun foreign-function-pointer (symbol)
  (make-pointer :symbol-name symbol :module :callbacks))
