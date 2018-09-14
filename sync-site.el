;;; sync-up --- Set up synchronization with vm1

;;; Commentary:
;; A file to enable setup for synchronization upon save in my local
;; Emacs.  TRAMP could be used, but for working on projects, working
;; on a local copy is really better.

;;; Code:

(use-package auto-shell-command)
(let ((host (getenv "HOST"))
	  (dir (getenv "DIR"))
	  (this-dir (file-name-directory (buffer-file-name))))
  (when
	  (and (and host dir)
		   (not (assoc this-dir ascmd:setting)))
	(ascmd:add
	 (list this-dir
		   (concat "rsync -av --delete --exclude .git --exclude /mediawiki/images "
				   "--exclude /logs --exclude '*~' --exclude '#*#' "
				   this-dir " "
				   (concat host ":" dir))))))

(provide 'sync-site)
;;; sync-site ends here
