;;; setup-ui.el --- UI and theme setup               -*- lexical-binding: t; -*-

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

(custom-set-faces
 '(default ((t (:family "Iosevka Comfy"
                        :slant normal :weight normal
                        :height 130 :width normal)))))

(use-package olivetti)

(use-package logos
  :after olivetti
  :config
  (add-hook 'nov-mode-hook (lambda ()
			     (setq olivetti-body-width 80
				   olivetti-minimum-body-width 60)
			     (olivetti-mode)))
  (setq logos-olivetti t))

(use-package doom-themes
  :config
  (setq doom-themes-enable-bold t
        doom-themes-enable-italic t)

  (setq doom-rouge-padded-modeline nil
        doom-rouge-brighter-comments t
        doom-rouge-brighter-tabs t)
  (doom-themes-org-config)
  (load-theme 'doom-gruvbox t))

;; (use-package modus-themes
;;   :config
;;   (modus-themes-load-theme 'modus-operandi))

(use-package doom-modeline
  :config
  (doom-modeline-mode))

(use-package pulsar
  :config
  (pulsar-global-mode))

(use-package hl-todo
  :config
  (global-hl-todo-mode))

(use-package spacious-padding
  :config
  (setq spacious-padding-widths
	'( :internal-border-width 15
           :header-line-width 4
           :mode-line-width 6
           :tab-width 4
           :right-divider-width 30
           :scroll-bar-width 8
           :fringe-width 8))

  ;; Read the doc string of `spacious-padding-subtle-mode-line' as it
  ;; is very flexible and provides several examples.
  (setq spacious-padding-subtle-mode-line
	`( :mode-line-active 'default
           :mode-line-inactive vertical-border))

  (spacious-padding-mode 1)

  ;; Set a key binding if you need to toggle spacious padding.
  (define-key global-map (kbd "<f8>") #'spacious-padding-mode))

;;; setup-ui.el ends here
