;;; setup-org.el --- Org Mode Setup                  -*- lexical-binding: t; -*-

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

(use-package org
  :bind (("\C-cl" . org-store-link)
	 ("<f5>" . org-capture)
	 ("<f6>" . org-agenda)) 
  :config
  (setq org-todo-keywords '((sequence "TODO(t)" "PROJECT(p!)" "DEFERRED(b@/!)" "SUSPENDED(S@/!)" "WAITING(w@/!)" "DELEGATED(D@/!)" "APPT(a@/!)" "SOMEDAY(s@/!)" "|" "DONE(d@/!)" "CANCELED(c@/!)"))
	org-agenda-files '("~/Dokumente/org/todo.org" "~/Dokumente/org/inbox.org" "~/Dokumente/org/repeating.org" "~/Dokumente/org/someday.org")
	org-log-into-drawer t
	org-cycle-separator-lines -1
	org-log-done 'time
	org-return-follows-link t
	org-special-ctrl-a t
	org-special-ctrl-k t
	org-imenu-depth 7
	org-refile-target-verify-function nil
	org-outline-path-complete-in-steps nil
        org-refile-use-outline-path 'file
        org-refile-use-cache nil
	org-refile-targets '((org-agenda-files :todo . "PROJECT")
			     ("~/Dokumente/org/sources.org" :level . 0))))

