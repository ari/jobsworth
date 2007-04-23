module ActsAsFerret
        
  module ClassMethods

    # rebuild the index from all data stored for this model.
    # This is called automatically when no index exists yet.
    #
    # When calling this method manually, you can give any additional 
    # model classes that should also go into this index as parameters. 
    # Useful when using the :single_index option.
    # Note that attributes named the same in different models will share
    # the same field options in the shared index.
    def rebuild_index(*models)
      models << self unless models.include?(self)
      aaf_index.rebuild_index(models.map(&:to_s))
    end                                                            
    
    # Retrieve the index instance for this model class. This can either be a
    # LocalIndex, or a RemoteIndex instance.
    # 
    # Index instances are stored in a hash, using the index directory
    # as the key. So model classes sharing a single index will share their
    # Index object, too.
    def aaf_index
      ActsAsFerret::ferret_indexes[aaf_configuration[:index_dir]] ||= create_index_instance
    end 
    
    # Finds instances by contents. Terms are ANDed by default, can be circumvented 
    # by using OR between terms. 
    # options:
    # offset::      first hit to retrieve (useful for paging)
    # limit::       number of hits to retrieve, or :all to retrieve
    #               all results
    # lazy::        Array of field names whose contents should be read directly
    #               from the index. Those fields have to be marked 
    #               :store => :yes in their field options. Give true to get all
    #               stored fields (if you have a shared index, you have to
    #               explicitly state the fields you want to fetch, true won't
    #               work)
    # models::      only for single_index scenarios: an Array of other Model classes to 
    #               include in this search. Use :all to query all models.
    #
    # find_options is a hash passed on to active_record's find when
    # retrieving the data from db, useful to i.e. prefetch relationships.
    #
    # this method returns a SearchResults instance, which really is an Array that has 
    # been decorated with a total_hits accessor that delivers the total
    # number of hits (including those not fetched because of a low num_docs
    # value).
    # Please keep in mind that the number of total hits might be wrong if you specify 
    # both ferret options and active record find_options that somehow limit the result 
    # set (e.g. :num_docs and some :conditions).
    def find_by_contents(q, options = {}, find_options = {})
      total_hits, result = find_records_lazy_or_not q, options, find_options
      logger.debug "Query: #{q}\ntotal hits: #{total_hits}, results delivered: #{result.size}"
      return SearchResults.new(result, total_hits)
    end 

   

    # return the total number of hits for the given query 
    def total_hits(q, options={})
      aaf_index.total_hits(q, options)
    end

    # Finds instance model name, ids and scores by contents. 
    # Useful e.g. if you want to search across models or do not want to fetch
    # all result records (yet).
    #
    # Options are the same as for find_by_contents
    #
    # A block can be given too, it will be executed with every result:
    # find_id_by_contents(q, options) do |model, id, score|
    #    id_array << id
    #    scores_by_id[id] = score 
    # end
    # NOTE: in case a block is given, only the total_hits value will be returned
    # instead of the [total_hits, results] array!
    # 
    def find_id_by_contents(q, options = {}, &block)
      deprecated_options_support(options)
      aaf_index.find_id_by_contents(q, options, &block)
    end
    
    # requires the store_class_name option of acts_as_ferret to be true
    # for all models queried this way.
    def multi_search(query, additional_models = [], options = {}, find_options = {})
      result = []

      if options[:lazy]
        logger.warn "find_options #{find_options} are ignored because :lazy => true" unless find_options.empty?
        total_hits = id_multi_search(query, additional_models, options) do |model, id, score, data|
          result << FerretResult.new(model, id, score, data)
        end
      else
        id_arrays = {}
        rank = 0
        total_hits = id_multi_search(query, additional_models, options) do |model, id, score, data|
          id_arrays[model] ||= {}
          id_arrays[model][id] = [ rank += 1, score ]
        end
        result = retrieve_records(id_arrays, find_options)
      end

      SearchResults.new(result, total_hits)
    end
    
    # returns an array of hashes, each containing :class_name,
    # :id and :score for a hit.
    #
    # if a block is given, class_name, id and score of each hit will 
    # be yielded, and the total number of hits is returned.
    def id_multi_search(query, additional_models = [], options = {}, &proc)
      deprecated_options_support(options)
      additional_models = [ additional_models ] unless additional_models.is_a? Array
      additional_models << self
      aaf_index.id_multi_search(query, additional_models.map(&:to_s), options, &proc)
    end
    

    protected

    def find_records_lazy_or_not(q, options = {}, find_options = {})
      if options[:lazy]
        logger.warn "find_options #{find_options} are ignored because :lazy => true" unless find_options.empty?
        lazy_find_by_contents q, options
      else
        ar_find_by_contents q, options, find_options
      end
    end

    def ar_find_by_contents(q, options = {}, find_options = {})
      result_ids = {}
      total_hits = find_id_by_contents(q, options) do |model, id, score, data|
        # stores ids, index of each id for later ordering of
        # results, and score
        result_ids[id] = [ result_ids.size + 1, score ]
      end

      result = retrieve_records( { self.name => result_ids }, find_options )
      # correct result size if the user specified conditions
      total_hits = result.length if find_options[:conditions]

      # order results as they were found by ferret, unless an AR :order
      # option was given
      result.sort! { |a, b| a.ferret_rank <=> b.ferret_rank } unless find_options[:order]

      [ total_hits, result ]
    end

    def lazy_find_by_contents(q, options = {})
      result = []
      total_hits = find_id_by_contents(q, options) do |model, id, score, data|
        result << FerretResult.new(model, id, score, data)
      end
      [ total_hits, result ]
    end


    def model_find(model, id, find_options = {})
      model.constantize.find(id, find_options)
    end

    # retrieves search result records from a data structure like this:
    # { 'Model1' => { '1' => [ rank, score ], '2' => [ rank, score ] }
    #
    # TODO: in case of STI AR will filter out hits from other 
    # classes for us, but this
    # will lead to less results retrieved --> scoping of ferret query
    # to self.class is still needed.
    # from the ferret ML (thanks Curtis Hatter)
    # > I created a method in my base STI class so I can scope my query. For scoping
    # > I used something like the following line:
    # > 
    # > query << " role:#{self.class.eql?(Contents) '*' : self.class}"
    # > 
    # > Though you could make it more generic by simply asking
    # > "self.descends_from_active_record?" which is how rails decides if it should
    # > scope your "find" query for STI models. You can check out "base.rb" in
    # > activerecord to see that.
    # but maybe better do the scoping in find_id_by_contents...
    def retrieve_records(id_arrays, find_options = {})
      result = []
      # get objects for each model
      id_arrays.each do |model, id_array|
        next if id_array.empty?
        begin
          model = model.constantize
          # merge conditions
          conditions = combine_conditions([ "#{model.table_name}.#{primary_key} in (?)", id_array.keys ], 
                                          find_options[:conditions])
          # fetch
          tmp_result = model.find(:all, find_options.merge(:conditions => conditions))
          # set scores and rank
          tmp_result.each do |record|
            record.ferret_rank, record.ferret_score = id_array[record.id.to_s]
          end
          # merge with result array
          result.concat tmp_result
        rescue TypeError
          raise "#{model} must use :store_class_name option if you want to use multi_search against it.\n#{$!}"
        end
      end
      return result
    end

    def deprecated_options_support(options)
      if options[:num_docs]
        logger.warn ":num_docs is deprecated, use :limit instead!"
        options[:limit] ||= options[:num_docs]
      end
      if options[:first_doc]
        logger.warn ":first_doc is deprecated, use :offset instead!"
        options[:offset] ||= options[:first_doc]
      end
    end

    # combine our conditions with those given by user, if any
    def combine_conditions(conditions, *additional_conditions)
      returning conditions do
        if additional_conditions.any?
          cust_opts = additional_conditions.dup.flatten
          conditions.first << " and " << cust_opts.shift
          conditions.concat(cust_opts)
        end
      end
    end

    # creates a new Index::Index instance. Before that, a check is done
    # to see if the index exists in the file system. If not, index rebuild
    # from all model data retrieved by find(:all) is triggered.
    def create_index_instance
      if aaf_configuration[:remote]
       RemoteIndex
      elsif aaf_configuration[:single_index]
        SharedIndex
      else
        LocalIndex
      end.new(aaf_configuration)
    end

  end
  
end

