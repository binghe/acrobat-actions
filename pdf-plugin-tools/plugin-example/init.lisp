;;; -*- Mode: LISP; Syntax: COMMON-LISP; Package: PLUGIN-EXAMPLE; Base: 10 -*-

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

(in-package :plugin-example)

;; configure PDF-PLUGIN-TOOLS for this particular plug-in
(setq *plugin-id* "LXmp"
      *plugin-name* "PDFLisp"
      #+:macosx #+:macosx
      *plugin-bundle-identifier* "com.github.binghe.PDFLisp"
      *plugin-help-text* "An example plug-in created with PDF-PLUGIN-TOOLS."
      ;; see ASDF system definition
      *plugin-version* cl-user:*plugin-example-version*
      *company-name* "Chun Tian"
      *product-name* "PDFLisp Demo"
      *copyright-message* "Copyright (c) 2022, Chun Tian.  All rights reserved."
      ;; we want a backtrace if something goes wrong
      *log-backtraces-p* t)
