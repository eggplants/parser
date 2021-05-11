# coding: utf-8
require 'parslet'

# rule syntax:
# - `any`:           任意の1文字
# - `str(x)`:        文字列x
# - `match(x)`:      正規表現x
# - `xxx >> yyy`:    (xxx)(yyy)
# - `xxx | yyy`:     (xxx|yyy)
# - `xxx.repeat`:    (xxx)*
# - `xxx.repeat(n)`: (xxx){n}
# - `xxx.maybe`:     (xxx)?
# - `xxx.absent?`:   (?!xxx) ただし文字は消費しない
# - `xxx.present?`:  (xxx)   ただし文字は消費しない

class MyNumberParser < Parslet::Parser
  rule(:separator) {
    match('[-\s]').repeat(0, 1)
  }
  rule(:four) {
    # match('[0-9][0-9][0-9][0-9]')はNG
    match('[0-9]').repeat(4, 4)
  }
  rule(:mynumber) {
    (
      # maybeのあとに
      four.as(:f1) >> separator >> four.as(:f2) >> separator >> four.as(:f3)
    ).as(:mynumber)
    # >> separator.maybe >> four
  }
  root(:mynumber)
end

MyNumberNode = Struct.new(:f1, :f2, :f3) {
  def eval
    p (f1+f2+f3).to_s
  end
}

class MyNumberTransformar < Parslet::Transform
  rule(:mynumber => subtree(:fields)){
    MyNumberNode.new(fields[:f1], fields[:f2], fields[:f3])
  }
end

def main(txt)
  p res = MyNumberParser.new.parse(txt)
  p tra = MyNumberTransformar.new.apply(res)
  p tra.eval
end

begin
  p 'gemmie my number'
  main(gets.chomp)
rescue Parslet::ParseFailed => e
  p "Parse failed!"
  raise e
rescue => e
  p "unknown error"
  raise e
end
