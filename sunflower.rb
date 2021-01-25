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
      file = readlines(ARGV[0]) # プログラムファイルをオープン
      code = file.map{|f| f.chomp}.join(' ') # 各行をスペース区切りで1行に
      # p code # for debug
      @scanner = StringScanner.new(code)
      @member = {} # 変数等を持つやつ
      eval(parse())
    end
  end
  
  def get_token 
    # scanメソッドを叩いて合致しないとnilが返る→そのif文は実行されない
    if token = @scanner.scan(/\A\s*#{"if|loop|print"}/)
      # p token.intern # for debug
      return token.intern # シンボル化して返す
    end
    if token = @scanner.scan(/\s*\*\-\s?\w+/) # コメント (*-と文章の間に空白があってもなくても良い)
      return :comment
    end
    if token = @scanner.scan(/\A\s*[\(\)\{\}\=\+\-\*\/\%]/) # (){}=+-*/% たち
      # p token.strip # for debug
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
    if token = @scanner.scan(/\A\s*[0-9]+/) # 数字
      return token.to_f # float型にして返す
    end
    if token = @scanner.scan(/\A\s*(\w+)/) # 変数名
    end
    if token = @scanner.scan(/\A\s*\".*\"/) # "文字列"
      return token.to_s # ""ごと全部渡す→factorで変数なのか文字列なのか判断
    end
    
  end

  def unget_token
    @scanner.unscan
  end

  def parse
    paragraph()
  end

  def eval(exp)
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
      # p s # for debug
      result << s
    end
    result
  end

  def sentence # sentence := substitution | if | loop | print
    token = get_token()
    case token
    when :lbraces # { の時
    when :if # 'if' '(' 式 ')' '{' paragraph '}' 'else' '{' paragraph '}'
    when :loop # 'loop' '(' 式 ')' '{' paragraph '}'
    when :print # 'print' '(' 式 ')'
      data = get_token() # 次を読んで
      # p data # for debug
      if data == :lpar # 左カッコだったら
        result = [:print, expression()] # 結果を格納 evalではこう→exp[:print, 式]
        # 式の中身はexpression以下でget_tokenするのでこれで良い
      else # "print"の次に左カッコがこない→構文エラー
        raise Exception
      end
    when :assign # 変数 '=' 式
    else
    end
  end

  def expression() # 項 ((+|-) 項)*
    result = term()
    token = get_token()
    while token == :add or token == :sub
      result = [token, result, term()]
      token = get_token()
    end
    token = unget_token() unless token.nil?
    return result
  end

  def term() # 因子 ((*|/) 因子)*
    result = facter()
    token = get_token()
    while token == :mul or token == :div or token == :mod
      result = [token, result, facter()]
      token = get_token()
    end
    # p token # for debug
    token = unget_token() unless token.nil?
    return result
  end

  def facter() # リテラル | 変数 | "文字列"
    token = get_token()
    if token.instance_of?(Float) # 数字
      result = token
    elsif token =~/"(.*)"/ # "文字列"
      # p token, $1 # for debug
      result = $1
    else # 変数
      if @member["#{token}"] # 変数が存在するとき
        result = @member["#{token}"]
      else # しない時
        raise Exception
      end
    end
    return result
  end
end

Sunflower.new