#!/usr/bin/ruby

require 'strscan'

class Sunflower
  @@rsvwords = { # 予約語
    '+' => :add,
    '-' => :sub,
    '*' => :mul,
    '/' => :div,
    '(' => :lpar,
    ')' => :rpar,
    '{' => :lbraces,
    '}' => :rbraces,
    '=' => :assign,
    'if' => :if,
    'else' => :else,
    'loop' => :loop,
    'print' => :print,
  }

  def initialize
    @prg = open(ARGV[0]) # プログラムファイルをオープン
  end
  
  def get_token
  end

  def unget_token
  end

  def parse
  end

  def eval
  end

end