;;; emacs -- Emacs config
;;; Commentary:
;;;   My Emacs config, nuffin special
;;; Code:
(require 'package)

(menu-bar-mode -1)
(tool-bar-mode -1)

(add-to-list 'package-archives '("org" . "http://orgmode.org/elpa/"))
(add-to-list 'package-archives '("melpa" . "http://melpa.org/packages/"))
(add-to-list 'package-archives '("melpa-stable" . "http://stable.melpa.org/packages/"))

(setq package-enable-at-startup nil)

(defun ensure-package-installed (&rest packages)
  "Assure every package is installed, install if it’s not.

Return a list of installed packages or nil for every skipped package."
  (mapcar
   (lambda (package)
     (if (package-installed-p package)
         nil
       (package-install package)))
   packages))

;; Make sure to have downloaded archive description.
(or (file-exists-p package-user-dir)
    (package-refresh-contents))

;; Activate installed packages
(package-initialize)

;; Packages
(ensure-package-installed
                          'airline-themes
                          'base16-theme
                          'evil
                          'evil-leader
                          'evil-args
                          'evil-indent-textobject
                          ;'evil-matchit
                          'evil-numbers
                          'evil-surround
                          'elm-mode
                          'projectile
                          'magit
                          'neotree
                          'helm
                          'helm-ls-git
                          'helm-ag
                          'helm-descbinds
                          'helm-projectile
                          'helm-backup
                          'php-mode
                          'powerline-evil
                          'web-mode
                          'flycheck
                          'company
                          'smartparens
                          'git-gutter
                          'tramp
                          'quickrun
                          'expand-region
                          'restclient
                          'relative-line-numbers
                          'elixir-mode
                          'alchemist
                          'color-theme-solarized)

;; Theme
; (defvar my:theme 'solarized)
; (defvar my:theme-window-loaded nil)
; (defvar my:theme-terminal-loaded nil)

; (if (daemonp)
;     (add-hook 'after-make-frame-functions
;               (lambda (frame)
;                 (select-frame frame)
;                 (if (window-system frame)
;                     (unless my:theme-window-loaded
;                       (if my:theme-terminal-loaded
;                           (enable-theme my:theme)
;                         (load-theme my:theme t))
;                       (setq my:theme-window-loaded t))
;                   (unless my:theme-terminal-loaded
;                     (if my:theme-window-loaded
;                         (enable-theme my:theme)
;                       (load-theme my:theme t))
;                     (setq my:theme-terminal-loaded t)))))

;   (progn
;     (load-theme my:theme t)
;     (if (display-graphic-p)
;         (setq my:theme-window-loaded t)
;       (setq my:theme-terminal-loaded t))))
(load-theme 'base16-solarized-dark t)

(scroll-bar-mode -1)

(require 'powerline)
(powerline-evil-vim-color-theme)
(display-time-mode t)

(require 'airline-themes)
; (load-theme 'airline-solarized-alternate-gui)
; (load-theme 'airline-solarized-gui)
(load-theme 'airline-base16-gui-dark)

(require 'evil-leader)
(global-evil-leader-mode t)

(require 'evil-surround)
(global-evil-surround-mode t)

(require 'evil-numbers)
(define-key evil-normal-state-map (kbd "C-a") 'evil-numbers/inc-at-pt)
(define-key evil-normal-state-map (kbd "C-x") 'evil-numbers/dec-at-pt)

(require 'evil-args)
(define-key evil-inner-text-objects-map "a" 'evil-inner-arg)
(define-key evil-outer-text-objects-map "a" 'evil-outer-arg)

(require 'evil)
(evil-mode t)

;; Treat wrapped line scrolling as single lines
(define-key evil-normal-state-map (kbd "j") 'evil-next-visual-line)
(define-key evil-normal-state-map (kbd "k") 'evil-previous-visual-line)
;;; esc quits pretty much anything (like pending prompts in the minibuffer)
(define-key evil-normal-state-map [escape] 'keyboard-quit)
(define-key evil-visual-state-map [escape] 'keyboard-quit)
(define-key minibuffer-local-map [escape] 'minibuffer-keyboard-quit)
(define-key minibuffer-local-ns-map [escape] 'minibuffer-keyboard-quit)
(define-key minibuffer-local-completion-map [escape] 'minibuffer-keyboard-quit)
(define-key minibuffer-local-must-match-map [escape] 'minibuffer-keyboard-quit)
(define-key minibuffer-local-isearch-map [escape] 'minibuffer-keyboard-quit)

(define-key evil-normal-state-map (kbd "C-u") 'evil-scroll-up)
(evil-leader/set-leader "<SPC>")
(evil-leader/set-key
  "w" 'save-buffer
  "x" 'helm-M-x
  "r" 'neotree-find
  "ff" 'helm-projectile
  "fb" 'helm-buffers-list
  "fa" 'helm-projectile)

;; (evil-define-key 'normal neotree-mode-map (kbd "q") 'neotree-hide)
;; (evil-define-key 'normal neotree-mode-map (kbd "RET") 'neotree-enter)

(defun custom-neotree-enter-hide ()
  (interactive)
  (neotree-enter)
  (neotree-hide))

(add-hook 'neotree-mode-hook
    (lambda ()
        (evil-leader/set-key
            "r" 'neotree-toggle)
        (define-key evil-normal-state-local-map (kbd "q") 'neotree-hide)
        (define-key evil-normal-state-local-map (kbd "o") 'neotree-enter)
        (define-key evil-normal-state-local-map (kbd "RET")
            'custom-neotree-enter-hide)))

;; esc quits
(defun minibuffer-keyboard-quit ()
  "Abort recursive edit.
In Delete Selection mode, if the mark is active, just deactivate it;
then it takes a second \\[keyboard-quit] to abort the minibuffer."
  (interactive)
  (if (and delete-selection-mode transient-mark-mode mark-active)
      (setq deactivate-mark  t)
    (when (get-buffer "*Completions*") (delete-windows-on "*Completions*"))
    (abort-recursive-edit)))
(define-key evil-normal-state-map [escape] 'keyboard-quit)
(define-key evil-visual-state-map [escape] 'keyboard-quit)
(define-key minibuffer-local-map [escape] 'minibuffer-keyboard-quit)
(define-key minibuffer-local-ns-map [escape] 'minibuffer-keyboard-quit)
(define-key minibuffer-local-completion-map [escape] 'minibuffer-keyboard-quit)
(define-key minibuffer-local-must-match-map [escape] 'minibuffer-keyboard-quit)
(define-key minibuffer-local-isearch-map [escape] 'minibuffer-keyboard-quit)
(global-set-key [escape] 'evil-exit-emacs-state)

(require 'helm-config)
(helm-mode 1)
(global-set-key (kbd "M-x") 'helm-M-x)

(helm-descbinds-mode)

(require 'helm-backup)
(add-hook 'after-save-hook 'helm-backup-versioning)

(with-eval-after-load 'company
  (defvar company-active-map)
  (define-key company-active-map (kbd "C-n") #'company-select-next)
  (define-key company-active-map (kbd "C-p") #'company-select-previous))
(global-company-mode)

(global-flycheck-mode)


(defvar whitespace-display-mappings)
(setq whitespace-display-mappings '((space-mark ?\  [?⋅])
                                    (newline-mark ?\n [?¬ ?\n])
                                    (tab-mark ?\t [?▸ ?\t])))

(setq-default tab-width 4)
(setq-default indent-tabs-mode nil)
(require 'whitespace)
(global-whitespace-mode)

(defvar linum-format)
(setq linum-format "%3d ")
(global-linum-mode)

(global-git-gutter-mode +1)
;; (global-relative-line-numbers-mode)

(add-to-list 'auto-mode-alist '("\\.phtml\\'" . web-mode))
(add-to-list 'auto-mode-alist '("\\.tpl\\.php\\'" . web-mode))
(add-to-list 'auto-mode-alist '("\\.html\\.twig\\'" . web-mode))
(add-to-list 'auto-mode-alist '("\\.blade\\.php\\'" . web-mode))
(add-to-list 'auto-mode-alist '("\\.html?\\'" . web-mode))


(standard-display-ascii ?\t ">   ")
(setq withespace-newline "8")
(whitespace-mode t)
(setq whitespace-display-mappings '((space-mark ?\  [?.]) (newline-mark ?\n [?- ?\n]) (tab-mark ?\t [?\> ?\t])))

(show-paren-mode t)
(defvar show-paren-delay)
(setq show-paren-delay 0)
(defadvice show-paren-function
    (after show-matching-paren-offscreen activate)
  "If the matching paren is offscreen, show the matching line in the
        echo area. Has no effect if the character before point is not of
        the syntax class ')'."
  (interactive)
  (let* ((cb (char-before (point)))
         (matching-text (and cb
                             (char-equal (char-syntax cb) ?\) )
                             (blink-matching-open))))
    (when matching-text (message matching-text))))


(require 'smartparens-config)
(smartparens-global-mode)
(defun my-elixir-do-end-close-action (id action context)
  (when (eq action 'insert)
    (newline-and-indent)
    (previous-line)
    (indent-according-to-mode)))

(sp-with-modes '(elixir-mode)
  (sp-local-pair "do" "end"
                 :when '(("SPC" "RET"))
                 :post-handlers '(:add my-elixir-do-end-close-action)
                 :actions '(insert)))


(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(custom-safe-themes
   (quote
    ("8db4b03b9ae654d4a57804286eb3e332725c84d7cdab38463cb6b97d5762ad26" "d6db7498e2615025c419364764d5e9b09438dfe25b044b44e1f336501acd4f5b" "158013ec40a6e2844dbda340dbabda6e179a53e0aea04a4d383d69c329fba6e6" "73a13a70fd111a6cd47f3d4be2260b1e4b717dbf635a9caee6442c949fad41cd" "721bb3cb432bb6be7c58be27d583814e9c56806c06b4077797074b009f322509" "2b8dff32b9018d88e24044eb60d8f3829bd6bbeab754e70799b78593af1c3aba" "b181ea0cc32303da7f9227361bb051bbb6c3105bb4f386ca22a06db319b08882" "962dacd99e5a99801ca7257f25be7be0cebc333ad07be97efd6ff59755e6148f" default)))
 '(inhibit-startup-screen t)
 '(package-selected-packages
   (quote
    (airline-themes smart-mode-line-powerline-theme helm magit projectile evil))))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )
(provide '.emacs)
;;; .emacs ends here
