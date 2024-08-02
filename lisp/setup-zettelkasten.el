;;; setup-zettelkasten.el --- Zettelkasten Setup     -*- lexical-binding: t; -*-

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

(use-package denote
  :config
  (setq denote-directory "~/Dokumente/zettelkasten"
	denote-known-keywords '()
	denote-prompts '(title keywords signature))

  
  (defun mk/dired-zettelkasten ()
    "Open zettelkasten's 'denote-directory' in dired"
    (interactive)
    (delete-other-windows)
    (dired (denote-directory)))

  
  (add-hook 'dired-mode-hook #'denote-dired-mode))

(use-package citar)

(use-package citar-denote
  :config
  (citar-denote-mode)

  (setq bibtex-completion-bibliography `(,(expand-file-name "references.bib" denote-directory)))
  (setq bibtex-dialect 'biblatex)
  (setq citar-bibliography bibtex-completion-bibliography)

  (setq org-noter-always-create-frame nil)

  (setq citar-library-paths `(,(expand-file-name "library/" denote-directory))
	citar-open-always-create-notes t)

  (setq citar-open-always-create-notes t
	citar-denote-title-format nil))

(use-package pdf-tools)

(use-package nov
  :config
  (setq nov-text-width 80
	visual-fill-column-center-text t)
  (add-to-list 'auto-mode-alist '("\\.epub\\'" . nov-mode)))

(use-package elfeed)

(use-package elfeed-org
  :config
  (setq rmh-elfeed-org-files '("~/Dokumente/elfeed.org"))
  (elfeed-org))

;;; setup-zettelkasten.el ends here
