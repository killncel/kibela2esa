require 'fileutils'

all_markdown = Dir.glob('./tmp/kibela-bankinc-*/**/*.md')
# pp all_markdown
# all_markdown.each do |path|
#   file = File.open(path)
#   pp file.read
# end

first_md = all_markdown.first
category = first_md.gsub(/\.\/tmp\/kibela-bankinc-[0-9]+\//, "")
pp category
pp File.open(first_md).read
