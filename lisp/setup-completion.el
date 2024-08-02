;;; setup-completion.el --- Setup for completion packages embark, vertico, orderless, marginalia, consult  -*- lexical-binding: t; -*-

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

(use-package vertico
  :config
  (setq vertico-cycle t)
  (vertico-mode))

(use-package orderless
  :config
  (setq completion-styles '(orderless basic)
	completion-category-overrides '((file (styles basic partial-completion)))))

(use-package embark
  :config
  (mk/keybind global-map
    "C-." #'embark-act)
  (mk/keybind embark-file-map
    "s" #'sudo-find-file))

(use-package embark-consult)

(use-package consult
  :config
  (mk/keybind (current-global-map)
    [remap bookmark-jump]                 #'consult-bookmark
    [remap evil-show-marks]               #'consult-mark
    [remap evil-show-jumps]               #'+vertico/jump-list
    [remap evil-show-registers]           #'consult-register
    [remap goto-line]                     #'consult-goto-line
    [remap imenu]                         #'consult-imenu
    [remap Info-search]                   #'consult-info
    [remap locate]                        #'consult-locate
    [remap load-theme]                    #'consult-theme
    [remap man]                           #'consult-man
    [remap recentf-open-files]            #'consult-recent-file
    [remap switch-to-buffer]              #'consult-buffer
    [remap switch-to-buffer-other-window] #'consult-buffer-other-window
    [remap switch-to-buffer-other-frame]  #'consult-buffer-other-frame
    [remap yank-pop]                      #'consult-yank-pop)

  (setq consult-fd-args '((if
			      (executable-find "fdfind" 'remote)
			      "fdfind" "fd")
			  "--full-path --color=never --hidden"))
  (setq consult-ripgrep-args "rg --null --line-buffered --color=never --max-columns=1000 --path-separator /   
--smart-case --no-heading --with-filename --line-number --search-zip --hidden"))

(use-package marginalia
  :config
  (mk/keybind minibuffer-local-map
    "M-a" #'marginalia-cycle)
  (marginalia-mode))

(use-package corfu
  :config
  (setq corfu-auto t
    	corfu-auto-prefix 2
    	corfu-cycle t)
  (global-corfu-mode))

(use-package nerd-icons-corfu
  :config
  (add-to-list 'corfu-margin-formatters #'nerd-icons-corfu-formatter))

;;; setup-completion.el ends here
