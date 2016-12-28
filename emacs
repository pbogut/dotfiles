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
(ensure-package-installed 'evil
                          'evil-leader
                          'evil-args
                          'evil-indent-textobject
                          ;'evil-matchit
                          'evil-numbers
                          'evil-surround
                          'projectile
                          'magit
                          'helm
                          'helm-ls-git
                          'helm-ag
                          'helm-descbinds
                          'helm-projectile
                          'helm-backup
                          'php-mode
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
(defvar my:theme 'solarized)
(defvar my:theme-window-loaded nil)
(defvar my:theme-terminal-loaded nil)
(if (daemonp)
    (add-hook 'after-make-frame-functions
              (lambda (frame)
                (select-frame frame)
                (if (window-system frame)
                    (unless my:theme-window-loaded
                      (if my:theme-terminal-loaded
                          (enable-theme my:theme)
                        (load-theme my:theme t))
                      (setq my:theme-window-loaded t))
                  (unless my:theme-terminal-loaded
                    (if my:theme-window-loaded
                        (enable-theme my:theme)
                      (load-theme my:theme t))
                    (setq my:theme-terminal-loaded t)))))

  (progn
    (load-theme my:theme t)
    (if (display-graphic-p)
        (setq my:theme-window-loaded t)
      (setq my:theme-terminal-loaded t))))
(load-theme my:theme t)

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


(define-key evil-normal-state-map (kbd "C-u") 'evil-scroll-up)
(evil-leader/set-leader "<SPC>")
(evil-leader/set-key
  "w" 'save-buffer
  "x" 'helm-M-x
  "ff" 'helm-projectile
  "fb" 'helm-buffers-list
  "fa" 'helm-projectile)

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
 '(inhibit-startup-screen t)
 '(package-selected-packages (quote (helm magit projectile evil))))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )
(provide '.emacs)
;;; .emacs ends here
