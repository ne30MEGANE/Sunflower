#!/usr/bin/ruby

require 'strscan'

class Sunflower
  @@rsvwords = { # 予約語
    '+' => :add,
    '-' => :sub,
    '*' => :mul,
    '/' => :div,
    '%' => :mod,
    '(' => :lpar,
    ')' => :rpar,
    '{' => :lbraces,
    '}' => :rbraces,
    '=' => :assign,
    'if' => :if,
    'else' => :else,
    'loop' => :loop,
    'print' => :print,
    '*-' => :comment
  }

  def initialize
    if ARGV[0]
      file = open(ARGV[0]) # プログラムファイルをオープン
      code = file.map {|l| l.chomp }.join(' ') # 各行をスペース区切りで1行に
      # p code # for debug
      @scanner = StringScanner.new(code)
      @member = {} # 変数等を持つやつ
      eval(parse())
    end
  end
  
  def get_token 
    # scanメソッドを叩いて合致しないとnilが返る→そのif文は実行されない
    # p "get_token先頭: #{@scanner.inspect}" # for debug
    if token = @scanner.scan(/\s*?(if|loop|print)/)
      return token.strip.intern # シンボル化して返す
    end
    if token = @scanner.scan(/\s*\*\-\s?\w+/) # コメント (*-と文章の間に空白があってもなくても良い)
      return :comment
    end
    if token = @scanner.scan(/\s*?[\(\)\{\}\=\+\-\*\/\%]/) # (){}=+-*/% たち
      case token.strip
      when "("
        return :lpar
      when ")"
        return :rpar
      when "{"
        return :lbraces
      when "}"
        return :rbraces
      when "="
        return :assign
      when "+"
        return :add
      when "-"
        return :sub
      when "*"
        return :mul
      when "/"
        return :div
      when "%"
        return :mod
      end
    end
    if token = @scanner.scan(/\A\s*?[0-9]+/) # 数字
      return token.to_f # float型にして返す
    end
    if token = @scanner.scan(/\A\s*\".*?\"/) # "文字列"
      return token.to_s # ""ごと全部渡す
    end
    if token = @scanner.scan(/\A\s*?(\w+)/) # 変数名
    end
    
  end

  def unget_token
    @scanner.unscan
  end

  def parse
    paragraph()
  end

  def eval(exp)
    # p "eval: #{exp}"
    if exp.instance_of?(Array)
      case exp[0]
      when :block # まずここに来る、この時exp[1]~にsentenceが格納されている状態
        exp.each_with_index do |s, idx|
          unless idx == 0 # exp[0]以外
            eval(s)
          end
        end
      when :print
        return puts(eval(exp[1]))
      when :loop
        1.step(exp[1]){ # 指定回数繰り返す
          exp[2].each{|sent| #ブロック内のsenteneをそれぞれ実行
            eval(sent)
          }
        }
      when :add
        return eval(exp[1]) + eval(exp[2])
      when :sub
        return eval(exp[1]) - eval(exp[2])
      when :mul
        return eval(exp[1]) * eval(exp[2])
      when :div
        return eval(exp[1]) / eval(exp[2])
      when :mod
        return eval(exp[1]) % eval(exp[2])
      end
    end
    return exp
  end

  def paragraph # paragraph := sentence(sentence)*
    result = [:block]
    while s = sentence() # 文をブロックにまとめる
      # p "paragraph: #{s}" # for debug
      result << s
    end
    result
  end

  def sentence # sentence := substitution | if | loop | print
    token = get_token()
    # p "sentence: #{token}, #{@scanner.pos}" # for debug
    case token
    when :if # 'if' '(' 式 ')' '{' paragraph '}' 'else' '{' paragraph '}'
      data = get_token()
      if data == :lpar
        result = [:if]
      else
        raise Exception
      end
    when :loop # 'loop' '(' 回数 ')' '{' paragraph '}'
      data = get_token()
      if data == :lpar
        times = expression() # ()内の式
        if times.instance_of?(Float) # factorを通過した数値型は全部floatなので
          if get_token() == :lbraces # {の時
            # ans = []
            # while get_token != :rbraces # }が来るまで
            #   ans << sentence()
            # end
            # get_token() # }ころす
            result = [:loop, times.to_i, paragraph()]
          end
        else
          raise Exception # エラー：loop回数指定が数値ではない
        end
      else
        raise Exception # 構文エラー
      end
    when :print # 'print' '(' 式 ')'
      if get_token() == :lpar
        result = [:print, expression()]
      else
        raise Exception  # 構文エラー
      end
    when :assign # 変数 '=' 式
    else
    end
  end

  def expression() # 項 ((+|-) 項)*
    result = term()
    token = get_token() # 先読み
    while token == :add or token == :sub
      result = [token, result, term()]
      token = get_token()
    end
    unget_token() unless token.nil?
    # p "expression: #{token}, #{@scanner.pos}" # for debug
    return result
  end

  def term() # 因子 ((*|/) 因子)*
    result = facter()
    token = get_token()  # 先読み
    while token == :mul or token == :div or token == :mod
      result = [token, result, facter()]
      token = get_token()
    end
    unget_token() unless token.nil?
    return result
  end

  def facter() # リテラル | 変数 | "文字列"
    token = get_token()
    if token.instance_of?(Float) # 数字
      result = token
      get_token() # とじかっこ殺す
    elsif token =~/"(.*)"/ # "文字列"
      # p token, $1 # for debug
      result = $1
      get_token() # とじかっこ殺す
    else # 変数
      if @member["#{token}"] # 変数が
        result = @member["#{token}"]
        get_token() # とじかっこ殺す
      else 
        raise Exception
      end
    end
    return result
  end
end

Sunflower.new