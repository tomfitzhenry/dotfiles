function svncd
	svn up --set-depth=immediates $argv; and cd "$argv[1]"
end
