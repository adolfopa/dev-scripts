(load "~/.emacs.d/machine-settings.el")

(require 'cl)

;;;
;;; Custom functions
;;;

(defun reorder-exec-path ()
  "Reorder the values on exec-path so that the Emacs directory
takes precedence over the rest."
  (labels ((emacs-binary-dir-p (s)
			       (string-prefix-p "/Applications/Emacs.app" s))
	   (find-matching (p xs)
			  (loop for x in xs
				when (funcall p x)
				collect x)))
    (setq exec-path
	  (append (find-matching #'emacs-binary-dir-p exec-path)
		  (find-matching #'(lambda (x)
				     (not (emacs-binary-dir-p x)))
				 exec-path)))))

(defun ensure-package-installed (package)
  (unless (package-installed-p package)
    (package-install package)))



;;;
;;; General configuration
;;;

;; UI

(setq inhibit-splash-screen t
      inhibit-startup-message t
      inhibit-startup-echo-area-message t)

(tool-bar-mode -1)
(menu-bar-mode -1)
(scroll-bar-mode -1)

(set-default 'cursor-type 'box)

(fringe-mode 1)

(column-number-mode 1)

(add-hook 'prog-mode-hook (lambda () (linum-mode 1)))

;; Input

(setq mac-option-modifier nil
      mac-command-modifier 'meta
      x-select-enable-clipboard t)

;; Selection

(delete-selection-mode)

;; Emacs server

(server-start)

(when (eq system-type 'darwin)
  ;; On Mac OS X, override the execution path so that Emacs finds the
  ;; correct `emacsclient' binary.
  (reorder-exec-path))

;; Global key bindings

(global-set-key (kbd "C-<tab>") 'completion-at-point)
(global-set-key (kbd "M-=") 'count-words)
(global-set-key (kbd "<M-up>") 'backward-paragraph)
(global-set-key (kbd "<M-down>") 'forward-paragraph)
(global-set-key (kbd "C-º") 'toggle-input-method)

;; Whitespace and special character handling

(define-key global-map (kbd "RET") 'newline-and-indent)

(setq-default indent-tabs-mode nil)

(setq-default show-trailing-whitespace t)

(add-hook 'before-save-hook 'delete-trailing-whitespace)

;; Navigation

(define-key prog-mode-map "\C-x\C-n" #'forward-page)
(define-key prog-mode-map "\C-x\C-p" #'backward-page)

;; Misc

(add-to-list 'exec-path "/usr/local/bin")

(show-paren-mode 1)

(setq fill-column 80)

(global-prettify-symbols-mode)

(if (eq system-type 'darwin)
    (setq ring-bell-function 'ignore)
  (setq visible-bell t))

(defun show-buffer-file-name ()
  (interactive)
  (let ((name (buffer-file-name)))
    (if (zerop (length name))
        (message "This buffer is not associated with any file")
      (message name))))

(global-set-key (kbd "M-?") 'show-buffer-file-name)

(exec-path-from-shell-initialize)



;;;
;;; Package system
;;;

(require 'package)

(add-to-list 'package-archives
	     '("marmalade" . "http://marmalade-repo.org/packages/") t)
(add-to-list 'package-archives
	     '("melpa" . "http://melpa.org/packages/") t)

(package-initialize)



;;;
;;; Themes
;;;

(setq custom-theme-directory "~/.emacs.d/local/themes")
(setq custom-safe-themes t)

(ensure-package-installed 'reykjavik-theme)

(load-theme 'gruvbox t)



;;;
;;; Modes
;;;

;; Expand

(ensure-package-installed 'expand-region)

(require 'expand-region)

(global-set-key (kbd "<M-S-up>") 'er/expand-region)
(global-set-key (kbd "<M-S-down>") 'er/contract-region)

;; Nyan

(ensure-package-installed 'nyan-mode)

(nyan-mode)
(nyan-start-animation)

;; Shell

(setq explicit-shell-file-name zsh-program-name)
(setenv "SHELL" explicit-shell-file-name)

;; IDO mode

(require 'ido)

(ido-mode t)

(setq ido-enable-flex-matching t)
(setq ido-everywhere t)

;; Magit

(ensure-package-installed 'magit)

(global-set-key (kbd "C-c C-g") 'magit-status)

(setq magit-last-seen-setup-instructions "1.4.0")

;; Slime

(ensure-package-installed 'slime)

(setq inferior-lisp-program sbcl-program-name)

;; Org-Mode

(add-hook 'org-mode-hook 'flyspell-mode)
(add-hook 'org-mode-hook 'auto-fill-mode)

;; SML-Mode

(ensure-package-installed 'sml-mode)

(require 'smie)

(defun custom-sml-rules (orig kind token)
  (pcase (cons kind token)
    (`(:before . "d=")
     (if (smie-rule-parent-p "structure" "signature" "functor") 2
       (funcall orig kind token)))
    (`(:after . "struct") 2)
    (_ (funcall orig kind token))))

(add-hook 'sml-mode-hook
	  (lambda ()
	    (add-function :around (symbol-function 'sml-smie-rules)
                          #'custom-sml-rules)))

;; Haskell-Mode

(ensure-package-installed 'haskell-mode)

(require 'haskell-interactive-mode)
(require 'haskell-process)
(add-hook 'haskell-mode-hook 'interactive-haskell-mode)

(custom-set-variables
 '(haskell-mode-hook (quote (turn-on-haskell-indent interactive-haskell-mode)))
 '(haskell-process-auto-import-loaded-modules t)
 '(haskell-process-log t)
 '(haskell-process-suggest-remove-import-lines t)
 '(haskell-process-type (quote ghci)))

;; Dash / Zeal

(let ((pkg/fn
       (if (eq system-type 'darwin)
           'dash-at-point
         'zeal-at-point)))
  (ensure-package-installed pkg/fn)
  (global-set-key (kbd "C-c d") pkg/fn))

(when (package-installed-p 'zeal-at-point)
  (add-hook 'emacs-lisp-mode-hook
            (lambda ()
              (setq zeal-at-point-docset "emacs lisp")))
  (add-hook 'lisp-mode-hook
            (lambda ()
              (setq zeal-at-point-docset "common lisp"))))

;; Racket

(ensure-package-installed 'racket-mode)

(add-hook 'racket-mode-hook
          (lambda ()
            (add-hook 'before-save-hook 'racket-tidy-requires nil t)))

;; Scala / Ensime

(ensure-package-installed 'ensime)

(add-hook 'scala-mode-hook 'ensime-scala-mode-hook)

;; Markdown

(ensure-package-installed 'markdown-mode)

(add-hook 'markdown-mode-hook 'auto-fill-mode)

;; AG

(ensure-package-installed 'ag)

;; All C-like modes

(add-hook 'c-mode-common-hook
          (lambda () (subword-mode 1)))

;; Spotlight (OSX)

(when (eq system-type 'darwin)
  (ensure-package-installed 'spotlight))

;; Tuareg

(ensure-package-installed 'tuareg)

;; Helm

(ensure-package-installed 'helm)

(require 'helm-config)

(global-set-key (kbd "M-x") 'helm-M-x)

;; ARM mode

(define-derived-mode arm-mode asm-mode "ARM"
  "Major mode for editing ARM assembler code."
  (local-unset-key (vector asm-comment-char))
  (set (make-local-variable 'asm-comment-char) ?@)
  (local-set-key (vector asm-comment-char) 'asm-comment)
  (set-syntax-table (make-syntax-table asm-mode-syntax-table))
  (modify-syntax-entry asm-comment-char "< b")
  (set (make-local-variable 'comment-start) (string asm-comment-char)))

;; Octave

(setq auto-mode-alist
      (cons '("\\.m$" . octave-mode) auto-mode-alist))

(add-hook 'octave-mode-hook
          (lambda ()
            (abbrev-mode 1)
            (auto-fill-mode 1)
            (if (eq window-system 'x)
                (font-lock-mode 1))))
