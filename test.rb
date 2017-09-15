require './interpreter'
require 'minitest/autorun'

class TestYAPL < MiniTest::Unit::TestCase
  def test_yapl
    l = YAPL.new

    l.evaluate([:define, :a, 42])

    assert_equal 42, l.evaluate(:a)

    assert l.evaluate [:eq, 42, :a]

    assert_equal [1, 2], l.evaluate([:quote, [1, 2]])

    assert_equal 1, l.evaluate([:car, [:quote, [1, 2]]])

    assert_equal [2], l.evaluate([:cdr, [:quote, [1, 2]]])

    assert_equal [1, 2, 3], l.evaluate([:cons, 1, [:quote, [2,3]]])

    assert_equal 43, l.evaluate([:if, [:eq, 1, 2], 42, 43])

    refute l.evaluate [:atom, [:quote, [1,2]]]

    l.evaluate [:define, [:second, :x], [:car, [:cdr, :x]]]

    assert_equal 2, l.evaluate([:second, [:quote, [1, 2, 3]]])
  end

  def test_to_sexpr
    yapl = YAML.load(File.open('example.yaml').read)
    sexpr = [
      [:define, [:max, :a, :b], [:if, [:gt, :a, :b], :a, :b]],
      [:define, :a, 42],
      [:define, :b, 46],
      [:max, :a, :b]
    ]

    assert_equal sexpr, YAPL.to_sexpr(yapl)
  end

  def test_evaluate_all
    yapl = YAML.load(File.open('example.yaml').read)

    assert_equal 46, YAPL.new.evaluate_all(YAPL.to_sexpr(yapl))
  end
end
