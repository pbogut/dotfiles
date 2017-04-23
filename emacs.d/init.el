;;; emacs -- Emacs config
;;; Commentary:
;;;   My Emacs config, nuffin special
;;; Code:



(require 'package)
(menu-bar-mode -1)
(tool-bar-mode -1)

(fringe-mode -1)

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
                          ;'neotree
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


;; Customization settings
(setq custom-file "~/.emacs.d/custom.el")
(load custom-file)

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


(define-key helm-map [(control ?w)] #'backward-kill-word)

(require 'helm-backup)
(add-hook 'after-save-hook 'helm-backup-versioning)

(with-eval-after-load 'company
  (defvar company-active-map)
  (define-key company-active-map (kbd "C-n") #'company-select-next)
  (define-key company-active-map (kbd "C-p") #'company-select-previous))
(global-company-mode)

(global-flycheck-mode)



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


; (standard-display-ascii ?\t ">   ")
; (setq withespace-newline "8")

; (defvar whitespace-display-mappings)
; (setq whitespace-display-mappings '((space-mark ?\  [?⋅])
;                                     (newline-mark ?\n [?¬ ?\n])
;                                     (tab-mark ?\t [?▸ ?\t])))
(setq whitespace-display-mappings '((space-mark ?\  [? ])
                                    (newline-mark ?\n [?¬ ?\n])
                                    (tab-mark ?\t [?▸ ?\t])))


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



