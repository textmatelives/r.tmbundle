require 'test/unit'
require 'rexml/document'

# Regression test for roxygen math highlighting in the R grammar.
# The inline pattern must cover both \eqn{} (inline) and \deqn{}
# (display) Rd macros. The pattern is read straight out of the
# grammar, so this fails if the rule ever regresses.
class TestRoxygenMath < Test::Unit::TestCase
  GRAMMAR = File.expand_path('../../Syntaxes/R.plist', File.dirname(__FILE__))

  def setup
    match = nil
    REXML::Document.new(File.read(GRAMMAR)).elements.each('//dict') do |dict|
      fields = {}
      dict.elements.each('key') { |key| fields[key.text] = key.next_element.text }
      match = fields['match'] if fields['name'] == 'markup.raw.inline.roxygen'
    end
    assert_not_nil(match, 'inline rule (markup.raw.inline.roxygen) missing from grammar')
    @inline = Regexp.new(match)
  end

  def test_eqn_matches
    assert(@inline.match?('\\eqn{x^2}'), 'expected \\eqn{} to be captured')
  end

  def test_deqn_matches
    assert(@inline.match?('\\deqn{x^2}'), 'expected \\deqn{} to be captured')
  end

  def test_other_macros_still_match
    assert(@inline.match?('\\code{foo}'), 'expected \\code{} to be captured')
    assert(@inline.match?('\\link{bar}'), 'expected \\link{} to be captured')
    assert(@inline.match?('\\dontrun{x}'), 'expected \\dontrun{} to be captured')
  end
end
