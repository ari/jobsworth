
require 'find'

# Take a directory, and a list of patterns to match, and a list of
# filenames to avoid
def recursive_search(dir,patterns,
                     excludes=[/\.svn/, /,v$/, /\.cvs$/, /\.tmp$/,
                               /^RCS$/, /^SCCS$/, /~$/])
  results = Hash.new{|h,k| h[k] = ''}

  Find.find(dir) do |path|
    fb =  File.basename(path) 
    next if excludes.any?{|e| fb =~ e}
    if File.directory?(path)
      if fb =~ /\.{1,2}/ 
        Find.prune
      else
        next
      end
    else  # file...
      File.open(path, 'r') do |f|
        ln = 1
        while (line = f.gets)
          patterns.each do |p|
            if line.include?(p)
              results[p] += "#{path}:#{ln}:#{line}"
            end
          end
          ln += 1
        end
      end
    end
  end
  return results
end

desc "Checks your app and gently warns you if you are using deprecated code."
task :deprecated => :environment do
  
  deprecated = {
    '@params'    => 'Use params[] instead',
    '@session'   => 'Use session[] instead',
    '@flash'     => 'Use flash[] instead',
    '@request'   => 'Use request[] instead',
    '@env' => 'Use env[] instead',
    'find_all\b'   => 'Use find(:all) instead',
    'find_first\b' => 'Use find(:first) instead',
    'render_partial' => 'Use render :partial instead',
    'component'  => 'Use of components are frowned upon',
    'paginate'   => 'The default paginator is slow. Writing your own may be faster',
    'start_form_tag'   => 'Use form_for instead',
    'end_form_tag'   => 'Use form_for instead',
    ':post => true'   => 'Use :method => :post instead'
  }

  results = recursive_search("#{File.expand_path('app', RAILS_ROOT)}",deprecated.keys)

  deprecated.each do |key, warning|
    puts '--> ' + key
    unless results[key] =~ /^$/
      puts "  !! " + warning + " !!"
      puts '  ' + '.' * (warning.length + 6)
      puts results[key]
    else
      puts "  Clean! Cheers for you!"
    end
    puts
  end

end
