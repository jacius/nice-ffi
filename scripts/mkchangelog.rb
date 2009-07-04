#!/bin/env ruby

# Constructs a ChangeLog from the git log.
# Strips out commit ids, since they might change (merge, rebase, etc.).

file = (ARGV[0] or "ChangeLog.txt")
`git log --name-status > #{file}.tmp`
`sed -e 's/^commit [0-9a-f]\\+$/#{"-"*60}/' #{file}.tmp > #{file}`
FileUtils.rm "#{file}.tmp"