(use-package org-agenda
  :ensure nil
  :after org
  :commands org-agenda
  :hook (org-agenda-finalize . hl-line-mode)
  :bind (:map org-agenda-mode-map
              ("D" . org-agenda-day-view)
              ("W" . org-agenda-week-view)
              ("w" . org-agenda-refile))
  :config
  (setq-default
   org-agenda-span 2
   org-agenda-restore-windows-after-quit t
   org-agenda-window-setup 'current-window
   org-stuck-projects '("TODO=\"PROJECT\"|TODO=\"SUSPENDED\"" ("TODO" "DEFERRED") nil "")
   org-agenda-use-time-grid nil
   org-agenda-todo-ignore-scheduled nil
   org-agenda-text-search-extra-files nil
   org-agenda-tags-column 'auto
   org-agenda-skip-scheduled-if-done t
   org-agenda-skip-scheduled-if-deadline-is-shown t
   org-agenda-show-all-dates nil
   org-agenda-inhibit-startup t
   org-agenda-include-diary nil
   org-agenda-follow-indirect nil
   org-agenda-default-appointment-duration 60)

  (advice-add 'org-agenda-do-tree-to-indirect-buffer :after
	      (defun mk/org-agenda-collapse-indirect-buffer-tree (arg)
		(with-current-buffer org-last-indirect-buffer
		  (org-ctrl-c-tab) (org-fold-show-entry 'hide-drawers))))

  (defun mk/org-agenda-next-section (arg)
    (interactive "p")
    (when (> arg 0)
      (dotimes (_ arg)
        (when-let ((m (text-property-search-forward 'face 'org-agenda-structure t t)))
          (goto-char (prop-match-beginning m))
          (forward-char 1)))))

  ;; FIXME this is broken
  (defun mk/org-agenda-previous-section (arg)
    (interactive "p")
    (when (> arg 0)
      (dotimes (_ arg)
        (when-let ((m (text-property-search-backward 'face 'org-agenda-structure nil nil)))
          (goto-char (prop-match-end m))
          ;; (forward-char 1)
          ))))

  (defun org-todo-age (&optional pos)
    (if-let* ((entry-age (org-todo-age-time pos))
              (days (time-to-number-of-days entry-age)))
        (cond
         ((< days 1)   "today")
         ((< days 7)   (format "%dd" days))
         ((< days 30)  (format "%.1fw" (/ days 7.0)))
         ((< days 358) (format "%.1fM" (/ days 30.0)))
         (t            (format "%.1fY" (/ days 365.0))))
      ""))

  (defun org-todo-age-time (&optional pos)
    (let ((stamp (org-entry-get (or pos (point)) "CREATED" t)))
      (when stamp
        (time-subtract (current-time)
                       (org-time-string-to-time stamp)))))

  (defun org-current-is-todo ()
    (member (org-get-todo-state) '("TODO" "STARTED")))
  
  (defun mk/org-agenda-should-skip-p ()
    "Skip all but the first non-done entry."
    (let (should-skip-entry)
      (unless (org-current-is-todo)
	(setq should-skip-entry t))
      (when (or (org-get-scheduled-time (point))
		(org-get-deadline-time (point)))
	(setq should-skip-entry t))
      (when (/= (point)
		(save-excursion
                  (org-goto-first-child)
                  (point)))
	(setq should-skip-entry t))
      (save-excursion
	(while (and (not should-skip-entry) (org-goto-sibling t))
          (when (and (org-current-is-todo)
                     (not (org-get-scheduled-time (point)))
                     (not (org-get-deadline-time (point))))
            (setq should-skip-entry t))))
      (when (and (not should-skip-entry)
		 (save-excursion
                   (unless (= (org-outline-level) 1)
                     (outline-up-heading 1 t))
                   (not (member (org-get-todo-state)
				'("PROJECT")))))
	(setq should-skip-entry t))
      should-skip-entry))
  
  (defun mk/org-agenda-skip-all-siblings-but-first ()
    "Skip all but the first non-done entry."
    (when (mk/org-agenda-should-skip-p)
      (or (outline-next-heading)
          (goto-char (point-max)))))
  
  (setq org-agenda-custom-commands
        '(("n" "Project Next Actions" alltodo ""
           ((org-agenda-prefix-format '((agenda . " %i %b %-12:c%?-12t% s")
					(todo . " %i %b")
					(tags . " %i %-12:c")
					(search . " %i %-12:c")))
	    (org-agenda-overriding-header "Project Next Actions")
            (org-agenda-skip-function #'mk/org-agenda-skip-all-siblings-but-first)))

          ("P" "All Projects" tags "TODO=\"PROJECT\"&LEVEL>1|TODO=\"SUSPENDED\"" ;|TODO=\"CLOSED\"
           ((org-agenda-overriding-header "All Projects")))

          ("i" "Inbox" tags "CATEGORY=\"Inbox\"&LEVEL=1"
           ((org-agenda-overriding-header "Uncategorized items")))

          ("W" "Waiting tasks" tags "W-TODO=\"DONE\"|TODO={WAITING\\|DELEGATED}"
           ((org-agenda-overriding-header "Waiting/delegated tasks:")
            (org-agenda-skip-function '(org-agenda-skip-entry-if 'scheduled))
            (org-agenda-sorting-strategy '(todo-state-up priority-down category-up))))

          ("D" "Deadlined tasks" tags "TODO<>\"\"&TODO<>{DONE\\|CANCELED\\|PROJECT}"
           ((org-agenda-overriding-header "Deadlined tasks: ")
            (org-agenda-skip-function '(org-agenda-skip-entry-if 'notdeadline))
            (org-agenda-sorting-strategy '(category-up))))

          ("S" "Scheduled tasks" tags "TODO<>\"\"&TODO<>{APPT\\|DONE\\|CANCELED\\|PROJECT}&STYLE<>\"habit\""
           ((org-agenda-overriding-header "Scheduled tasks: ")
            (org-agenda-skip-function '(org-agenda-skip-entry-if 'notscheduled))
            (org-agenda-sorting-strategy '(category-up))
            (org-agenda-prefix-format "%-11c%s ")))
          
          ("u" "Unscheduled tasks" tags "TODO<>\"\"&TODO<>{DONE\\|CANCELED\\|PROJECT\\|DEFERRED\\|SOMEDAY}"
           ((org-agenda-overriding-header "Unscheduled tasks: ")
            (org-agenda-skip-function
             '(org-agenda-skip-entry-if 'scheduled 'deadline 'timestamp))
            (org-agenda-sorting-strategy '(user-defined-up))
            (org-agenda-prefix-format "%-11c%5(org-todo-age) ")
            (org-agenda-files '("~/Dokumente/org/todo.org"))))

          ("~" "Someday Tasks" tags "TODO=\"SOMEDAY\""
           ((org-agenda-overriding-header "Maybe tasks:")
            (org-agenda-sorting-strategy '(user-defined-up))
            (org-agenda-prefix-format "%-11c%5(org-todo-age) ")
            ))

          ("K" "Habits" tags "STYLE=\"habit\""
           ((mk/org-habit-show-graphs-everywhere t)
            (org-agenda-overriding-header "Habits:")
            (org-habit-show-all-today t)))
          
          ("o" "Overview"
           ((tags-todo "*"
		       ((org-agenda-skip-function '(org-agenda-skip-if nil '(timestamp)))
			(org-agenda-skip-function
			 `(org-agenda-skip-entry-if
			   'notregexp ,(format "\\[#%s\\]" ;;(char-to-string org-priority-highest)
					       "\\(?:A\\|B\\|C\\)")))
			(org-agenda-block-separator nil)
			(org-agenda-overriding-header "⛤ Important\n")))
            (agenda ""
                    ((org-agenda-overriding-header "\n🕐 Today\n")
                     (org-agenda-span 1)
                     (org-deadline-warning-days 0)
                     (org-agenda-day-face-function (lambda (date) 'org-agenda-date))
                     (org-agenda-block-separator nil)))
            (agenda "" ((org-agenda-start-on-weekday nil)
			(org-agenda-start-day "+1d")
			(org-agenda-span 3)
			(org-deadline-warning-days 0)
			(org-agenda-block-separator nil)
			(org-agenda-skip-function '(org-agenda-skip-entry-if 'todo 'done))
			(org-agenda-overriding-header "\n📅 Next three days\n")))
            (tags "CATEGORY=\"Inbox\"&LEVEL=1"
		  ((org-agenda-block-separator nil)
		   (org-agenda-overriding-header "\n📧 Inbox\n")))
            (agenda ""
                    ((org-agenda-time-grid nil)
                     (org-agenda-start-on-weekday nil)
                     ;; We don't want to replicate the previous section's
                     ;; three days, so we start counting from the day after.
                     (org-agenda-start-day "+3d")
                     (org-agenda-span 14)
                     (org-agenda-show-all-dates nil)
                     (org-deadline-warning-days 0)
                     (org-agenda-block-separator nil)
                     (org-agenda-entry-types '(:deadline))
                     (org-agenda-skip-function '(org-agenda-skip-entry-if 'todo 'done))
                     (org-agenda-overriding-header "\n🞜 Upcoming deadlines (+14d)\n")))
            (alltodo ""
		     ((org-agenda-prefix-format '((agenda . " %i %b %-12:c%?-12t% s")
						  (todo . " %i %b")
						  (tags . " %i %-12:c")
						  (search . " %i %-12:c")))
		      (org-agenda-block-separator nil)
		      (org-agenda-overriding-header "\n🚩 Project Next Actions\n")
		      (org-agenda-skip-function #'mk/org-agenda-skip-all-siblings-but-first)))
            (todo "WAITING"
                  ((org-agenda-overriding-header "\n💤 On Hold\n")
                   (org-agenda-block-separator nil))))))))

(use-package org-habit
  :after org-agenda
  :ensure nil
  :config
  (setq org-habit-preceding-days 42)
  
  (defvar mk/org-habit-show-graphs-everywhere nil
    "If non-nil, show habit graphs in all types of agenda buffers.

Normally, habits display consistency graphs only in
\"agenda\"-type agenda buffers, not in other types of agenda
buffers.  Set this variable to any non-nil variable to show
consistency graphs in all Org mode agendas.")

  (defun mk/org-agenda-mark-habits ()
    "Mark all habits in current agenda for graph display.

This function enforces `mk/org-habit-show-graphs-everywhere' by
marking all habits in the current agenda as such.  When run just
before `org-agenda-finalize' (such as by advice; unfortunately,
`org-agenda-finalize-hook' is run too late), this has the effect
of displaying consistency graphs for these habits.

When `mk/org-habit-show-graphs-everywhere' is nil, this function
has no effect."
    (when (and mk/org-habit-show-graphs-everywhere
               (not (get-text-property (point) 'org-series)))
      (let ((cursor (point))
            item data) 
        (while (setq cursor (next-single-property-change cursor 'org-marker))
          (setq item (get-text-property cursor 'org-marker))
          (when (and item (org-is-habit-p item)) 
            (with-current-buffer (marker-buffer item)
              (setq data (org-habit-parse-todo item))) 
            (put-text-property cursor
                               (next-single-property-change cursor 'org-marker)
                               'org-habit-p data))))))

  (advice-add #'org-agenda-finalize :before #'mk/org-agenda-mark-habits))

(use-package org-capture
  :ensure nil
  :after org
  :defer
  :config
  (pcase-dolist
      (`(,key . ,template)
       '(("r" "Add resource" entry (file "~/Dokumente/org/inbox.org")
          "* TODO [[%c][%^{Title: }]] %^G\n:PROPERTIES:\n:CREATED:  %U\n:END:\n"
          :immediate-finish t)
         ("t" "Add task" entry (file "~/Dokumente/org/inbox.org")
          "* TODO %?\n:PROPERTIES:\n:CREATED:  %U\n:END:\n%a\n%i\n")
         ("c" "Add calendar entry" entry (file "~/Dokumente/org/gmail-cal.org")
          "* %?\n%^{LOCATION}p\n:%(progn (require 'org-gcal) (symbol-value 'org-gcal-drawer-name)):
%a\n:END:")))
    (setf (alist-get key org-capture-templates nil nil #'equal)
          template)))

(use-package org-modern
  :after org
  :ensure (:host github
		 :repo "minad/org-modern")
  :config
  (setq org-ellipsis "…"
	org-modern-hide-stars nil
	org-modern-hide-stars 'leading)
  (set-face-attribute 'org-ellipsis nil :inherit 'default :box nil)
  
  (defun mk/org-modern-spacing ()
    (setq-local line-spacing
                (if org-modern-mode
                    0.1 0.0)))

  (add-hook 'org-modern-mode-hook #'mk/org-modern-spacing)
  (add-hook 'org-mode-hook #'org-modern-mode)
  (add-hook 'org-agenda-finalize-hook #'org-modern-agenda))
;;; setup-org.el ends here
