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

class NumberParser < Parslet::Parser
  rule(:sign) {
    match('[+-]').repeat 1
  }
  rule(:integer) {
    match('[0-9]') | (
      match('[1-9]') >> match('[0-9]').repeat
    )
  }
  rule(:decimal) {
    str(?.) >> match('[0-9]').repeat(1)
  }
  rule(:number) {
    sign.maybe >> integer >> decimal.maybe
  }
  root(:number)
end

def main
  parser = NumberParser.new

  check=->text{
    begin
      parser.parse(text)
    rescue
      False
    end
  }
  p check['1.12']
end

begin
  main
rescue => e
  raise e
end
