;;; Package -- Summary

;;; Commentary:

;; need proper js code traversal
;; skewer uses js2 machinery in place of
;; generic (backward-sexp)


;;; Code:

(require 'comint)
(require 'nodejs-repl)


(defvar jslime-repl-buffer "*nodejs*")

(defun jslime--clean-region (start end)
  "Clean up object property lookup prepended by a newline"
  (let ((rx "\\(?:\\(
+[[:space:]]*\\)\\(\\.\\)\\)"))

    (replace-regexp-in-string rx
                              "\\2\\1"
                              (buffer-substring-no-properties start end))))

;;;###autoload
(defun jslime-send-region (start end)
  "Send the current region to the inferior Javascript process."
  (interactive "r")
  (comint-send-string jslime-repl-buffer
                      (concat (jslime--clean-region start end) "\n")))

;;;###autoload
(defun jslime-send-last-sexp ()
  "Send the previous sexp to the inferior Javascript process."
  (interactive)
  (jslime-send-region (save-excursion (backward-sexp) (point)) (point)))



;;;###autoload
(defun jslime-send-region-and-go (start end)
  "Send the current region to the inferior Javascript process."
  (interactive "r")
  (comint-send-string jslime-repl-buffer
                      (jslime--clean-region start end))
  (jslime-switch-to-repl jslime-repl-buffer))

;;;###autoload
(defun jslime-send-last-sexp-and-go ()
  "Send the previous sexp to the inferior Js process."
  (interactive)
  (jslime-send-region-and-go (save-excursion (backward-sexp) (point)) (point)))

;;;###autoload
(defun jslime-send-buffer-and-go ()
  "Send the buffer to the inferior Javascript process."
  (interactive)
  (let ((buf (current-buffer)))
    (jslime-restart-nodjs-repl)
    (with-current-buffer buf
      (jslime-send-region-and-go (point-min) (point-max)))))


;; ;;;###autoload
;; (defun jslime-send-buffer-and-go ()
;;   "Send the buffer to the inferior Javascript process."
;;   (interactive)
;;   (jslime-send-region-and-go (point-min) (point-max)))

;;;###autoload
(defun jslime-load-file (filename)
  "Load a file in the javascript interpreter."
  (interactive "f")
  (let ((filename (expand-file-name filename)))
    (comint-send-string jslime-repl-buffer (concat "require(\"" filename "\")\n"))))

;;;###autoload
(defun jslime-load-file-and-go (filename)
  "Load a file in the javascript interpreter."
  (interactive "f")
  (let ((filename (expand-file-name filename)))
    (comint-send-string jslime-repl-buffer (concat "require(\"" filename "\")\n"))
    (jslime-switch-to-repl jslime-repl-buffer)))

;;;###autoload
(defun jslime-switch-to-repl (eob-p)
  "Switch to the javascript process buffer.
With argument, position cursor at end of buffer."
  (interactive "P")

  (if (and jslime-repl-buffer (get-buffer jslime-repl-buffer))
      (pop-to-buffer jslime-repl-buffer)
    (error "No current process buffer.  See variable `jslime-repl-buffer'"))

  ;; (if (and jslime-repl-buffer (get-buffer jslime-repl-buffer))
  ;;     (display-buffer-reuse-window (get-buffer jslime-repl-buffer)
  ;;                                  '((reusable-frames . t)))
  ;;   ;; (pop-to-buffer jslime-repl-buffer)
  ;;   (error "No current process buffer.  See variable `jslime-repl-buffer'"))

  (when eob-p
    (push-mark)
    (goto-char (point-max))))

;;;###autoload
(defun jslime-restart-nodjs-repl ()
  "Start nodejs-repl."
  (interactive)
  (if (comint-check-proc jslime-repl-buffer)
      (progn
        (delete-process (get-buffer-process jslime-repl-buffer))
        (kill-buffer jslime-repl-buffer)))
  (nodejs-repl)
  (other-window 1))

(defvar jslime-mode-map
  (let ((m (make-sparse-keymap)))
    (define-key m (kbd "C-t C-e") 'jslime-send-last-sexp)
    (define-key m (kbd "C-M-t") 'jslime-send-last-sexp-and-go)
    ;; (define-key m (kbd "C-c C-r") 'jslime-send-region)
    (define-key m (kbd "C-c C-b") 'jslime-send-buffer-and-go)
    (define-key m (kbd "C-c C-z") 'jslime-restart-nodjs-repl)
    m))


(define-minor-mode jslime-mode
  "Minor mode for interacting with a nodejs."
  :lighter " jslime"
  :keymap jslime-mode-map
  :group 'jslime)

(provide 'jslime-mode)

;;; jslime ends here
