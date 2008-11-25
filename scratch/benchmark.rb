require 'rubygems'
require 'benchmark'
require 'time'
require 'parsedate'

js_comp = "2008/11/25 15:18:21 +0000" # Time.now.utc.strftime("%Y/%m/%d %H:%M:%S +0000")
iso8601 = "2008-11-25T12:15:34Z"
secs = 1227615341
count = 10_000

Benchmark.bmbm do |x|
  x.report("ISO8601 Time.parse") do
    count.times do
      Time.parse(iso8601)
    end
  end
  x.report("ISO8601 ParseDate.parsedate")  do
    count.times do
      pd_vals = ParseDate.parsedate(iso8601)
      Time.utc(*pd_vals)
    end
  end
  x.report("JS Time.parse") do
    count.times do
      Time.parse(js_comp)
    end
  end
  x.report("JS ParseDate.parsedate")  do
    count.times do
      pd_vals = ParseDate.parsedate(js_comp)
      Time.utc(*pd_vals)
    end
  end
  x.report("Time.at") do
    count.times do
      Time.at(secs).utc
    end
  end
end
