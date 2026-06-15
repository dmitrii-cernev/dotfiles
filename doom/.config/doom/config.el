;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

;; Place your private configuration here! Remember, you do not need to run 'doom
;; sync' after modifying this file!


;; Some functionality uses this to identify you, e.g. GPG configuration, email
;; clients, file templates and snippets. It is optional.
;; (setq user-full-name "John Doe"
;;       user-mail-address "john@doe.com")

;; Doom exposes five (optional) variables for controlling fonts in Doom:
;;
;; - `doom-font' -- the primary font to use
;; - `doom-variable-pitch-font' -- a non-monospace font (where applicable)
;; - `doom-big-font' -- used for `doom-big-font-mode'; use this for
;;   presentations or streaming.
;; - `doom-symbol-font' -- for symbols
;; - `doom-serif-font' -- for the `fixed-pitch-serif' face
;;
;; See 'C-h v doom-font' for documentation and more examples of what they
;; accept. For example:
;;
;;(setq doom-font (font-spec :family "Fira Code" :size 12 :weight 'semi-light)
;;      doom-variable-pitch-font (font-spec :family "Fira Sans" :size 13))
;;
;; If you or Emacs can't find your font, use 'M-x describe-font' to look them
;; up, `M-x eval-region' to execute elisp code, and 'M-x doom/reload-font' to
;; refresh your font settings. If Emacs still can't find your font, it likely
;; wasn't installed correctly. Font issues are rarely Doom issues!

;; There are two ways to load a theme. Both assume the theme is installed and
;; available. You can either set `doom-theme' or manually load a theme with the
;; `load-theme' function. This is the default:
(setq doom-font (font-spec :family "monospace" :size 20))
(setq doom-theme 'doom-one)

;; This determines the style of line numbers in effect. If set to `nil', line
;; numbers are disabled. For relative line numbers, set this to `relative'.
(setq display-line-numbers-type 'visible)

;; If you use `org' and don't want your org files in the default location below,
;; change `org-directory'. It must be set before org loads!
(setq org-directory "~/org/")


;; Whenever you reconfigure a package, make sure to wrap your config in an
;; `after!' block, otherwise Doom's defaults may override your settings. E.g.
;;
;;   (after! PACKAGE
;;     (setq x y))
;;
;; The exceptions to this rule:
;;
;;   - Setting file/directory variables (like `org-directory')
;;   - Setting variables which explicitly tell you to set them before their
;;     package is loaded (see 'C-h v VARIABLE' to look up their documentation).
;;   - Setting doom variables (which start with 'doom-' or '+').
;;
;; Here are some additional functions/macros that will help you configure Doom.
;;
;; - `load!' for loading external *.el files relative to this one
;; - `use-package!' for configuring packages
;; - `after!' for running code after a package has loaded
;; - `add-load-path!' for adding directories to the `load-path', relative to
;;   this file. Emacs searches the `load-path' when you load packages with
;;   `require' or `use-package'.
;; - `map!' for binding new keys
;;
;; To get information about any of these functions/macros, move the cursor over
;; the highlighted symbol at press 'K' (non-evil users must press 'C-c c k').
;; This will open documentation for it, including demos of how they are used.
;; Alternatively, use `C-h o' to look up a symbol (functions, variables, faces,
;; etc).
;;
;; You can also try 'gd' (or 'C-c c d') to jump to their definition and see how
;; they are implemented.
(setq org-agenda-files '("~/org/"))

(after! org
  ;; TODO keyword states (replaces Doom defaults incl. STRT and LOOP)
  (setq org-todo-keywords
        '((sequence "TODO(t)" "BACKLOG(b)" "NEXT(n)" "IN-PROGRESS(i)" "WAITING(w)" "HOLD(h)" "PROJ(p)" "|" "DONE(d)" "CANCELLED(c)")
          (sequence "[ ](T)" "[-](S)" "[?](W)" "|" "[X](X)")))
  ;; TODO keyword colors with background
  (setq org-todo-keyword-faces
        '(("BACKLOG"     . (:background "#3b3b3b" :foreground "#888888"  :weight bold))
          ("TODO"        . (:background "#ff6c6b" :foreground "white"   :weight bold))
          ("NEXT"        . (:background "#a9a1e1" :foreground "white"   :weight bold))
          ("IN-PROGRESS" . (:background "#e5a50a" :foreground "white"   :weight bold))
          ("WAITING"     . (:background "#51afef" :foreground "white"   :weight bold))
          ("DONE"        . (:background "#98be65" :foreground "white"   :weight bold))
          ("CANCELLED"   . (:background "#5b5b5b" :foreground "#9ca0a4" :weight bold))))

  ;; Skip repeated tasks that are outside their warning period
  (defun my/org-skip-repeated-outside-warning ()
    "Skip entries whose deadline/scheduled has a repeater but is not yet within warning period."
    (let ((end (save-excursion (org-end-of-subtree t))))
      (save-excursion
        (let* ((deadline-str (org-entry-get (point) "DEADLINE"))
               (scheduled-str (org-entry-get (point) "SCHEDULED"))
               (ts-str (or deadline-str scheduled-str)))
          (when (and ts-str (string-match "\\+[0-9]+[hdwmy]" ts-str))
            (let* ((warning-days
                    (cond
                     ((string-match "-\\([0-9]+\\)d" ts-str)
                      (string-to-number (match-string 1 ts-str)))
                     ((string-match "-\\([0-9]+\\)w" ts-str)
                      (* 7 (string-to-number (match-string 1 ts-str))))
                     (t (or org-deadline-warning-days 14))))
                   (ts-time (or (org-get-deadline-time (point))
                                (org-get-scheduled-time (point))))
                   (warn-start (when ts-time
                                 (time-subtract ts-time (days-to-time warning-days)))))
              (when (and warn-start (time-less-p (current-time) warn-start))
                end)))))))

  ;; Skip entries from seconda.org (for main views).
  ;; WAITING entries with DEADLINE/SCHEDULED can be pulled by agenda collection,
  ;; not only by the TODO matcher, so apply this via the global skip function too.
  (defun my/org-in-seconda-p ()
    "Return non-nil when the current Org agenda source buffer is seconda.org."
    (let ((file (buffer-file-name (or (buffer-base-buffer) (current-buffer)))))
      (and file (string= (file-name-nondirectory file) "seconda.org"))))

  (defun my/org-skip-seconda ()
    "Skip entries that belong to seconda.org, except in the dedicated seconda command."
    (when (and (my/org-in-seconda-p)
               (not (equal (and (boundp 'org-keys) org-keys) "2")))
      (save-excursion
        (or (outline-next-heading) (goto-char (point-max)))
        (point))))

  (setq org-agenda-skip-function-global #'my/org-skip-seconda)

  ;; In the main agenda, show only the next occurrence of repeating items
  ;; (e.g. daily habits), instead of listing every future repeat in the span.
  (setq org-agenda-show-future-repeats 'next)

  ;; Load org-habit early enough for it to add its agenda finalize hook;
  ;; otherwise habits can appear without the right-side consistency graph.
  (add-to-list 'org-modules 'org-habit)
  (require 'org-habit)
  (setq org-habit-show-habits t
        org-habit-show-habits-only-for-today nil
        ;; Put graph far enough right to keep agenda text readable.
        org-habit-graph-column 80
        ;; Thin/compact graph: one week history + a couple upcoming days.
        org-habit-preceding-days 10
        org-habit-following-days 2
        ;; Lighter glyphs for the consistency graph.
        org-habit-today-glyph ?┆
        org-habit-completed-glyph ?•
        org-habit-ready-glyph ?·
        org-habit-alert-glyph ?!
        org-habit-overdue-glyph ?×
        org-habit-clear-glyph ? )

  ;; Override default "t" in agenda to exclude checkbox-style keywords and seconda tasks
  (setq org-agenda-custom-commands
        '(("t" "TODOs (no checkboxes)"
           todo "TODO|NEXT|IN-PROGRESS|WAITING|HOLD|PROJ"
           ((org-agenda-skip-function
             (lambda ()
               (or (my/org-skip-seconda)
                   (my/org-skip-repeated-outside-warning))))))
          ("2" "Seconda project"
           todo "TODO|NEXT|IN-PROGRESS|WAITING|HOLD|PROJ"
           ((org-agenda-files '("~/org/seconda.org"))
            (org-agenda-overriding-header "Seconda tasks"))))))

(map! :leader
      :desc "Open neotree" "e" #'+neotree/open)

(setq org-archive-location "~/org/archive.org::* From %s")
(defun my/org-archive-done-tasks ()
  "Archive all DONE tasks preserving their outline tree structure."
  (interactive)
  (let ((archive-file (expand-file-name "~/org/archive.org"))
        (source-file (buffer-file-name)))
    (org-map-entries
     (lambda ()
       (when (member (org-get-todo-state) org-done-keywords)
         (let* ((tree-path (org-get-outline-path))  ; ancestors list
                (heading (org-get-heading t t t t))
                (source-name (file-name-nondirectory source-file))
                (body (save-excursion
                        (org-end-of-meta-data t)
                        (buffer-substring-no-properties
                         (point)
                         (org-end-of-subtree t)))))
           (with-current-buffer (find-file-noselect archive-file)
             ;; Ensure top-level "From <file>" heading exists
             (let ((top-heading (format "From %s" source-name)))
               (or (org-find-exact-headline-in-buffer top-heading)
                   (progn (goto-char (point-max))
                          (insert (format "\n* %s\n" top-heading))))
               (goto-char (org-find-exact-headline-in-buffer top-heading)))
             ;; Recreate each ancestor heading if missing
             (let ((level 2))
               (dolist (ancestor tree-path)
                 (let ((found (save-excursion
                                (org-find-exact-headline-in-buffer ancestor (point)))))
                   (if found
                       (goto-char found)
                     (org-end-of-subtree t)
                     (insert (format "\n%s %s\n" (make-string level ?*) ancestor))))
                 (setq level (1+ level)))
               ;; Insert the DONE entry at the right depth
               (org-end-of-subtree t)
               (insert (format "\n%s DONE %s\n%s"
                               (make-string level ?*)
                               heading
                               body)))
             (save-buffer)))
         ;; Mark for deletion from source
         (org-archive-subtree)))
     "/DONE" 'file)))

(defun my/org-fold-others ()
  "Fold all headings except the current subtree."
  (interactive)
  (org-overview)
  (org-reveal)
  (org-show-subtree))

(map! :after org
      :map org-mode-map
      :localleader
      "A A" #'my/org-archive-done-tasks
      "z"   #'my/org-fold-others)

(defun my/org-job-capture-target ()
  "Return position in the current quarter section in ~/org/job.org, creating it if needed."
  (let* ((year (format-time-string "%Y"))
         (month (string-to-number (format-time-string "%m")))
         (quarter (1+ (/ (1- month) 3)))
         (quarter-heading (format "%s Q%d" year quarter))
         app-pos app-end quarter-pos)
    (goto-char (point-min))
    (setq app-pos (org-find-exact-headline-in-buffer "Applications"))
    (unless app-pos
      (goto-char (point-max))
      (unless (bolp) (insert "\n"))
      (insert "* Applications\n")
      (setq app-pos (org-find-exact-headline-in-buffer "Applications")))
    (goto-char app-pos)
    (setq app-end (save-excursion (org-end-of-subtree t t)))
    (setq quarter-pos
          (save-excursion
            (re-search-forward
             (format "^\\*\\* +%s\\(?:[ \\t]\\|$\\)" (regexp-quote quarter-heading))
             app-end t)))
    (unless quarter-pos
      (goto-char app-end)
      (unless (bolp) (insert "\n"))
      (insert "** " quarter-heading "\n")
      (forward-line -1)
      (setq quarter-pos (point)))
    (goto-char quarter-pos)
    (org-end-of-subtree t t)
    (unless (bolp) (insert "\n"))
    (point)))

(after! org-capture
  ;; Hide unused Doom project capture templates, then reuse "o" for Others.
  (setq org-capture-templates
        (assoc-delete-all "p" (assoc-delete-all "o" org-capture-templates)))
  (setf (alist-get "t" org-capture-templates nil nil #'equal)
        '("Personal todo" entry
          (file+headline +org-capture-todo-file "Inbox")
          "* TODO %?\n%i" :prepend t))
  (setf (alist-get "n" org-capture-templates nil nil #'equal)
        '("Notes" entry
          (file+headline +org-capture-notes-file "Inbox")
          "* %u %?\n%i" :prepend t))
  (setf (alist-get "j" org-capture-templates nil nil #'equal)
        '("Journal" entry
          (file+olp+datetree +org-capture-journal-file)
          "* %U %?\n%i" :prepend t))
  (setf (alist-get "o" org-capture-templates nil nil #'equal)
        '("Others"))
  (setf (alist-get "oj" org-capture-templates nil nil #'equal)
        '("Job application sent" plain
          (file+function "~/org/job.org" my/org-job-capture-target)
          "*** %^{Job name}\n:PROPERTIES:\n:SALARY: %^{Salary|N/A}\n:LOCATION: %^{Location}\n:LINK: %^{Link}\n:SERVICE: %^{Service|LinkedIn|JustJoinIT|No Fluff Jobs|Pracuj.pl|Other}\n:STATUS: %^{Status|Sent|Interview|Offer|Rejected|Ghosted}\n:APPLIED_AT: %U\n:UPDATED_AT: %U\n:END:\n%i\n%?\n")))

(after! org-superstar
  ;; Heading bullet symbols per level
  (setq org-superstar-headline-bullets-list '("◉" "○" "✸" "✿" "✦" "◆"))
  ;; Replace list hyphens/plusses with nicer symbols
  (setq org-superstar-item-bullet-alist '((?- . ?•) (?+ . ?➤))))

(after! org-journal
  (setq org-journal-dir (expand-file-name "journal/" org-directory)
        org-journal-file-type 'daily
        org-journal-file-format "%Y-%m-%d.org"
        org-journal-date-format "%A, %d %B %Y"
        org-journal-carryover-items
        "TODO=\"TODO\"|TODO=\"NEXT\"|TODO=\"IN-PROGRESS\"|TODO=\"WAITING\"|TODO=\"HOLD\"|TODO=\"PROJ\""))

(use-package! reverse-im
  :config
  ;; Russian layout
  (reverse-im-activate "russian-computer")
  ;; Make it work with Evil/Doom
  (setq reverse-im-input-methods '("russian-computer")))
