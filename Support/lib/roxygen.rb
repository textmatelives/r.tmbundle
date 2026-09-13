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

			m = prefix_match(line)
			unless m
				print e_sn(line[0...index].to_s) + "\n" + e_sn(line[index..-1].to_s) + "$0"
				return
			end

			prefix = m[1] + " "
			before = line[0...index]
			after = line[index..-1].to_s
			at_end = after.strip.empty?
			content = line.sub(/^(\s*#')\s*/, "")
			budget = [wrap_col - prefix.length, 20].max

			if at_end && content.length > budget
				lines = wrap_words(prefix, content, budget)
				print lines.map { |l| e_sn(l) }.join("\n") + "$0"
			else
				leftover = after.lstrip
				print e_sn(before.rstrip) + "\n" + prefix + e_sn(leftover) + "$0"
			end
		end
	end
end
