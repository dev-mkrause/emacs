;;; init.el --- My personal emacs config             -*- lexical-binding: t; -*-

;; Copyright (C) 2024  Marvin Krause

;; Author: Marvin Krause <public@mkrause.org>
;; Keywords: 

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
(require 'use-package)

(defvar elpaca-installer-version 0.7)
(defvar elpaca-directory (expand-file-name "elpaca/" user-emacs-directory))
(defvar elpaca-builds-directory (expand-file-name "builds/" elpaca-directory))
(defvar elpaca-repos-directory (expand-file-name "repos/" elpaca-directory))
(defvar elpaca-order '(elpaca :repo "https://github.com/progfolio/elpaca.git"
                              :ref nil :depth 1
                              :files (:defaults "elpaca-test.el" (:exclude "extensions"))
                              :build (:not elpaca--activate-package)))
(let* ((repo  (expand-file-name "elpaca/" elpaca-repos-directory))
       (build (expand-file-name "elpaca/" elpaca-builds-directory))
       (order (cdr elpaca-order))
       (default-directory repo))
  (add-to-list 'load-path (if (file-exists-p build) build repo))
  (unless (file-exists-p repo)
    (make-directory repo t)
    (when (< emacs-major-version 28) (require 'subr-x))
    (condition-case-unless-debug err
        (if-let ((buffer (pop-to-buffer-same-window "*elpaca-bootstrap*"))
                 ((zerop (apply #'call-process `("git" nil ,buffer t "clone"
                                                 ,@(when-let ((depth (plist-get order :depth)))
                                                     (list (format "--depth=%d" depth) "--no-single-branch"))
                                                 ,(plist-get order :repo) ,repo))))
                 ((zerop (call-process "git" nil buffer t "checkout"
                                       (or (plist-get order :ref) "--"))))
                 (emacs (concat invocation-directory invocation-name))
                 ((zerop (call-process emacs nil buffer nil "-Q" "-L" "." "--batch"
                                       "--eval" "(byte-recompile-directory \".\" 0 'force)")))
                 ((require 'elpaca))
                 ((elpaca-generate-autoloads "elpaca" repo)))
            (progn (message "%s" (buffer-string)) (kill-buffer buffer))
          (error "%s" (with-current-buffer buffer (buffer-string))))
      ((error) (warn "%s" err) (delete-directory repo 'recursive))))
  (unless (require 'elpaca-autoloads nil t)
    (require 'elpaca)
    (elpaca-generate-autoloads "elpaca" repo)
    (load "./elpaca-autoloads")))
(add-hook 'after-init-hook #'elpaca-process-queues)
(elpaca `(,@elpaca-order))

;; Install use-package support
(elpaca elpaca-use-package
  ;; Enable use-package :ensure support for Elpaca.
  (elpaca-use-package-mode))

(elpaca-wait)

(setq use-package-enable-imenu-support t)
(setq use-package-always-ensure t)

(use-package emacs :ensure nil
  :config
  (setq display-line-numbers-type t
	use-short-answers t
	ring-bell-function 'ignore
	vc-follow-symlinks t
	use-dialog-box nil
	enable-recursive-minibuffers t)

  (defvar --backup-directory (expand-file-name "backups" user-emacs-directory))
  (if (not (file-exists-p --backup-directory))
      (make-directory --backup-directory t))

  (setq backup-directory-alist `(("." . ,--backup-directory)))
  (setq make-backup-files t               ; backup of a file the first time it is saved.
	backup-by-copying t               ; don't clobber symlinks
	version-control t                 ; version numbers for backup files
	delete-old-versions t             ; delete excess backup files silently
	delete-by-moving-to-trash t
	kept-old-versions 6               ; oldest versions to keep when a new numbered backup is made (default: 2)
	kept-new-versions 9               ; newest versions to keep when a new numbered backup is made (default: 2)
	auto-save-default t               ; auto-save every buffer that visits a file
	)

  (recentf-mode)
  (pixel-scroll-precision-mode)
  (repeat-mode 1)
  (savehist-mode 1)
  (blink-cursor-mode -1)
  (auto-insert-mode))

(use-package minibuffer
  :ensure nil
  :config
  (setq  read-buffer-completion-ignore-case t
	 read-file-name-completion-ignore-case t
	 completion-ignore-case t
	 read-answer-short t))

(use-package tramp
  :ensure nil
  :config
  (add-to-list 'tramp-remote-path 'tramp-own-remote-path))

(defun sudo-find-file (file)
  "Open FILE as root."
  (interactive "FOpen file as root: ")
  (when (file-writable-p file)
    (user-error "File is user writeable, aborting sudo"))
  (find-file (if (file-remote-p file)
                 (concat "/" (file-remote-p file 'method) ":"
                         (file-remote-p file 'user) "@" (file-remote-p file 'host)
                         "|sudo:root@"
                         (file-remote-p file 'host) ":" (file-remote-p file 'localname))
               (concat "/sudo:root@localhost:" file))))

(defun sudo-this-file ()
  "Open the current file as root."
  (interactive)
  (sudo-find-file (file-truename buffer-file-name)))

(setq user-full-name "Marvin Krause")
(setq user-mail-address "public@mkrause.org")

(defun mk/package-install (package)
  (unless (package-installed-p package)
    (package-install package)))

(defmacro mk/keybind (keymap &rest definitions)
  "Expand key binding DEFINITIONS for the given KEYMAP.
DEFINITIONS is a sequence of string and command pairs."
  (declare (indent 1))
  (unless (zerop (% (length definitions) 2))
    (error "Uneven number of key+command pairs"))
  (let ((keys (seq-filter #'stringp definitions))
        ;; We do accept nil as a definition: it unsets the given key.
        (commands (seq-remove #'stringp definitions)))
    `(when-let (((keymapp ,keymap))
                (map ,keymap))
       ,@(mapcar
          (lambda (pair)
            (let* ((key (car pair))
                   (command (cdr pair)))
              (unless (and (null key) (null command))
                `(define-key map (kbd ,key) ,command))))
          (cl-mapcar #'cons keys commands)))))

(setq use-package-always-ensure t)

(setq custom-file (expand-file-name "custom.el" user-emacs-directory))
(add-to-list 'load-path (expand-file-name "lisp" user-emacs-directory))

(use-package restart-emacs)

(use-package which-key
  :config (which-key-mode))

(use-package epg
  :ensure nil
  :config
  (setq epa-file-name-regexp "\\.\\(gpg\\|\\asc\\)\\(~\\|\\.~[0-9]+~\\)?\\'")
  (epa-file-name-regexp-update))

(use-package dictionary
  :ensure nil
  :config
  (setq dictionary-server "dict.org"))

;;;;;;;;;;;;;;;;;;
;; UI and Theme ;;
;;;;;;;;;;;;;;;;;;
(load (expand-file-name "lisp/setup-ui.el" user-emacs-directory))

;;;;;;;;;;;;;;;;;;
;; Coding & IDE ;;
;;;;;;;;;;;;;;;;;;
(load (expand-file-name "lisp/setup-ide" user-emacs-directory))

;;;;;;;;;;;;;;;;;;;;;;;
;; Completion system ;;
;;;;;;;;;;;;;;;;;;;;;;;
(load (expand-file-name "lisp/setup-completion" user-emacs-directory))

;;;;;;;;;;;;;;
;; Personal ;;
;;;;;;;;;;;;;;
(load (expand-file-name "lisp/setup-personal" user-emacs-directory))

;;;;;;;;;;;
;; Dired ;;
;;;;;;;;;;;
(load (expand-file-name "lisp/setup-dired" user-emacs-directory))

;;;;;;;;;;;;;;
;; Org Mode ;;
;;;;;;;;;;;;;;
(load (expand-file-name "lisp/setup-org" user-emacs-directory))

;;;;;;;;;;;;;;;;;;
;; Zettelkasten ;;
;;;;;;;;;;;;;;;;;;
(load (expand-file-name "lisp/setup-zettelkasten" user-emacs-directory))

;;;;;;;;;;;;
;; Extras ;;
;;;;;;;;;;;;
(use-package 0x0)

;;;;;;;;;;;;;
;; Keymaps ;;
;;;;;;;;;;;;;
(defvar-keymap mk/prefix-zettelkasten-map
  :doc "Prefix map for zettelkasten."
  :name "Zettelkasten"
  "d"     #'denote
  "f"     #'denote-open-or-create
  "i"     #'denote-link
  "o"     #'denote-find-link
  "O"     #'citar-open
  "z"     #'mk/dired-zettelkasten
  "b"     #'denote-find-backlink
  "a"     #'denote-keywords-add
  "A"     #'denote-keywords-remove
  "c"     #'citar-create-note
  "k"     #'citar-denote-add-citekey
  "K"     #'citar-denote-remove-citekey)

(defvar-keymap mk/prefix-organization-map
  :doc "Prefix map for organization stuff."
  :name "Organization"
  "c"    #'mk/org-classify)

(defvar-keymap mk/prefix-open-map
  :doc "Prefix map for opening my stuff."
  :name "Open"
  "t" #'eat
  "e" #'eshell)

(defvar-keymap mk/prefix-notes-map
  :doc "Prefix keymap for notes and organization."
  :name "Notes"
  "a" #'org-agenda
  "n" #'org-capture
  "d" mk/prefix-zettelkasten-map
  "o" mk/prefix-organization-map)

(defvar-keymap mk/prefix-search-map
  :doc "Prefix map for search functions."
  :name "Search"
  "s" #'consult-line
  "o" #'occur
  "d" #'consult-fd
  "D" #'dictionary-search
  "r" #'consult-ripgrep)

(defvar-keymap mk/prefix-quit-map
  :doc "Prefix keymap for quitting and restarting."
  :name "Quit"
  "r" #'restart-emacs
  "R" #'restart-emacs-start-new-emacs
  "f" #'delete-frame)

(defvar-keymap mk/prefix-files-map
  :doc "Prefix keymap for files."
  :name "Files"
  "r" #'recentf
  "u" #'sudo-find-file
  "U" #'sudo-this-file)

(mk/keybind global-map
  "C-z" nil ;; Remove suspend frame
  "C-x C-z" nil
  "C-c f" mk/prefix-files-map
  "C-c n" mk/prefix-notes-map
  "C-c s" mk/prefix-search-map
  "C-c o" mk/prefix-open-map
  "C-c q" mk/prefix-quit-map)

;;; init.el ends here
