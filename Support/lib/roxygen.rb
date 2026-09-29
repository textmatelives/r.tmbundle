# Roxygen line break / wrap, modeled on Markdown::List#break (Rtim).
# Ctrl-Return on a #' line continues with #'  or reflows a long line.

module Roxygen
	module Line
		module_function

		def prefix_match(line)
			line.match(/^(\s*#')(\s*)/)
		end

		def wrap_words(prefix, text, budget)
			words = text.split(/\s+/)
			return [prefix.rstrip] if words.empty?
			lines = []
			cur = []
			words.each do |w|
				trial = (cur + [w]).join(" ")
				if !cur.empty? && trial.length > budget
					lines << prefix + cur.join(" ")
					cur = [w]
				else
					cur << w
				end
			end
			lines << prefix + cur.join(" ") unless cur.empty?
			lines
		end

		# Returns the broken line with a caret marker at the split.
		# A caret inside the #' prefix is treated as the end of that prefix,
		# so the prefix is not copied onto the new line.
		def break_text(line, index, wrap_col)
			m = prefix_match(line)
			unless m
				left = line[0...index].to_s
				right = line[index..-1].to_s
				return left + "\n" + "\0" + right
			end

			prefix = m[1] + " "
			index = m[0].length if index <= m[0].length
			before = line[0...index]
			after = line[index..-1].to_s
			at_end = after.strip.empty?
			content = line.sub(/^(\s*#')\s*/, "")
			budget = [wrap_col - prefix.length, 20].max

			if at_end && content.length > budget
				wrap_words(prefix, content, budget).join("\n") + "\0"
			else
				before.rstrip + "\n" + prefix + "\0" + after.lstrip
			end
		end

		def break_or_wrap
			require ENV["TM_SUPPORT_PATH"] + "/lib/escape.rb"

			line = ENV["TM_CURRENT_LINE"].to_s.chomp
			# TM_LINE_INDEX is UTF-8 bytes; Ruby 2 indexes by character.
			n = ENV["TM_LINE_INDEX"].to_i
			index = if n <= 0
				0
			elsif n >= line.bytesize
				line.length
			else
				line.byteslice(0, n).length
			end
			wrap_col = (ENV["TM_COLUMNS"] || ENV["TM_WRAP_COLUMN"] || 80).to_i
			parts = break_text(line, index, wrap_col).split("\0", -1)
			print parts.map { |part| e_sn(part) }.join("$0")
		end
	end
end
