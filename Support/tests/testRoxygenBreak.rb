require 'test/unit'
require '../lib/roxygen.rb'

# Port of the /tmp verification battery: drives Roxygen::Line.break_text
# directly. break_text takes a CHARACTER index and marks the caret with \0.
class TestRoxygenBreak < Test::Unit::TestCase
  def brk(line, index, wrap_col = 80)
    Roxygen::Line.break_text(line, index, wrap_col)
  end

  def test_mid_line_split
    assert_equal("#' hello\n#' \0world", brk("#' hello world", 8))
  end

  def test_end_of_short_line
    assert_equal("#' hello\n#' \0", brk("#' hello", 8))
  end

  def test_caret_at_col_0
    # Caret in the prefix snaps to its end; no "#' #'" duplication.
    assert_equal("#'\n#' \0hello", brk("#' hello", 0))
  end

  def test_caret_inside_prefix
    assert_equal("#'\n#' \0hello", brk("#' hello", 1))
    assert_equal("#'\n#' \0hello", brk("#' hello", 2))
    assert_equal("#'\n#' \0hello", brk("#' hello", 3))
  end

  def test_plain_non_roxygen_line
    assert_equal("hello\n\0 world", brk("hello world", 5))
  end

  def test_unicode_split
    assert_equal("#' héllo wör\n#' \0ld → done", brk("#' héllo wörld → done", 12))
  end

  def test_indented_roxygen
    assert_equal("  #' hello\n  #' \0world", brk("  #' hello world", 10))
  end

  def test_nospace_prefix
    assert_equal("#'\n#' \0foo", brk("#'foo", 2))
  end

  def test_bare_prefix_at_end
    assert_equal("#'\n#' \0", brk("#'", 3))
  end

  def test_bare_prefix_caret_inside
    assert_equal("#'\n#' \0", brk("#'", 1))
  end

  def test_prefix_with_trailing_space
    assert_equal("#'\n#' \0", brk("#' ", 3))
  end

  def test_no_doubled_prefix_anywhere
    ["#' hello", "#'foo", "#'", "#' ", "  #' hello world"].each do |line|
      (0..line.length).each do |i|
        assert_no_match(/#' #'/, brk(line, i), "line=#{line.inspect} index=#{i}")
      end
    end
  end

  def test_long_line_reflows_with_caret_at_end
    long = "#' " + (["word"] * 22).join(" ")
    out = brk(long, long.length)
    assert(out.lines.count > 1, "expected a wrap, got: #{out.inspect}")
    assert(out.end_with?("\0"), "caret not at end: #{out.inspect}")
    assert_no_match(/#' #'/, out)
    assert(out.lines.all? { |l| l.start_with?("#'") }, "prefix lost: #{out.inspect}")
  end

  def test_unbreakable_word_stays_intact
    long = "#' " + ("x" * 100)
    out = brk(long, long.length)
    assert_equal(1, out.lines.count)
    assert(out.end_with?("\0"))
    assert_equal("#' " + ("x" * 100) + "\0", out)
  end
end
