;;; rails-test-toggler.el -- Flip between test and implementation in a rails project

;; Copyright (C) 2011 Matt Briggs
;;
;; Author: Matt Briggs <matt@mattbriggs.net>
;; URL: http://github.com/mbriggs/rails-test-toggler
;; Version: 0.2
;; Keywords: rails

;; This file is not part of GNU Emacs.

;;; Commentary:

;; Provides a way to quickly toggle between test and implementation

;;; Installation:

;; Put rails-test-toggler.el somewhere in your load path, and

;; (require 'rails-test-toggler)

;; in your init.el. To toggle between test and implementation, bind
;; rtt/toggle-test-and-implementation to something.

;;; License:

;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License
;; as published by the Free Software Foundation; either version 3
;; of the License, or (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301, USA.

;; Code

(defun rtt/toggle-test-and-implementation ()
  (interactive)
  (let ((file (buffer-file-name)))
    (if (rtt/test? file)
        (rtt/find-test-by-target-type file)
      (rtt/find-target-by-test-type file))))

(defun rtt/find-test-by-target-type (test-file)
  (if (rtt/rspec? test-file) (rtt/find-spec-target test-file)
    (cond ((rtt/helper-test? test-file) (rtt/find-helper-test test-file))
          ((rtt/unit-test? test-file) (rtt/find-unit-test test-file))
          ((rtt/functional-test? test-file) (rtt/find-functional-test test-file)))))

(defun rtt/find-target-by-test-type (test-file)
  (or (rtt/find-spec test-file)
      (cond ((rtt/helper? test-file) (rtt/find-helper test-file))
            ((rtt/model? test-file) (rtt/find-model test-file))
            ((rtt/controller? test-file) (rtt/find-controller test-file))
            ((rtt/app? test-file) (rtt/find-generic test-file)))))



;; Predicates

(defun rtt/test? (file)
  (string-match "/\\(test\\|spec\\)/" file))

(defun rtt/rspec? (file)
  (string-match "/spec" file))

(defun rtt/model? (file)
  (or
   (string-match "/app/models" file)
   (string-match "/lib/" file)))

(defun rtt/app? (file)
  (string-match "/app" file))

(defun rtt/helper? (file)
  (string-match "/app/helpers" file))

(defun rtt/javascript? (file)
  (string-match "javascripts" file))

(defun rtt/controller? (file)
  (string-match "/app/controllers" file))

(defun rtt/unit-test? (file)
  (string-match "/test/unit" file))

(defun rtt/helper-test? (file)
  (string-match "/test/unit/helpers" file))

(defun rtt/functional-test? (file)
  (string-match "/test/functional" file))


;; rspec

(defun rtt/find-spec (file)
  (let* ((path (replace-regexp-in-string "app/\\(assets/\\)?" "spec/" file))
         (rb (replace-regexp-in-string ".rb$" "_spec.rb" path))
         (spec (replace-regexp-in-string ".js$" "_spec.js" rb)))
    (if (file-exists-p spec)
        (find-file spec))))

(defun rtt/find-spec-target (file)
  (let* ((path (replace-regexp-in-string "spec/" "app/" file))
         (name (replace-regexp-in-string "_spec" "" path))
         (target (if (rtt/javascript? name) (replace-regexp-in-string "app/" "app/assets/" name) name)))
    (if (file-exists-p target)
        (find-file target))))

;; Test::Unit Finders

(defun rtt/find-controller (file)
  (rtt/find-target "app/controllers" "functional" file))

(defun rtt/find-helper (file)
  (rtt/find-target "app/helpers" "unit/helpers" file))

(defun rtt/find-model (file)
  (or
   (rtt/find-target "app/models" "unit" file)
   (rtt/find-target "lib" "unit" file)))

(defun rtt/find-generic (file)
  (rtt/find-target "app" "unit" file))

(defun rtt/find-functional-test (test-file)
  (rtt/find-test "functional" "app/controllers" test-file))

(defun rtt/find-helper-test (test-file)
  (rtt/find-test "unit/helpers" "app/helpers" test-file))

(defun rtt/find-unit-test (test-file)
  (or
   (rtt/find-test "unit" "app/models" test-file)
   (rtt/find-test "unit" "lib" test-file)
   (rtt/find-test "unit" "app" test-file)))


;; Test::Unit Helpers

(defun rtt/find-test (test-re rails-dir test-file)
  (let ((path (rtt/test-file test-re rails-dir test-file)))
    (if (file-exists-p path)
        (find-file path))))

(defun rtt/find-target (rails-dir-re test-dir file)
  (let ((path (rtt/target-file rails-dir-re test-dir file)))
    (if (file-exists-p path)
        (find-file path))))

(defun rtt/test-file (test-re rails-dir test-file)
  (replace-regexp-in-string (concat "test\\/" test-re)
                            rails-dir
                            (rtt/drop-test-extension test-file)))

(defun rtt/target-file (rails-dir-re test-dir file)
  (replace-regexp-in-string rails-dir-re
                            (concat "test/" test-dir)
                            (rtt/add-test-extension file)))

(defun rtt/drop-test-extension (file)
  (replace-regexp-in-string "_test" "" file))

(defun rtt/add-test-extension (file)
  (replace-regexp-in-string "\\.rb" "_test.rb" file))

(provide 'rails-test-toggler)
