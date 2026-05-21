;; early-init.el
;; Runs BEFORE the first frame is created.
;; This is the only place to set frame properties without a visual jerk.

(setq frame-resize-pixelwise t)

(setq default-frame-alist '((undecorated . nil)
                             (fullscreen . maximized)))

(setq initial-frame-alist '((undecorated . nil)
                             (fullscreen . maximized)))

;; Suppress the toolbar and scrollbar early so they don't flash briefly
(push '(tool-bar-lines . 0) default-frame-alist)
(push '(menu-bar-lines . 0) default-frame-alist)
(push '(vertical-scroll-bars . nil) default-frame-alist)
