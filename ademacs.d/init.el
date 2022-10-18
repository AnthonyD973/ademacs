;;; Much of the config taken from
;;; https://github.com/daviwil/emacs-from-scratch/blob/master/init.el

;; Create dir specific to flag files that indicate whether some action has been
;; performed already
(setq ade/flag-dir (concat user-emacs-directory "/ade-flags"))
(unless (file-directory-p ade/flag-dir) (mkdir ade/flag-dir t))

;; Load temporary theme while the real theme is being downloaded
;; or loaded. I don't like to be blinded!
(load-theme 'wombat)

(setq inhibit-startup-message t)

(if (display-graphic-p)
    (progn
      ;; Disable visible scrollbar
      (scroll-bar-mode -1)
      ;; Disable the toolbar
      (tool-bar-mode -1)
      ;; Disable tooltips
      (tooltip-mode -1)
      ;; Give some breathing room
      (set-fringe-mode 10)))

;; Disable menu bar that appears in both graphic and headless modes
(menu-bar-mode -1)

(setq visible-bell t)

;; Start emacs maximized
(add-hook 'emacs-startup-hook 'toggle-frame-fullscreen)

;; Font && font size
(if (eq system-type 'windows-nt)
  (progn (set-face-attribute 'default nil :height 190 :weight 'normal :font "Consolas"))
  (progn (set-face-attribute 'default nil :height 190 :weight 'normal)))

;; Don't add the annoying Custom line things in this file; add
;; them to a separate file
(setq custom-file (concat user-emacs-directory "/custom.el"))

(column-number-mode)
(global-display-line-numbers-mode t)
(set-default-coding-systems 'utf-8)
(setq-default tab-width 4)

;; Don't show line number in certain modes
(dolist (mode '(org-mode-hook
                term-mode-hook
                shell-mode-hook
                treemacs-mode-hook
                eshell-mode-hook))
  (add-hook mode (lambda () (display-line-numbers-mode 0))))

;; Need package stuff for use-package!
(require 'package)
(setq package-archives '(("melpa" . "https://melpa.org/packages/")
                         ("org" . "https://orgmode.org/elpa/")
                         ("elpa" . "https://elpa.gnu.org/packages/")))
;; Put the packages inside the current emacs dir, not the default one.
(setq package-user-dir (concat user-emacs-directory "/packages"))
(package-initialize)
;; Only do that on initial package setup
(unless package-archive-contents (package-refresh-contents))
;; For non-Linux platforms apparently...
(unless (package-installed-p 'use-package) (package-install 'use-package))

(require 'use-package)
;; Always ensure packages loaded by use-package is downloaded
(setq use-package-always-ensure t)

(setq ade/all-the-icons-install-fonts-flag-path
	  (concat ade/flag-dir "/all-the-icons-install-fonts"))

;; Taken from all-the-icons package
(defun ade/all-the-icons-install-fonts-windows ()
 "Helper function to download and install the latests fonts on Windows."
 (interactive)
 (let* ((url-format "https://raw.githubusercontent.com/domtronn/all-the-icons.el/master/fonts/%s")
        (font-dest (cond
		            ((eq system-type 'windows-nt)
					 (concat user-emacs-directory "/fonts-to-install"))))
        (known-dest? (stringp font-dest))
		(progn (if (not font-dest)
				   (error "Running %s on system other than Windows NT"
						  (get-current-function-name)))))

   (unless (file-directory-p font-dest) (mkdir font-dest t))

   (mapc (lambda (font)
           (url-copy-file (format url-format font) (expand-file-name font font-dest) t))
         all-the-icons-font-names)
   (when (yes-or-no-p
		  (format "Please manually install fonts in %s. Did install succeed? " font-dest))
     (message "%s Successfully %s `all-the-icons' fonts to `%s'!"
              (all-the-icons-wicon "stars" :v-adjust 0.0)
              (if known-dest? "installed" "downloaded")
              font-dest))))

(defun ade/all-the-icons-install-fonts ()
  (interactive)
  (unless (file-exists-p ade/all-the-icons-install-fonts-flag-path)
	(progn (if (not (eq system-type 'windows-nt))
			   ;; Don't prompt for fonts install on Linux and MacOS.
			   (all-the-icons-install-fonts t)
			 (ade/all-the-icons-install-fonts-windows))
		   (make-empty-file ade/all-the-icons-install-fonts-flag-path))))

;; Needed by doom-modeline
(use-package all-the-icons
  :if (display-graphic-p)
  :config
  (ade/all-the-icons-install-fonts))

(use-package ivy
  :diminish
  :bind (("C-s" . swiper)
    :map ivy-minibuffer-map
    ("TAB" . ivy-alt-done)
    ("C-l" . ivy-alt-done)
    ("C-j" . ivy-next-line)
    ("C-k" . ivy-previous-line)
    :map ivy-switch-buffer-map
    ("C-k" . ivy-previous-line)
    ("C-l" . ivy-done)
    ("C-d" . ivy-switch-buffer-kill)
    :map ivy-reverse-i-search-map
    ("C-k" . ivy-previous-line)
    ("C-d" . ivy-reverse-i-search-kill))
  :config
  (ivy-mode 1))

;; Counsel package is used by ivy-rich; ivy-rich doesn't seem to work without it
(use-package counsel
  :bind (("M-x" . counsel-M-x)
	 ("C-x b" . counsel-ibuffer)
	 ("C-x C-f" . counsel-find-file)
	 ("C-M-j" . counsel-switch-buffer)
	 :map minibuffer-local-map ("C-r" . 'counsel-minibuffer-history))
  :custom (ivy-initial-inputs-alist nil)) ; Don't start searches with "^"

;; When some text is selected and we type some other text, the selected text is
;; removed first. Not particularly useful since we use Evil mode, but oh well.
(use-package delsel
  :config (delete-selection-mode 1))

(use-package ivy-rich
  :init (ivy-rich-mode 1))

;; https://github.com/seagle0128/doom-modeline/issues/187#issuecomment-507201556
(defun ade/doom-modeline-height ()
  "Calculate the actual char height of the mode-line."
  (- (frame-char-height) 8))

(use-package doom-modeline
  :after all-the-icons
  :init (doom-modeline-mode 1)
  :config
  (advice-add #'doom-modeline--font-height :override #'ade/doom-modeline-height))

(use-package doom-themes
  :init (load-theme 'doom-dark+ t))

(use-package rainbow-delimiters
  :hook (prog-mode . rainbow-delimiters-mode))

;; To show available keybindings when using a hierarchical keybinding
(use-package which-key
  :init (which-key-mode)
  :diminish which-key-mode
  :custom (which-key-idle-delay 0.3))

(use-package helpful
  :custom
  (counsel-describe-function-function #'helpful-callable)
  (counsel-describe-variable-function #'helpful-variable)
  :bind
  ;; 'remap' thing apparently returns the string representing the keybinding that
  ;; binds given function
  ([remap describe-function] . counsel-describe-function)
  ([remap describe-command] . helpful-command)
  ([remap describe-variable] . counsel-describe-variable)
  ([remap describe-key] . helpful-key))

(use-package general)

(use-package hydra)

(use-package undo-tree
  :ensure t
  :after evil
  :diminish
  :config
  (evil-set-undo-system 'undo-tree)
  (global-undo-tree-mode 1))

;; Somehow, adding this to the :init of evil still triggers a warning on the
;; first time emacs is run, so just set that before evil and evil-collection
;; are ever mentioned.
(setq evil-want-keybinding nil)

(use-package evil-collection
  :after evil
  :config
  (evil-collection-init))

(defhydra ade/evil-window-size-change (:timeout 4)
  "Resize current window"
  ("a" evil-window-decrease-width "- width")
  ("f" evil-window-increase-width "+ width")
  ("s" evil-window-decrease-height "- height")
  ("d" evil-window-increase-height "+ height"))

(general-create-definer ade/evil-window-mgt-leader-def
  :prefix "C-w")

;; I don't really care about Vim compatibility -- I don't use Vim. All I want
;; is modal editing. So remove all Evil keybindings. I'll make my own
;; afterwards. My keybindings are more about where the buttons are on the
;; keyboard than about the name of the functionality, altough I do insipre
;; myself from the default keybindings too.
;;
;; TODO See if we could iterate on the evil keymaps instead of hardcoding
;; all the keybindings.
(defun ade/remove-evil-keybindings ()
  (interactive)
  (progn
    (general-unbind 'motion
      "!"
      "#"
      "$"
      "%"
      "'"
      "("
      ")"
      "*"
      "+"
      ","
      "-"
      "/"
      "0"
      "1"
      "2"
      "3"
      "4"
      "5"
      "6"
      "7"
      "8"
      "9"
      ":"
      ";"
      "<down-mouse-1>"
      "<down>"
      "<end>"
      "<home>"
      "<left>"
      "<right>"
      "<up>"
      "?"
      "B"
      "C-6"
      "C-]"
      "C-^"
      "C-b"
      "C-d"
      "C-e"
      "C-f"
      "C-g"
      "C-o"
      "C-v"
      "C-w +"
      "C-w -"
      "C-w :"
      "C-w <"
      "C-w <down>"
      "C-w <left>"
      "C-w <right>"
      "C-w <up>"
      "C-w ="
      "C-w >"
      "C-w C-<down>"
      "C-w C-<left>"
      "C-w C-<right>"
      "C-w C-<up>"
      "C-w C-S-h"
      "C-w C-S-j"
      "C-w C-S-k"
      "C-w C-S-l"
      "C-w C-S-r"
      "C-w C-S-s"
      "C-w C-S-w"
      "C-w C-_"
      "C-w C-b"
      "C-w C-c"
      "C-w C-f"
      "C-w C-h"
      "C-w C-j"
      "C-w C-k"
      "C-w C-l"
      "C-w C-n"
      "C-w C-o"
      "C-w C-p"
      "C-w C-q"
      "C-w C-r"
      "C-w C-s"
      "C-w C-t"
      "C-w C-v"
      "C-w C-w"
      "C-w C-x"
      "C-w H"
      "C-w J"
      "C-w K"
      "C-w L"
      "C-w R"
      "C-w S"
      "C-w W"
      "C-w _"
      "C-w b"
      "C-w c"
      "C-w f"
      "C-w g T"
      "C-w g t"
      "C-w h"
      "C-w j"
      "C-w k"
      "C-w l"
      "C-w n"
      "C-w o"
      "C-w p"
      "C-w q"
      "C-w r"
      "C-w s"
      "C-w t"
      "C-w v"
      "C-w w"
      "C-w x"
      "C-w |"
      "C-y"
      "C-z"
      "E"
      "F"
      "G"
      "H"
      "K"
      "L"
      "M"
      "N"
      "RET"
      "SPC"
      "SPC..~"
      "T"
      "TAB"
      "V"
      "W"
      "Y"
      "[ '"
      "[ ("
      "[ ["
      "[ ]"
      "[ `"
      "[ s"
      "[ {"
      "\\"
      "] '"
      "] )"
      "] ["
      "] ]"
      "] `"
      "] s"
      "] }"
      "^"
      "_"
      "`"
      "b"
      "e"
      "f"
      "g #"
      "g $"
      "g *"
      "g 0"
      "g <down>"
      "g <end>"
      "g <home>"
      "g <up>"
      "g C-]"
      "g E"
      "g M"
      "g N"
      "g ^"
      "g _"
      "g d"
      "g e"
      "g g"
      "g j"
      "g k"
      "g m"
      "g n"
      "g o"
      "g v"
      "h"
      "j"
      "k"
      "l"
      "n"
      "t"
      "v"
      "w"
      "y"
      "z +"
      "z -"
      "z ."
      "z <left>"
      "z <return>"
      "z <right>"
      "z H"
      "z L"
      "z RET"
      "z ^"
      "z b"
      "z h"
      "z l"
      "z t"
      "z z"
      "{"
      "|"
      "}")
    (general-unbind 'normal
      "\""
      "&"
      "."
      "<"
      "<deletechar>"
      "<escape>"
      "<insert>"
      "<insertchar>"
      "<mouse-2>"
      "="
      ">"
      "@"
      "A"
      "C"
      "C-."
      "C-n"
      "C-p"
      "C-r"
      "C-t"
      "D"
      "DEL"
      "I"
      "J"
      "M-."
      "M-y"
      "O"
      "P"
      "R"
      "S"
      "X"
      "Y"
      "Z Q"
      "Z Z"
      "[ F"
      "[ f"
      "] F"
      "] f"
      "a"
      "c"
      "d"
      "g &"
      "g ,"
      "g 8"
      "g ;"
      "g ?"
      "g F"
      "g I"
      "g J"
      "g P"
      "g T"
      "g U"
      "g a"
      "g f"
      "g i"
      "g p"
      "g q"
      "g t"
      "g u"
      "g w"
      "g x"
      "g ~"
      "i"
      "m"
      "o"
      "p"
      "q"
      "r"
      "s"
      "u"
      "x"
      "y"
      "z ="
      "z O"
      "z a"
      "z c"
      "z m"
      "z o"
      "z r"
      "~")
    (general-unbind 'insert
      "<delete>"
      "<escape>"
      "<insert>"
      "<mouse-2>"
      "C-@"
      "C-a"
      "C-d"
      "C-e"
      "C-g"
      "C-k"
      "C-n"
      "C-o"
      "C-p"
      "C-q"
      "C-r"
      "C-t"
      "C-v"
      "C-w"
      "C-x C-n"
      "C-x C-p"
      "C-y"
      "C-z"
      "DEL")
    (general-unbind 'replace
      "<escape>"
      "<insert>"
      "<mouse-2>"
      "C-@"
      "C-a"
      "C-d"
      "C-e"
      "C-k"
      "C-n"
      "C-o"
      "C-p"
      "C-q"
      "C-r"
      "C-t"
      "C-v"
      "C-w"
      "C-x C-n"
      "C-x C-p"
      "C-y"
      "DEL")
    (general-unbind 'visual
      "<escape>"
      "<insert>"
      "<insertchar>"
      "<mouse-2>"
      "A"
      "C-g"
      "I"
      "O"
      "R"
      "U"
      "a \""
      "a '"
      "a ("
      "a )"
      "a <"
      "a >"
      "a B"
      "a W"
      "a ["
      "a ]"
      "a `"
      "a b"
      "a o"
      "a p"
      "a s"
      "a t"
      "a w"
      "a {"
      "a }"
      "g f"
      "i \""
      "i '"
      "i ("
      "i )"
      "i <"
      "i >"
      "i B"
      "i W"
      "i ["
      "i ]"
      "i `"
      "i b"
      "i o"
      "i p"
      "i s"
      "i t"
      "i w"
      "i {"
      "i }"
      "o"
      "u"
      "z =")))

(defun ade/add-custom-evil-keybindings ()
  (interactive)

  ;; C-g is like "quit"; it makes us go back to normal mode. Easy to hit!
  (general-def 'motion "C-g" 'evil-normal-state)
  (general-def 'insert "C-g" 'evil-normal-state)
  (general-def 'replace "C-g" 'evil-normal-state)
  ;; Need access to emacs state in case evil ever betrays me.
  (general-def 'motion "C-z" 'evil-emacs-state)
  (general-def 'insert "C-z" 'evil-emacs-state)
  (general-def 'replace "C-z" 'evil-emacs-state)
  ;; Keeping <escape> seems to be a Vim doctrine, so let's keep it.
  (general-def 'motion  "<escape>" 'evil-normal-state)
  (general-def 'insert "<escape>" 'evil-normal-state)
  (general-def 'replace "<escape>" 'evil-normal-state)

  ;; Movement and going back to normal state is generally with left hand
  ;; whereas changing modes, inserting and special commands (e.g. kill, yank)
  ;; usually with right hand.
  (general-def 'motion ":"   'evil-ex) ; Vim execute command thing.
  (general-def 'motion "a"   'evil-backward-char)
  (general-def 'motion "f"   'evil-forward-char)
  (general-def 'motion "s"   'evil-previous-visual-line)
  (general-def 'motion "d"   'evil-next-visual-line)
  (general-def 'motion "k"   'evil-insert)
  (general-def 'motion "K"   'evil-insert-line)
  (general-def 'motion "l"   'evil-append)
  (general-def 'motion "L"   'evil-append-line)
  (general-def 'motion "w"   'evil-backward-word-begin)
  (general-def 'motion "e"   'evil-forward-word-end)
  (general-def 'motion "W"   'evil-backward-WORD-begin)
  (general-def 'motion "E"   'evil-forward-WORD-end)
  (general-def 'motion "q"   'evil-beginning-of-visual-line)
  (general-def 'motion "r"   'evil-end-of-visual-line)
  (general-def 'motion "Q"   'beginning-of-buffer)
  (general-def 'motion "R"   'end-of-buffer)
  (general-def 'motion "x"   'scroll-down)
  (general-def 'motion "c"   'scroll-up)
  (general-def 'motion "X"   (lambda () (interactive) (scroll-down 1)))
  (general-def 'motion "C"   (lambda () (interactive) (scroll-up 1)))
  (general-def 'motion "h"   'evil-visual-char)
  (general-def 'motion "H"   'evil-visual-line)
  (general-def 'motion "M-h" 'evil-visual-block)
  (general-def 'motion "t"   'evil-jump-item)
  (ade/evil-window-mgt-leader-def 'motion "a"   'evil-window-left)
  (ade/evil-window-mgt-leader-def 'motion "f"   'evil-window-right)
  (ade/evil-window-mgt-leader-def 'motion "s"   'evil-window-up)
  (ade/evil-window-mgt-leader-def 'motion "d"   'evil-window-down)
  (ade/evil-window-mgt-leader-def 'motion "q"   'evil-quit)
  (ade/evil-window-mgt-leader-def 'motion "C-q" 'evil-quit)
  (ade/evil-window-mgt-leader-def 'motion "w"   'evil-window-split)
  (ade/evil-window-mgt-leader-def 'motion "e"   'evil-window-vsplit)
  (ade/evil-window-mgt-leader-def 'motion "C-w" 'evil-window-split)
  (ade/evil-window-mgt-leader-def 'motion "C-e" 'evil-window-vsplit)
  (ade/evil-window-mgt-leader-def 'motion "r"   'ade/evil-window-size-change/body)
  (ade/evil-window-mgt-leader-def 'motion "C-r" 'ade/evil-window-size-change/body)

  (general-def 'normal "k"   'evil-insert)
  (general-def 'normal "K"   'evil-insert-line)
  (general-def 'normal "l"   'evil-append)
  (general-def 'normal "L"   'evil-append-line)
  (general-def 'normal "j"   'evil-visual-char)
  (general-def 'normal "J"   'evil-visual-line)
  (general-def 'normal "M-j" 'evil-visual-block)
  (general-def 'normal "h"   'evil-replace)
  (general-def 'normal "H"   'evil-enter-replace-state)
  (general-def 'normal "u"   'evil-undo) ; C-z on Linux
  (general-def 'normal "U"   'evil-redo) ; C-Z on Linux, so uppercase makes sense
  (general-def 'normal "p"   'evil-paste-before)
  (general-def 'normal "P"   'evil-paste-after)
  (general-def 'normal "n"   'evil-delete-backward-char)
  (general-def 'normal "N"   'evil-delete-whole-line)
  (general-def 'normal "m"   'evil-delete-char)
  (general-def 'normal "M"   'evil-delete-whole-line)

  (general-def '(insert replace) "C-a" 'evil-backward-char)
  (general-def '(insert replace) "C-f" 'evil-forward-char)
  ;; Already mapped to search command
  ;; (general-def '(insert replace) "C-s" 'evil-previous-visual-line)
  (general-def '(insert replace) "C-d" 'evil-next-visual-line)
  (general-def '(insert replace) "C-u" 'evil-undo)
  (general-def '(insert replace) "C-U" 'evil-redo)
  ;; Already in insert/replace state so C-k should go to beginning of line
  (general-def '(insert replace) "C-k" 'evil-insert-line)
  (general-def '(insert replace) "C-K" 'evil-insert-line)
  ;; Already in insert/replace state so C-l should go to end of line
  (general-def '(insert replace) "C-l" 'evil-append-line)
  (general-def '(insert replace) "C-L" 'evil-append-line)
  ;; <return> maps to C-m, so rebinding C-m looks like a can of worms:
  ;; http://makble.com/rebind-ctrlm-and-enter-in-emacs
  ;;
  ;; (general-def '(insert replace) "C-n" 'evil-delete-backward-char)
  ;; (general-def '(insert replace) "C-N" 'evil-delete-whole-line)
  ;; (general-def '(insert replace) "C-m" 'evil-delete-char)
  ;; (general-def '(insert replace) "C-M" 'evil-delete-whole-line)
  ;;
  ;; C-w is already mapped to window management
  ;; (general-def '(insert replace) "C-w" 'evil-backward-word-begin)
  ;; (general-def '(insert replace) "C-W" 'evil-backward-WORD-begin)
  ;; (general-def '(insert replace) "C-e" 'evil-forward-word-begin)
  ;; (general-def '(insert replace) "C-E" 'evil-forward-WORD-begin)
  (general-def '(insert replace) "C-p" 'evil-paste-before)
  (general-def '(insert replace) "C-P" 'evil-paste-after)

  (general-def 'visual ";"   'comment-dwim) ; I do that often!
  (general-def 'visual "h"   'evil-visual-char)
  (general-def 'visual "H"   'evil-visual-line)
  (general-def 'visual "M-h" 'evil-visual-block)
  (general-def 'visual "o"   'kill-ring-save)
  (general-def 'visual "O"   'kill-region)
  ;; "a" seems to be overridden by its nil keybindings, causing it
  ;; to be considered a prefix keybinding, so forcefully set that!
  (general-def 'visual "a"   'evil-backward-char)
  (general-def 'visual "u"   'evil-downcase)
  (general-def 'visual "U"   'evil-upcase))

(use-package evil
  :custom
  ;; Apparently needed with evil-collection
  (evil-want-integration t)
  ;; Apparently also needed with evil-collection
  (evil-want-keybinding nil)
  ;; Hitting "." shouldn't move the cursor (normally repeats last command)
  (evil-repeat-move-cursor nil)
  ;; Exiting insert mode shouldn't move the cursor one char back
  (evil-move-cursor-back nil)
  ;; evil-forward/backward-char can move to the EOL character. Like, seriously.
  (evil-move-beyond-eol t)
  ;; evil-forward/backward-char can move accross lines
  (evil-cross-lines t)

  :config

  (evil-mode 1)

  (ade/remove-evil-keybindings)
  (ade/add-custom-evil-keybindings))

