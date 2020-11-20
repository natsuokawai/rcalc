require './rcalc'

line_num = 1
loop do
  print "rcalc:#{line_num}>> "
  line_num += 1

  input = gets.chomp
  break if input == 'exit'
  next if input == ''

  print '=> '
  puts Rcalc::Evaluator.new(input).eval
rescue
  puts 'error'
end