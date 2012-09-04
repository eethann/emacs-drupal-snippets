(defun process-hook-file (fPath outDir)
  "Process and API file, extracting each hook"
  (with-temp-buffer
    (insert-file-contents fPath)
    (goto-char (point-min))
    (while (re-search-forward "/\\*\\*[^/]*?\\*/\nfunction \\(hook_.*?\\)([[:ascii:]]*?\n}\n" nil t)
      (let (hookDef
	    hookName
	    snipFile
	    (module-name-code "${1:`(file-name-nondirectory (file-name-sans-extension (buffer-file-name)))`}"))
	;; extract the hook name from the function definition
	(setq hookName (match-string 1))
	(setq hookDef (match-string 0))
	(with-temp-buffer
	  (insert (concat
		   "# -*- mode: snippet -*-
# name: " hookName "
# key: " hookName "
# --
" hookDef))
	  (goto-char (point-min))
	  (replace-regexp "^function hook_" (concat "function " module-name-code "_"))
	  (goto-char (point-min))
	  (replace-regexp "/\\*\\*\n \\* \\([[:ascii:]]*?\\)\n \\(\\*/\\|\\* @\\)"
			  "/**\n * ${2:\\1}\n \\2")
	  (replace-regexp "\\(^ *function.*{\n\\)"
			  "\\1$0")
	  (setq snipFile (concat outDir hookName))
	  (when (file-writable-p snipFile)
	    (write-region (point-min)
			  (point-max)
			  snipFile))
	  )
	)
      )
    )
  )

(defun process-hook-dir (inDir outDir)
  "Process a module-builder created directory with hook doc files"
  (let ((dir (directory-file-name inDir))
	(files (directory-files inDir nil nil t)))
    (dolist (file files)
      (unless (member file '("." ".."))
	(process-hook-file (concat inDir "/" file) outDir)
	)
      )
    )
  )

;; Example snippet processor invocation:
(process-hook-dir "~/Sites/d7.dev/sites/default/files/hooks" "~/.emacs.d/mysnippets/drupal-mode/")
