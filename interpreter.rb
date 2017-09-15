require 'yaml'

class YAPL
  def initialize(ext={})
    @env = {
      :define => proc { |(name,val), _| @env[name] = evaluate(val, @env) },
      :car   => lambda { |(list), _| list[0] },
      :cdr   => lambda { |(list), _| list.drop 1 },
      :cons  => lambda { |(e,cell), _| [e] + cell },
      :eq    => lambda { |(l,r), ctx| evaluate(l,ctx) == evaluate(r,ctx) },
      :gt    => lambda { |(l,r), ctx| evaluate(l,ctx) > evaluate(r,ctx) },
      :if    => proc { |(cond, thn, els), ctx| evaluate(cond, ctx) ? evaluate(thn, ctx) : evaluate(els, ctx) },
      :atom  => lambda { |(sexpr), _| (sexpr.is_a? Symbol) or (sexpr.is_a? Numeric) },
      :quote => proc { |sexpr, _| sexpr[0] }
    }.merge(ext)
  end

  def apply fn, args, ctx=@env
    return ctx[fn].call(args, ctx) if ctx[fn].respond_to? :call
    self.evaluate ctx[fn][2], ctx.merge(Hash[*(ctx[fn][1].zip args).flatten(1)])
  end

  def evaluate sexpr, ctx=@env
    if ctx[:atom].call [sexpr], ctx
      return ctx[sexpr] || sexpr
    end
    fn, *args = sexpr

    # Translate scheme define shorthand into quoted lambda
    if fn == :define && args.first.is_a?(Array)
      name = args.first.first
      params = args.first.drop 1
      body = args.drop 1
      args = [name, [:quote, [:lambda, params] + body]]
    end

    args = args.map { |a| self.evaluate(a, ctx) } if ctx[fn].is_a?(Array) || (ctx[fn].respond_to?(:lambda?) && ctx[fn].lambda?)
    apply(fn, args, ctx)
  end

  def evaluate_all(sexprs, ctx=@env)
    last_result = nil
    sexprs.each do |sexpr|
      last_result = evaluate sexpr
    end
    last_result
  end

  def self.to_sexpr(yexprs)
    sexpr = []

    yexprs.each do |yexpr|
      if yexpr['define']
        defines = yexpr.fetch('define', []).each do |k, v|
          unless v.is_a? Array
            sexpr << [:define, k.to_sym, v]
          else
            args = v.first.map(&:to_sym)
            body = self.to_sexpr(v.drop 1)

            sexpr << [:define, [k.to_sym] + args] + body
          end
        end
        others = yexpr.keys - ['define']
        raise 'Should not have any others!' if others.size > 0
      else
        if yexpr.is_a? Hash
          raise 'Should not have more than one key!' if yexpr.keys.size > 1
          key = yexpr.keys.first
          value = yexpr.values.first
          raise 'Should have value as an Array' unless value.is_a? Array
          sexpr << [key.to_sym] + to_sexpr(value)
        elsif yexpr.is_a? String
          sexpr << yexpr.to_sym
        else
          sexpr << yexpr
        end
      end
    end

    sexpr
  end
end

if ARGV[0]
  puts YAPL.new.evaluate_all(YAPL.to_sexpr(YAML.load(File.open(ARGV[0]).read)))
else
  puts 'Please enter a filename'
end
