cache=ActiveSupport::Cache.lookup_store(:file_store, "#{Rails.root}/tmp/cache")
0.upto(1000) do |i|
  cache.write("/views/tags/1/#{i}a", "tag 1, tag2, tag3 "*200)
end
puts "Cache created, cleanup..."
p Benchmark.realtime{
 cache.delete_matched(%r{views\/tags\/1\/*})
}



      def cache.delete_matched_in_dir(dir, matcher, options = nil)
        path = @cache_path + dir
        return unless File.exist?(path) #it's ok to not have the cache dir
        search_dir(path) do |f|
          if f =~ matcher
          begin
            File.delete(f)
          rescue SystemCallError => e
            # If there's no cache, then there's nothing to complain about
          end
          end
         end
       end
0.upto(1000) do |i|
  cache.write("/views/tags/1/#{i}a", "tag 1, tag2, tag3 "*200)
end
puts "Cache created, cleanup..."
p Benchmark.realtime{
 cache.delete_matched_in_dir("/views/tags/1", /.*/ )
}
#I benchmarked solution from http://blog.pluron.com/2008/07/hell-is-paved-w.html
#      def delete_matched_in_dir(dir, matcher, options = nil)
#        path = @cache_path + dir
#        return unless File.exist?(path) #it's ok to not have the cache dir
#        search_dir(path) do |f|
#          if f =~ matcher
#          begin
#            File.delete(f)
#          rescue SystemCallError => e
#            # If there's no cache, then there's nothing to complain about
#          end
#          end
#         end
#       end
#The main idea is to split regexp /tags\/1\/*/ to "tags/1/" and regexp /.*/. Then we should not match dirs in tmp/cache and in tmp/cache/tags, we should match only in tmp/cache/tags/1.
#The time of expire_fragment is:
#M*(E1+E2+E3) + D*(E3)
#The time of delete_matched_in_dir is:
#M*D*E3
#Where M - time to match one file system entry(file or dir)
#            D - time to delete one file system entry
#            E1 - number of entries in tmp/cache
#            E2 - number of entries in tmp/cache/tags
#            E3 - number of entries in tmp/cache/tags/1
#Benchmark results is:
#E1 =1;    E2 =100;  E3 = 100k
#expire_fragment                                                   delete_matched_in_dir
#9.1                                                                            7.2
#E1=100k; E2=100k; E3 =100k
#13.1                                                                          7.3
#E1=100k; E2=100k; E3 =100
#5.6                                                                            0.072
#Notice the last example, 100 times faster!
