;;; setup-ide.el --- IDE functionality and programming setup  -*- lexical-binding: t; -*-

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

(use-package transient)
(use-package magit
  :after transient)

(use-package flymake
  :ensure nil
  :config
  (setq flymake-fringe-indicator-position 'right-fringe)
  (mk/keybind flymake-mode-map
    "M-n" #'flymake-goto-next-error
    "M-p" #'flymake-goto-prev-error
    "C-c ! p" #'flymake-show-project-diagnostics
    "C-c ! !" #'flymake-show-buffer-diagnostics)0
  (add-hook 'prog-mode-hook #'flymake-mode)
  (add-hook 'text-mode #'flymake-mode))

(use-package compile
  :ensure nil
  :config
  (mk/keybind prog-mode-map
    "<f11>" #'compile
    "<f12>" #'recompile))

(use-package eglot
  :ensure nil
  :config
  (setq eglot-autoshutdown t))

(use-package tempel)

(use-package eshell
  :ensure nil
  :config
  (defun my/eshell-default-prompt-fn ()
    "Generate the prompt string for eshell. Use for `eshell-prompt-function'."
    (concat (if (bobp) "" "\n")
            (when (bound-and-true-p conda-env-current-name)
              (propertize (concat "(" conda-env-current-name ") ")
                          'face 'my/eshell-prompt-git-branch))
            (let ((pwd (eshell/pwd)))
              (propertize (if (equal pwd "~")
                              pwd
                            (abbreviate-file-name pwd))
                          'face 'my/eshell-prompt-pwd))
            (propertize (my/eshell--current-git-branch)
                        'face 'my/eshell-prompt-git-branch)
            (propertize " λ" 'face (if (zerop eshell-last-command-status) 'success 'error))
            " "))

  (defsubst my/eshell--current-git-branch ()
    ;; TODO Refactor me
    (cl-destructuring-bind (status . output)
        (with-temp-buffer (cons
                           (or (call-process "git" nil t nil "symbolic-ref" "-q" "--short" "HEAD")
                               (call-process "git" nil t nil "describe" "--all" "--always" "HEAD")
                               -1)
                           (string-trim (buffer-string))))
      (if (equal status 0)
          (format " [%s]" output)
        "")))

  (setq eshell-banner-message
        '(format "%s %s\n"
                 (propertize (format " %s " (string-trim (buffer-name)))
                             'face 'mode-line-highlight)
                 (propertize (current-time-string)
                             'face 'font-lock-keyword-face))
        eshell-scroll-to-bottom-on-input 'all
        eshell-scroll-to-bottom-on-output 'all
        eshell-kill-processes-on-exit t
        eshell-hist-ignoredups t

        ;; em-glob
        eshell-glob-case-insensitive t
        eshell-error-if-no-glob t)

  (setq eshell-prompt-regexp "^.* λ "
        eshell-prompt-function #'my/eshell-default-prompt-fn))

(use-package eat
  :config
  (setq eat-kill-buffer-on-exit t)

  (mk/keybind project-prefix-map
    [remap project-shell] #'eat-project))

(use-package buffer-env
  :config
  (setq buffer-env-script-name '(".envrc" "flake.nix"))
  (add-hook 'hack-local-variables-hook #'buffer-env-update)
  (add-hook 'comint-mode-hook #'buffer-env-update))

(use-package paredit
  :config
  (dolist (h '(clojure-mode-hook cider-repl-mode-hook emacs-lisp-mode-hook scheme-mode-hook racket-mode-hook))
    (add-hook h #'paredit-mode)))

(use-package rainbow-delimiters
  :config
  (add-hook 'prog-mode-hook #'rainbow-delimiters-mode))

(use-package clojure-mode)
(use-package cider)
(setq cider-repl-pop-to-buffer-on-connect 'display-only)

(use-package geiser
  :config
  (setq geiser-autodoc-identifier-format "%s -> %s"))

(use-package nix-mode
  :mode "\\.nix\\'"
  :config
  (add-to-list 'eglot-server-programs '(nix-mode . ("nil")))
  (add-hook 'nix-mode-hook #'eglot-ensure))

  (use-package geiser-guile
    :config
    (when (executable-find "guix")
      ;; (add-to-list 'geiser-guile-load-path
      ;; 		 (expand-file-name "~/.config/guix/current/share/guile/site/3.0"))
      (load-file "~/dev/guix/etc/copyright.el")
      (setq copyright-names-regexp
	    (format "%s <%s>" user-full-name user-mail-address))
      (with-eval-after-load 'geiser-guile
	(add-to-list 'geiser-guile-load-path "~/dev/guix"))

      ;; Yasnippet configuration
      (with-eval-after-load 'yasnippet
	(add-to-list 'yas-snippet-dirs "~/dev/guix/etc/snippets/yas"))
      ;; Tempel configuration
      (with-eval-after-load 'tempel
	;; Ensure tempel-path is a list -- it may also be a string.
	(unless (listp 'tempel-path)
	  (setq tempel-path (list tempel-path)))
	(add-to-list 'tempel-path "~/dev/guix/etc/snippets/tempel/*"))))

;;; setup-ide.el ends here
