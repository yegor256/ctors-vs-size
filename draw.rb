#!/usr/bin/env ruby
# The MIT License (MIT)
#
# Copyright (c) 2020 Yegor Bugayenko
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included
# in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NON-INFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

require 'slop'

opts = Slop.parse(ARGV, strict: true, help: true) do |o|
  o.integer '--width', default: 12
  o.integer '--height', default: 8
  o.integer '--rmax', default: 4
  o.integer '--rmin', default: 0.5
  o.integer '--steps', default: 100
  o.integer '--max-ncss', default: 1000
  o.string '--summary', default: 'summary.csv'
  o.string '--type', default: 'ctors'
end

xstep = opts['max-ncss'] / opts[:steps]
data = []
File.open(opts[:summary]).read.each_line do |l|
  attrs, ctors, methods, ncss = l.strip.split(',').map { |a| a.to_i }
  next if ncss > opts['max-ncss']
  x = ncss / xstep
  data[x] = [] if data[x].nil?
  data[x] << { attrs: attrs, ctors: ctors, methods: methods, ncss: ncss }
end

cols = []
(0..(opts[:steps] - 1)).each do |x|
  next if data[x].nil?
  dt = data[x].map do |d|
    if opts[:type] == 'ctors-share'
      next if (d[:ctors] + d[:methods]).zero?
      d[:ctors].to_f / (d[:ctors] + d[:methods])
    elsif opts[:type] == 'attrs-vs-ctors'
      next if d[:ctors].zero?
      d[:attrs].to_f / d[:ctors]
    elsif opts[:type] == 'ctors'
      d[:ctors]
    else
      raise "Invalid type #{opts[:type]}"
    end
  end.compact
  cols[x] = dt.empty? ? 0 : dt.inject(&:+).to_f / dt.count
end

puts '\begin{tikzpicture}'
puts "\\begin{axis}[width=#{opts[:width]}cm,height=#{opts[:height]}cm,"
puts 'axis lines=middle, xlabel={NCSS}, ylabel={$R$},'
puts "xmin=0, xmax=#{opts['max-ncss']}, ymin=0, ymax=#{cols.compact.max},"
puts "extra tick style={major grid style=black},grid=major]"
puts "\\addplot [mark=*] coordinates {"
cols.each_with_index do |c, x|
  next if c.nil?
  puts "(#{x * xstep},#{c})"
end
puts "};"
puts '\end{axis}\end{tikzpicture}'
