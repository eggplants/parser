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

# TODO:
# - (書き直す？)
# - 接頭辞に対応
# - 括弧に対応
# - 選言に対応
# - 量指定に対応
# - in, out, schemaをinitに持つクラス => eval(graph)で評価

class ShExSchemaParser < Parslet::Parser
  rule(:label) {
    match('[a-z]') >> match('[a-zA-Z0-9_]').repeat(0)
  }
   rule(:type) {
    match('[a-z]') >> match('[a-zA-Z0-9_]').repeat(0)
  }
  rule(:space) {
    match('\s').repeat(1)
  }
  rule(:space?) {
    space.maybe
  }
  rule(:blank_type) {
    str('_')
  }
  rule(:op){
    str('||') | str('|')
  }
  rule(:stop){
    str('.')
  }
  rule(:state) {
    (
      blank_type.as(:out_type) |
      (label.as(:label) >>  str('::') >> type.as(:out_type))
    )
  }
  rule(:schema) {
    (
      space? >> type.as(:in_type) >> match('[ \t]').repeat(1) >>
      state >> space? >> (
        op.as(:operator) >> space? >> state >> space?
      ).repeat(0) >> space? >> stop >> space?
    ).as(:schema)
  }
  rule(:schemas){
    schema.repeat(0)
  }
  root(:schemas)
end

class ShExSchemaTransformar < Parslet::Transform
  rule(:in_type => simple(:x)){ x.to_s }
  rule(:out_type => simple(:x)){ x.to_s }
  rule(:label => simple(:x)){ x.to_s }
  # rule(:schema => subtree(:t)){ t }
end

def add_infos(elm, in_, out, first_elm='')
  if elm[:out_type].to_s != ?_
    l, i, o = [elm[:label], elm[:in_type], elm[:out_type]].map(&:to_s)
    i = first_elm.to_s if i == ''
    (in_[l]||=[]) << o; (out[l]||=[]) << i
  end
end

def create_info_tables(res)
  in_, out = {}, {}
  res.each{|k|
    elm = k[:schema]
    if elm.class == Array
      fst = elm.shift
      add_infos(fst, in_, out)
      elm.each{|e|
        if e[:operator] == '||'
          add_infos(e, in_, out, fst[:in_type])
        else
          # pass
        end
      }
    else
      add_infos(elm, in_, out)
    end
  }
  return in_, out
end

def typing(graph, in_, out)
  typed = []
  (n=graph.size).times{|i|
    types = []
    graph[i].each_with_index{|e, idx|
      next if idx == i
      if e != ""
        types << out[e] unless out[e].nil?
      else
        graph.each_with_index{
          next if _2 == i
          types << in_[_1[i]] unless in_[_1[i]].nil?
        }
      end
    }
    types = types.flatten
    unless types.empty? || (_=types.uniq).size != 1
      typed << _
    else
      return false, i
    end
  }
  return true, typed
end

def main()
  txt = <<-SC
    t_0 st::t_1.
    t_1 ta::t_2 || sv::t_3.
    t_2 _.
    t_3 te::t_2.
  SC
  puts "[schema]:", txt
  res = ShExSchemaParser.new.parse(txt)
  puts "[parsed]:"
  pp res = ShExSchemaTransformar.new.apply(res)
  in_, out = create_info_tables(res)
  puts "[table_in]:"; pp in_
  puts "[table_out]:"; pp out
  #############################################
  p graph_1 = [["", "tv", "ta"],
             ["", ""  , "te"],
             ["", ""  , ""  ]]
  puts '[g1_typing]:'
  p typing(graph_1, in_, out)
  p graph_2 = [["", "ta", "te"],
             ["", ""  , "sv"],
             ["", ""  , ""  ]]
  puts '[g2_typing]:'
  p typing(graph_2, in_, out)
end

begin
  main
rescue Parslet::ParseFailed => e
  p "Parse failed!"
  raise e
rescue => e
  p "Unknown error"
  raise e
end
