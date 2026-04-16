;;; init.el --- Emacs Configuration -*- lexical-binding: t; -*-

;;; Commentary:
;; Personal Emacs configuration
;; Cross-platform: macOS and Linux (Aurora/Fedora)
;; Optimized for org-mode and Rust development

;;; Code:

;; ============================================================================
;; PACKAGE MANAGEMENT
;; ============================================================================

(require 'package)
(setq package-archives '(("melpa" . "https://melpa.org/packages/")
                         ("elpa" . "https://elpa.gnu.org/packages/")))
(package-initialize)

;; Silence compiler warnings
(setq native-comp-async-report-warnings-errors 'silent)
(setq byte-compile-warnings '(not free-vars unresolved noruntime last-line obsolete))

;; Install use-package if missing
(unless (package-installed-p 'use-package)
  (condition-case nil
      (progn
        (package-refresh-contents)
        (package-install 'use-package))
    (error (warn "Could not reach package archives. Starting anyway."))))

(require 'use-package)
(setq use-package-always-ensure t)

;; ============================================================================
;; GPG/OAUTH2 SETTINGS
;; ============================================================================

;; GPG/OAuth2 settings for org-gcal
(setq plstore-encrypt-to '("ross@pearlstone.us"))
(setq oauth2-token-file "~/Documents/Org/.oauth2-tokens.plist")
(setenv "XDG_DATA_HOME" (expand-file-name "~/Documents/Org/.local/share"))

;; Load local secrets EARLY (before packages that need them)
(let ((secrets-file (expand-file-name "init-secrets.el" user-emacs-directory)))
  (when (file-exists-p secrets-file)
    (load secrets-file)))

;; ============================================================================
;; PLATFORM-SPECIFIC OPTIMIZATIONS
;; ============================================================================

;; Scrolling and display (cross-platform)
(setq scroll-conservatively 10
      scroll-margin 3
      scroll-preserve-screen-position t
      auto-window-vscroll nil
      mouse-wheel-scroll-amount '(1 ((shift) . 5))
      mouse-wheel-progressive-speed nil
      frame-resize-pixelwise t
      window-resize-pixelwise t)

;; Trash handling
(setq delete-by-moving-to-trash t)
(when (eq system-type 'darwin)
  (setq trash-directory "~/.Trash"))

;; ============================================================================
;; UI CONFIGURATION
;; ============================================================================

;; Startup behavior
(setq inhibit-startup-message t
      initial-scratch-message nil
      ring-bell-function 'ignore
      confirm-kill-emacs 'yes-or-no-p)

;; Font - platform specific
(set-face-attribute 'default nil 
  :family (cond ((eq system-type 'darwin) "Menlo")
                ((eq system-type 'gnu/linux) "DejaVu Sans Mono")
                (t "Monospace"))
  :height 130)

;; UI cleanup
(menu-bar-mode -1)
(tool-bar-mode -1)
(scroll-bar-mode -1)
(column-number-mode 1)

;; Line numbers - relative with absolute current line
(global-display-line-numbers-mode 1)
(setq display-line-numbers-type 'relative
      display-line-numbers-current-absolute t)

;; Add left padding for breathing room
(setq-default left-fringe-width 16)

;; ============================================================================
;; EDITING BEHAVIOR
;; ============================================================================

;; Auto-pairing brackets and quotes
(use-package elec-pair
  :ensure nil
  :init
  (electric-pair-mode 1)
  :config
  (setq electric-pair-pairs '((?< . ?>)
                              (?` . ?`)))
  (setq electric-pair-text-pairs electric-pair-pairs))

;; Prettify symbols (λ, →, etc.)
(global-prettify-symbols-mode 1)

;; ============================================================================
;; PATH CONFIGURATION
;; ============================================================================

;; Path to main config file (for SPC f e)
(defvar my/config-file (expand-file-name "init.el" user-emacs-directory)
  "Path to the main configuration file.")

;; ============================================================================
;; THEME & APPEARANCE
;; ============================================================================

(use-package doom-themes
  :config
  (load-theme 'doom-city-lights t))

(use-package doom-modeline
  :init
  (doom-modeline-mode 1)
  :custom
  (doom-modeline-height 25)
  (doom-modeline-battery t))

(use-package nerd-icons)

;; ============================================================================
;; WHICH-KEY (KEYBINDING HELP)
;; ============================================================================

(use-package which-key
  :init
  (setq which-key-idle-delay 0.3)
  :config
  (which-key-mode)
  (setq which-key-compute-remaps nil)
  (which-key-setup-side-window-bottom))

;; ============================================================================
;; EVIL MODE (VIM EMULATION)
;; ============================================================================

(use-package evil
  :init
  (setq evil-want-integration t
        evil-want-keybinding nil)
  :config
  (evil-mode 1))

(use-package evil-collection
  :after evil
  :init
  (setq evil-collection-calendar-want-prefix t)
  :config
  ;; Remove calfw from collection (we configure it separately)
  (setq evil-collection-mode-list (delq 'calfw evil-collection-mode-list))
  (evil-collection-init)
  ;; Fix dired 'o' binding
  (evil-collection-define-key 'normal 'dired-mode-map
    "o" 'dired-find-file-other-window))

(use-package evil-surround
  :after evil
  :demand t
  :config
  (global-evil-surround-mode 1))

;; ============================================================================
;; KEYBINDINGS (GENERAL)
;; ============================================================================

(use-package general
  :config
  (general-create-definer my/leader-keys
    :keymaps '(normal insert visual emacs)
    :prefix "SPC"
    :global-prefix "C-SPC")
  
  (my/leader-keys
    ;; Search
    "/"   '(consult-line :which-key "search buffer")
    "?"   '(consult-ripgrep :which-key "search project")
    
    ;; Files
    "f"   '(:ignore t :which-key "file")
    "ff"  '(find-file :which-key "find file")
    "fs"  '(save-buffer :which-key "save file")
    "fe"  '((lambda () (interactive) (find-file my/config-file)) :which-key "edit config")
    "fd"  '(dired-jump :which-key "open dired")
    "fr"  '(recentf-open-files :which-key "recent files")
 
    ;; Buffers
    "b"   '(:ignore t :which-key "buffer")
    "bb"  '(consult-buffer :which-key "switch buffer")
    "bk"  '(kill-current-buffer :which-key "kill buffer")
    
    ;; Jump
    "j"   '(:ignore t :which-key "jump")
    "ji"  '(consult-imenu :which-key "jump to symbol")
    "jj"  '(avy-goto-char-timer :which-key "jump to char")
    "jl"  '(consult-goto-line :which-key "jump to line")
    "jw"  '(avy-goto-word-1 :which-key "jump to word")

    ;; Help/Reload
    "h"   '(:ignore t :which-key "help/reload")
    "hr"  '((lambda () (interactive) (load-file user-init-file)) :which-key "reload config")
 
    ;; Git
    "g"   '(:ignore t :which-key "git")
    "gs"  '(magit-status :which-key "magit")
    "gb"  '(magit-branch-checkout :which-key "switch branch")
    "gl"  '(magit-log-all :which-key "log")
    
    ;; Org Mode
    "o"   '(:ignore t :which-key "org")
    "oa"  '(org-agenda :which-key "agenda")
    "oc"  '(org-capture :which-key "capture")
    "ol"  '(org-store-link :which-key "store link")
    "or"  '(org-refile :which-key "refile")
    "oC"  '(calfw-org-open-calendar :which-key "open calendar")
    
    "og"  '(:ignore t :which-key "google cal")
    "ogf" '(org-gcal-fetch :which-key "fetch from google")
    "ogs" '(org-gcal-sync :which-key "sync with google")
    "ogp" '(org-gcal-post-at-point :which-key "post entry to google")
    "ogd" '(org-gcal-delete-at-point :which-key "delete from google")
    
    ;; Org-Roam 
    "on"  '(:ignore t :which-key "roam")
    "ond" '(my/org-roam-delete-node :which-key "delete node")
    "onf" '(org-roam-node-find :which-key "find node")
    "oni" '(org-roam-node-insert :which-key "insert link")
    "onl" '(org-roam-buffer-toggle :which-key "backlinks")
    "ons" '(org-roam-db-sync :which-key "sync db")
 
    "ms"  '(org-schedule :which-key "mark schedule")
 
    ;; Calendar Navigation
    "n"   '(:ignore t :which-key "navigate")
    
    "nm"  '(:ignore t :which-key "month")
    "nmf" '(calfw-navi-next-month-command :which-key "forward")
    "nmb" '(calfw-navi-previous-month-command :which-key "backward")
    
    "nw"  '(:ignore t :which-key "week")
    "nwf" '(calfw-navi-next-week-command :which-key "forward")
    "nwb" '(calfw-navi-previous-week-command :which-key "backward")
    
    "nd"  '(:ignore t :which-key "day")
    "ndf" '(calfw-navi-next-day-command :which-key "forward")
    "ndb" '(calfw-navi-previous-day-command :which-key "backward")
    
    "nt"  '(calfw-navi-goto-today-command :which-key "goto today")
    "ng"  '(calfw-navi-goto-date-command :which-key "goto date")
    "nr"  '(calfw-refresh-calendar-buffer :which-key "refresh")
    "ns"  '(calfw-show-details-command :which-key "show details")
    
    "nv"  '(:ignore t :which-key "view")
    "nvd" '(calfw-change-view-day :which-key "day view")
    "nvw" '(calfw-change-view-week :which-key "week view")
    "nvm" '(calfw-change-view-month :which-key "month view")
    "nvt" '(calfw-change-view-two-weeks :which-key "two-week view")
    
    "nc"  '((lambda () (interactive) 
              (switch-to-buffer "*cfw-calendar*")
              (delete-other-windows)) :which-key "close details")
    
    "nq"  '((lambda () (interactive)
              (let ((details-buf (get-buffer "*calfw-details*")))
                (when details-buf (kill-buffer details-buf)))
              (let ((cal-buf (get-buffer "*cfw-calendar*")))
                (when cal-buf (kill-buffer cal-buf)))
              (delete-other-windows)) :which-key "quit calendar")
    
    ;; PDF Navigation
    "p"   '(:ignore t :which-key "pdf")
    "pn"  '(doc-view-next-page :which-key "next page")
    "pp"  '(doc-view-previous-page :which-key "prev page")
    "pk"  '(quit-window :which-key "close pdf")
 
    ;; Rust Development
    "r"   '(:ignore t :which-key "rust")
    "rr"  '(cargo-process-run :which-key "cargo run")
    "rb"  '(cargo-process-build :which-key "cargo build")
    "rt"  '(cargo-process-test :which-key "cargo test")
    "rc"  '(cargo-process-check :which-key "cargo check")
    "rf"  '(rust-format-buffer :which-key "format buffer")
    "rd"  '(xref-find-definitions :which-key "goto definition")
    "rD"  '(xref-find-references :which-key "find references")
    "rh"  '(eldoc-doc-buffer :which-key "describe")
    "ra"  '(eglot-code-actions :which-key "code action")
 
    ;; Code Snippets
    "s"   '(:ignore t :which-key "snippets")
    "si"  '(yas-insert-snippet :which-key "insert snippet")
    "sn"  '(yas-new-snippet :which-key "new snippet")
    "sv"  '(yas-visit-snippet-file :which-key "visit snippet file")
 
;; Terminal
    "t"   '(:ignore t :which-key "terminal")
    "tt"  '(vterm :which-key "vterm")
    "tT"  '(vterm-other-window :which-key "vterm other window")

    ;; Markdown
    "m"   '(:ignore t :which-key "markdown")
    "mp"  '(markdown-preview-mode :which-key "preview")
    "mt"  '(markdown-toggle-markup-hiding :which-key "toggle markup")
    ;; Errors (Flymake/LSP)
    "e"   '(:ignore t :which-key "errors")
    "en"  '(flymake-goto-next-error :which-key "next error")
    "ep"  '(flymake-goto-prev-error :which-key "prev error")
    "el"  '(flymake-show-buffer-diagnostics :which-key "list errors")
    
    ;; Terminal
    "t"   '(:ignore t :which-key "terminal")
    "tt"  '(vterm :which-key "vterm")
    "tT"  '(vterm-other-window :which-key "vterm other window")))

;; ============================================================================
;; COMPLETION FRAMEWORK (VERTICO + ORDERLESS + MARGINALIA)
;; ============================================================================

(use-package vertico
  :init
  (vertico-mode 1)
  :config
  (setq vertico-count 10
        vertico-resize t
        vertico-cycle t)
  (add-hook 'rfn-eshadow-update-overlay-hook #'vertico-directory-tidy))

(use-package orderless
  :custom
  (completion-styles '(basic orderless))
  (completion-category-defaults nil)
  (completion-category-overrides
   '((eglot (styles basic orderless))
     (file (styles basic partial-completion)))))

(use-package marginalia
  :init
  (marginalia-mode 1))

(use-package savehist
  :ensure nil
  :init
  (savehist-mode))

(use-package emacs
  :ensure nil
  :custom
  (context-menu-mode t)
  (enable-recursive-minibuffers t)
  (read-extended-command-predicate #'command-completion-default-include-p)
  (minibuffer-prompt-properties
   '(read-only t cursor-intangible t face minibuffer-prompt)))

;; ============================================================================
;; COMPANY (AUTO-COMPLETION)
;; ============================================================================

(use-package company
  :init
  (global-company-mode)
  :config
  (setq company-idle-delay 0.1
        company-minimum-prefix-length 2
        company-show-numbers t
        company-tooltip-align-annotations t
        company-selection-wrap-around t
        company-transformers '(company-sort-prefer-same-case-prefix))
  
  (setq company-backends '((company-capf :with company-yasnippet)
                           (company-dabbrev-code company-keywords company-files)
                           (company-dabbrev)))
  
  (setq company-dabbrev-downcase nil
        company-dabbrev-ignore-case nil
        company-dabbrev-other-buffers t
        company-dabbrev-code-other-buffers 'all)
  
  :bind (:map company-active-map
              ("C-n" . company-select-next)
              ("C-p" . company-select-previous)
              ("C-d" . company-show-doc-buffer)
              ("M-." . company-show-location)))

(use-package company-box
  :hook (company-mode . company-box-mode)
  :config
  (setq company-box-doc-enable t
        company-box-doc-delay 0.3))

;; ============================================================================
;; YASNIPPET (CODE SNIPPETS)
;; ============================================================================

(use-package yasnippet
  :config
  (yas-global-mode 1))

(use-package yasnippet-snippets)

;; ============================================================================
;; GIT (MAGIT)
;; ============================================================================

(use-package magit)

;; ============================================================================
;; AVY (JUMP NAVIGATION)
;; ============================================================================

(use-package avy
  :config
  (setq avy-background t
        avy-style 'at-full))

;; ============================================================================
;; CONSULT (ENHANCED SEARCH)
;; ============================================================================

(use-package consult
  :bind (("C-s" . consult-line))
  :config
  (setq consult-preview-key 'any))

;; ============================================================================
;; VTERM (TERMINAL EMULATOR)
;; ============================================================================

(use-package vterm
  :config
  (setq vterm-max-scrollback 10000
        vterm-kill-buffer-on-exit t))

;; ============================================================================
;; RUST DEVELOPMENT
;; ============================================================================

;; Add Rust tools to PATH on macOS (handled by distrobox on Linux)
(when (eq system-type 'darwin)
  (setenv "PATH" (concat (getenv "HOME") "/.cargo/bin:" (getenv "PATH")))
  (add-to-list 'exec-path (concat (getenv "HOME") "/.cargo/bin")))

;; Eglot (built-in LSP client)
(use-package eglot
  :ensure nil
  :config
  (setq eldoc-echo-area-display-truncation-message nil
        eldoc-echo-area-use-multiline-p 4
        eldoc-echo-area-prefer-doc-buffer t
        eldoc-idle-delay 0.1
        eldoc-documentation-strategy #'eldoc-documentation-default)
  
  (add-hook 'eglot-managed-mode-hook #'eglot-inlay-hints-mode)
  
  (setq eglot-server-programs
        (cons '((rust-mode rust-ts-mode) . 
                ("rust-analyzer" :initializationOptions
                 (:checkOnSave t
                  :procMacro (:enable t)
                  :inlayHints (:typeHints (:enable t)
                               :parameterHints (:enable t)
                               :chainingHints (:enable t)))))
              (delete (assoc 'rust-mode eglot-server-programs) 
                      eglot-server-programs))))

(use-package eglot-booster
  :vc (:url "https://github.com/jdtsmith/eglot-booster")
  :after eglot
  :config
  (eglot-booster-mode))

(use-package rust-mode
  :demand t
  :init
  (setq rust-mode-treesitter-derive t)
  :hook ((rust-mode . eglot-ensure)
         (rust-ts-mode . eglot-ensure))
  :config
  (setq rust-format-on-save t))

(use-package treesit-auto
  :config
  (global-treesit-auto-mode))

(use-package cargo
  :hook (rust-mode . cargo-minor-mode))

;; ============================================================================
;; DOC-VIEW (PDFs)
;; ============================================================================

(pixel-scroll-precision-mode -1)

(use-package doc-view
  :ensure nil
  :config
  (setq doc-view-resolution 200
        doc-view-continuous nil)
  
  (add-hook 'doc-view-mode-hook
            (lambda ()
              (display-line-numbers-mode -1)
              (hl-line-mode -1)
              (pixel-scroll-precision-mode -1))))

(with-eval-after-load 'doc-view
  (general-define-key
   :states 'normal
   :keymaps 'doc-view-mode-map
   "SPC" nil
   "j" (lambda () (interactive) (doc-view-next-line-or-next-page 5))
   "k" (lambda () (interactive) (doc-view-previous-line-or-previous-page 5))
   "J" 'doc-view-next-page
   "K" 'doc-view-previous-page
   "q" 'quit-window))

;; ============================================================================
;; ORG MODE
;; ============================================================================

(use-package org
  :ensure nil
  :init
  (with-eval-after-load 'org
    (setq org-todo-keywords
          '((sequence "PROJ(p)" "IN-PROGRESS(i@)" "TODO(t)" "WAIT(w@/!)" "|" "RESCHEDULE(r)" "DONE(d!)" "CANCELED(c@)"))))
  
  (setq org-tag-alist '(("@work" . ?w)
                        ("@home" . ?h)
                        ("@flight" . ?f)
                        ("@hotel" . ?t)
                        ("@travel" . ?v)
                        ("urgent" . ?u)
                        ("PROJ" . ?p)))
  :config
  (setq org-directory "~/Documents/Org"
        org-agenda-files (directory-files-recursively "~/Documents/Org/" "\\.org$"))
  
  (defun my/keep-agenda-files-clean ()
    "Ensure only files in org-directory are in org-agenda-files."
    (setq org-agenda-files 
          (seq-filter (lambda (f) 
                        (string-prefix-p (expand-file-name org-directory) 
                                         (expand-file-name f)))
                      org-agenda-files)))
  (add-hook 'org-agenda-mode-hook #'my/keep-agenda-files-clean)
  
  (setq org-M-RET-may-split-line '((default . nil))
        org-insert-heading-respect-content t
        org-log-done 'time
        org-agenda-show-current-time-in-grid t
        org-deadline-warning-days 5
        calendar-mark-diary-entries-flag t
        org-agenda-include-diary t
        cfw:org-agenda-schedule-args '(:scheduled :deadline :timestamp :sexp :todo)
        org-agenda-span 10
        org-agenda-start-day "-3d"
        org-agenda-start-on-weekday nil
        org-startup-indented t
        org-hide-emphasis-markers t
        org-image-actual-width nil
        org-tags-column -77
        org-use-tag-inheritance t
        org-log-into-drawer t
        org-refile-targets '((org-agenda-files :maxlevel . 2))
        org-refile-use-outline-path 'file
        org-refile-allow-creating-parent-nodes 'confirm)
  
  (setq org-capture-templates
        '(("t" "Todo" entry
           (file+headline "~/Documents/Org/inbox.org" "Inbox")
           "* TODO %^{Task}\n:PROPERTIES:\n:CREATED: %U\n:CAPTURED: %a\n:END:\n%?")
          
          ("v" "Travel" entry
           (file+headline "~/Documents/Org/travel.org" "Travel")
           "* %?\nEntered on %U\n  %i\n  %a")
          
          ("s" "Sleep/BFS Tracker" table-line
           (file+headline "~/Documents/Org/health.org" "Sleep and Exercise Log")
           "| %<%Y-%m-%d %a %H:%M> | %^{Ride Time|Morning|Afternoon|Evening} | %^{Intensity|Low|Med|High} | %^{Sleep Quality (1-10)} | %^{Twitch Level (1-10)} |"
           :immediate-finish t)
          
          ("e" "Event" entry
           (file+headline "~/Documents/Org/calendar.org" "Events")
           "* %^{Event}\n%^{SCHEDULED}T\n:PROPERTIES:\n:CREATED: %U\n:CONTACT: %(org-capture-ref-link \"~/Documents/Org/contacts.org\")\n:END:\n%?")
          
          ("d" "Deadline" entry
           (file+headline "~/Documents/Org/calendar.org" "Deadlines")
           "* TODO %^{Task}\nDEADLINE: %^{Deadline}T\n:PROPERTIES:\n:CREATED: %U\n:END:\n%?")
          
          ("p" "Project" entry
           (file+headline "~/Documents/Org/projects.org" "Projects")
           "* PROJ %^{Project name}\n:PROPERTIES:\n:CREATED: %U\n:END:\n** TODO %?")
          
          ("i" "Idea" entry
           (file+headline "~/Documents/Org/ideas.org" "Ideas")
           "** IDEA %^{Idea}\n:PROPERTIES:\n:CREATED: %U\n:CAPTURED: %a\n:END:\n%?")
          
          ("b" "Bookmark" entry
           (file+headline "~/Documents/Org/bookmarks.org" "Inbox")
           "** [[%^{URL}][%^{Title}]]\n:PROPERTIES:\n:CREATED: %U\n:TAGS: %(org-capture-bookmark-tags)\n:END:\n\n"
           :empty-lines 0)
          
          ("c" "Contact" entry
           (file+headline "~/Documents/Org/contacts.org" "Contacts")
           "* %(let ((name (read-string \"Name: \"))) (setq my-contact-name name) name)
:PROPERTIES:
:EMAIL: %(read-string \"Email: \")
:PHONE: %(read-string \"Phone: \")
:LOCATION: %(read-string \"Address: \")
%(let ((input (read-string \"Date of Birth (YYYY-MM-DD or Enter to skip): \")))
    (if (string-equal input \"\")
        \":BIRTHDAY: \n:END:\"
      (concat \":BIRTHDAY: \" input \"\n:END:\")))
%?")
          
          ("n" "Note" entry
           (file+headline "~/Documents/Org/notes.org" "Notes")
           "* [%<%Y-%m-%d %a>] %^{Title}\n:PROPERTIES:\n:CREATED: %U\n:END:\n%?"
           :prepend t))))

(use-package evil-org
  :after org
  :hook (org-mode . evil-org-mode)
  :config
  (evil-org-set-key-theme '(navigation insert textobjects additional calendar)))

(use-package org-modern
  :hook ((org-mode . org-modern-mode)
         (org-agenda-finalize . org-modern-agenda))
  :config
  (setq org-modern-label-border 3
        org-modern-star '("◉" "○" "◈" "◇" "✳")
        org-modern-list '((?- . "•") (?+ . "◦") (?* . "▸"))
        org-modern-table nil
        org-modern-timestamp nil))

(use-package org-contacts
  :after org
  :custom
  (org-contacts-files '("~/Documents/Org/contacts.org")))

(add-hook 'org-mode-hook 'visual-line-mode)

;; ============================================================================
;; GOOGLE CALENDAR INTEGRATION
;; ============================================================================

(use-package org-gcal
  ;; Credentials loaded from init-secrets.el
  :config
  (setq org-gcal-token-file "~/.emacs.d/.org-gcal-token"
        org-gcal-dir "~/.emacs.d/.org-gcal/"
        org-gcal-notify-p nil
        org-gcal-up-days 30
        org-gcal-down-days 30
        org-gcal-fetch-file-alist '(("ross@pearlstone.us" . "~/Documents/Org/gcal.org"))))

;; ============================================================================
;; ORG-ROAM
;; ============================================================================

(use-package org-roam
  :ensure t
  :custom
  (org-roam-directory "~/Documents/Org-Roam/")
  (org-roam-db-location "~/org-roam-db/org-roam.db")
  (org-roam-complete-everywhere t)
  :bind (("C-c n l" . org-roam-buffer-toggle)
         ("C-c n f" . org-roam-node-find)
         ("C-c n i" . org-roam-node-insert))
  :config
  (org-roam-db-autosync-mode))

(defun my/org-roam-delete-node ()
  "Delete the current org-roam note and update the database."
  (interactive)
  (when (yes-or-no-p "Delete this node? ")
    (delete-file (buffer-file-name))
    (kill-current-buffer)
    (org-roam-db-sync)))

;; ============================================================================
;; CALENDAR (CALFW)
;; ============================================================================

(use-package calfw
  :demand t)

(use-package calfw-org
  :demand t
  :after calfw)

;; ============================================================================
;; MARKDOWN
;; ============================================================================

(use-package markdown-mode
  :mode ("\\.md\\'" . markdown-mode)
  :config
  (setq markdown-fontify-code-blocks-natively t))

(use-package markdown-preview-mode)

(use-package olivetti
  :hook (markdown-mode . olivetti-mode)
  :config
  (setq olivetti-body-width 100))

(use-package mixed-pitch
  :hook (markdown-mode . mixed-pitch-mode))

;; ============================================================================
;; FILE BROWSER (DIRED)
;; ============================================================================

(use-package all-the-icons
  :if (display-graphic-p))

(use-package all-the-icons-dired)

(add-hook 'dired-mode-hook
          (lambda ()
            (all-the-icons-dired-mode 1)
            (dired-hide-details-mode 1)))

;; ============================================================================
;; DASHBOARD
;; ============================================================================

(use-package dashboard
  :config
  (dashboard-setup-startup-hook)
  (setq dashboard-startup-banner 'official
        dashboard-items '((recents . 5)
                          (projects . 5)))
  (setq initial-buffer-choice (lambda () (get-buffer-create "*dashboard*"))))

;;; init.el ends here

;; ============================================================================
;; CUSTOM FACES (Auto-generated - keep at end)
;; ============================================================================

(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(calfw-annotation-face ((t (:foreground "#5B6268" :slant italic))))
 '(calfw-day-title-face ((t (:background "#21242b"))))
 '(calfw-default-content-face ((t (:foreground "#c678dd" :background nil))))
 '(calfw-default-day-face ((t (:weight bold))))
 '(calfw-disable-face ((t (:foreground "#3f444a"))))
 '(calfw-grid-face ((t (:foreground "#3f444a"))))
 '(calfw-header-face ((t (:foreground "#98be65" :weight bold))))
 '(calfw-holiday-face ((t (:foreground "#ECBE7B" :weight bold))))
 '(calfw-periods-face ((t (:foreground "#c678dd" :background nil))))
 '(calfw-saturday-face ((t (:foreground "#c678dd" :weight bold))))
 '(calfw-sunday-face ((t (:foreground "#ff6c6b" :weight bold))))
 '(calfw-title-face ((t (:foreground "#51afef" :weight bold :height 2.0))))
 '(calfw-today-face ((t (:background "#2d333f" :weight bold))))
 '(calfw-today-title-face ((t (:background "#46D9FF" :foreground "#282c34" :weight bold))))
 '(calfw-toolbar-button-off-face ((t (:foreground "#5B6268"))))
 '(calfw-toolbar-button-on-face ((t (:foreground "#51afef" :weight bold))))
 '(calfw-toolbar-face ((t (:background "#21242b" :foreground "#51afef"))))
 '(cursor ((t (:background "#ff8c00"))))
 '(line-number ((t (:inherit default :foreground "#3E4451"))))
 '(line-number-current-line ((t (:foreground "#ff8c00" :weight normal))))
 '(org-code ((t (:foreground "#d0b03d" :weight normal))))
 '(org-date-selected ((t (:height 1.4 :foreground "light blue" :weight bold))))
 '(org-document-title ((t (:height 1.8 :weight bold :foreground "#BEA4DB"))))
 '(org-level-1 ((t (:inherit outline-1 :height 1.5 :weight extrabold :foreground "#d6837c"))))
 '(org-level-2 ((t (:inherit outline-2 :height 1.4 :weight bold :foreground "#8dcff0"))))
 '(org-level-3 ((t (:inherit outline-3 :height 1.3 :weight normal :foreground "#d555e0"))))
 '(org-level-4 ((t (:inherit outline-4 :height 1.2 :weight normal :foreground "#ff665c"))))
 '(org-level-5 ((t (:inherit outline-5 :height 1.1 :weight normal :foreground "#ababff"))))
 '(org-level-6 ((t (:inherit outline-6 :height 1.0 :weight normal :foreground "#5e65cc"))))
 '(org-level-7 ((t (:inherit outline-7 :height 1.0 :weight normal :foreground "#2843fb"))))
 '(org-level-8 ((t (:height 1.0 :weight normal :foreground "#ECBE7B"))))
 '(org-quote ((t (:foreground "#66b4e3" :slant italic))))
 '(org-scheduled ((t (:foreground "#51afef"))))
 '(org-scheduled-today ((t (:foreground "#98be65" :weight bold))))
 '(org-scheduled-previously ((t (:foreground "#ff6c6b" ))))  ; Burnt orange/pink
 '(org-upcoming-deadline ((t (:foreground "#ECBE7B"))))  ; Yellow (upcoming)
 '(org-warning ((t (:foreground "#d6837c" )))))  ; Burnt orange for overdue deadlines

(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(org-agenda-files
   '("/Users/rosspearlstone/Documents/Org/bookmarks.org"
     "/Users/rosspearlstone/Documents/Org/calendar.org"
     "/Users/rosspearlstone/Documents/Org/contacts.org"
     "/Users/rosspearlstone/Documents/Org/done.org"
     "/Users/rosspearlstone/Documents/Org/gcal.org"
     "/Users/rosspearlstone/Documents/Org/general.org"
     "/Users/rosspearlstone/Documents/Org/health.org"
     "/Users/rosspearlstone/Documents/Org/ideas.org"
     "/Users/rosspearlstone/Documents/Org/inbox.org"
     "/Users/rosspearlstone/Documents/Org/journal.org"
     "/Users/rosspearlstone/Documents/Org/notes.org"
     "/Users/rosspearlstone/Documents/Org/projects.org"
     "/Users/rosspearlstone/Documents/Org/rosspearl-gcal.org"
     "/Users/rosspearlstone/Documents/Org/todo.org"
     "/Users/rosspearlstone/Documents/Org/travel.org"))
 '(package-selected-packages
   '(all-the-icons-dired avy calfw-org cargo company-box consult
			 dashboard doom-modeline doom-themes
			 eglot-booster evil-collection evil-org
			 evil-surround general magit marginalia
			 markdown-preview-mode mixed-pitch olivetti
			 orderless org-contacts org-gcal org-modern
			 org-roam rust-mode treesit-auto vertico vterm
			 yasnippet-snippets))
 '(package-vc-selected-packages
   '((eglot-booster :url "https://github.com/jdtsmith/eglot-booster"))))
