;;; sync-up --- Set up synchronization with vm1

;;; Commentary:
;; A file to enable setup for synchronization upon save in my local
;; Emacs.  TRAMP could be used, but for working on projects, working
;; on a local copy is really better.

;;; Code:

(use-package auto-shell-command)
(let ((this-dir (file-name-directory (buffer-file-name))))
  (ascmd:add
   (list this-dir
		 (concat "rsync -av --delete --exclude .git --exclude /mediawiki/images "
				 "--exclude /logs --exclude '*~' --exclude '#*#' "
				 this-dir " "
				 (concat (getenv "HOST") ":" (getenv "DIR") )))))

(provide 'sync-up)
;;; sync-up ends here
