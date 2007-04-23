module ActsAsFerret
  
  class LocalIndex < AbstractIndex
    include MoreLikeThis::IndexMethods


    def initialize(aaf_configuration)
      super
      ensure_index_exists
    end

    # The 'real' Ferret Index instance
    def ferret_index
      ensure_index_exists
      @ferret_index ||= Ferret::Index::Index.new(aaf_configuration[:ferret])
    end

    # Checks for the presence of a segments file in the index directory
    # Rebuilds the index if none exists.
    def ensure_index_exists
      unless File.file? "#{aaf_configuration[:index_dir]}/segments"
        close
        rebuild_index 
      end
    end

    # Closes the underlying index instance
    def close
      @ferret_index.close if @ferret_index
    rescue StandardError 
      # is raised when index already closed
    ensure
      @ferret_index = nil
    end

    # rebuilds the index from all records of the model class this index belongs
    # to. Arguments can be given in shared index scenarios to name multiple
    # model classes to include in the index
    def rebuild_index(*models)
      logger.debug "rebuild index: #{models.inspect}"
      models << aaf_configuration[:class_name] unless models.include?(aaf_configuration[:class_name])
      models = models.flatten.uniq.map(&:constantize)
      index = Ferret::Index::Index.new(aaf_configuration[:ferret].dup.update(:auto_flush => false, 
                                                                             :field_infos => field_infos(models),
                                                                             :create => true))
      models.each do |model|
        reindex_model(index, model)
      end
      logger.debug("Created Ferret index in: #{aaf_configuration[:index_dir]}")
      index.flush
      index.optimize
      index.close
      close_multi_indexes
    end

    # Parses the given query string into a Ferret Query object.
    def process_query(query)
      # work around ferret bug in #process_query (doesn't ensure the
      # reader is open)
      ferret_index.synchronize do
        ferret_index.send(:ensure_reader_open)
        original_query = ferret_index.process_query(query)
      end
    end

    # Total number of hits for the given query. 
    def total_hits(query, options = {})
      ferret_index.search(query, options).total_hits
    end

    def determine_lazy_fields(options = {})
      stored_fields = options[:lazy]
      if stored_fields && !(Array === stored_fields)
        stored_fields = aaf_configuration[:ferret_fields].select { |field, config| config[:store] == :yes }.map(&:first)
      end
      logger.debug "stored_fields: #{stored_fields}"
      return stored_fields
    end

    # Queries the Ferret index to retrieve model class, id, score and the
    # values of any fields stored in the index for each hit.
    # If a block is given, these are yielded and the number of total hits is
    # returned. Otherwise [total_hits, result_array] is returned.
    def find_id_by_contents(query, options = {})
      result = []
      index = ferret_index
      logger.debug "query: #{ferret_index.process_query query}" # TODO only enable this for debugging purposes
      lazy_fields = determine_lazy_fields options

      total_hits = index.search_each(query, options) do |hit, score|
        doc = index[hit]
        model = aaf_configuration[:store_class_name] ? doc[:class_name] : aaf_configuration[:class_name]
        # fetch stored fields if lazy loading
        data = {}
        lazy_fields.each { |field| data[field] = doc[field] } if lazy_fields
        if block_given?
          yield model, doc[:id], score, data
        else
          result << { :model => model, :id => doc[:id], :score => score, :data => data }
        end
      end
      #logger.debug "id_score_model array: #{result.inspect}"
      return block_given? ? total_hits : [total_hits, result]
    end

    # Queries multiple Ferret indexes to retrieve model class, id and score for 
    # each hit. Use the models parameter to give the list of models to search.
    # If a block is given, model, id and score are yielded and the number of 
    # total hits is returned. Otherwise [total_hits, result_array] is returned.
    def id_multi_search(query, models, options = {})
      models.map!(&:constantize)
      index = multi_index(models)
      result = []
      lazy_fields = determine_lazy_fields options
      total_hits = index.search_each(query, options) do |hit, score|
        doc = index[hit]
        # fetch stored fields if lazy loading
        data = {}
        lazy_fields.each { |field| data[field] = doc[field] } if lazy_fields
        if block_given?
          yield doc[:class_name], doc[:id], score, doc, data
        else
          result << { :model => doc[:class_name], :id => doc[:id], :score => score, :data => data }
        end
      end
      return block_given? ? total_hits : [ total_hits, result ]
    end

    ######################################
    # methods working on a single record
    # called from instance_methods, here to simplify interfacing with the
    # remote ferret server
    # TODO having to pass id and class_name around like this isn't nice
    ######################################

    # add record to index
    # record may be the full AR object, a Ferret document instance or a Hash
    def add(record)
      record = record.to_doc unless Hash === record || Ferret::Document === record
      ferret_index << record
    end
    alias << add

    # delete record from index
    def remove(id, class_name)
      ferret_index.query_delete query_for_record(id, class_name)
    end

    # highlight search terms for the record with the given id.
    def highlight(id, class_name, query, options = {})
      options.reverse_merge! :num_excerpts => 2, :pre_tag => '<em>', :post_tag => '</em>'
      highlights = []
      ferret_index.synchronize do
        doc_num = document_number(id, class_name)
        if options[:field]
          highlights << ferret_index.highlight(query, doc_num, options)
        else
          query = process_query(query) # process only once
          aaf_configuration[:ferret_fields].each_pair do |field, config|
            next if config[:store] == :no || config[:highlight] == :no
            options[:field] = field
            highlights << ferret_index.highlight(query, doc_num, options)
          end
        end
      end
      return highlights.compact.flatten[0..options[:num_excerpts]-1]
    end

    # retrieves the ferret document number of the record with the given id.
    def document_number(id, class_name)
      hits = ferret_index.search(query_for_record(id, class_name))
      return hits.hits.first.doc if hits.total_hits == 1
      raise "cannot determine document number from primary key: #{id}"
    end

    # build a ferret query matching only the record with the given id
    # the class name only needs to be given in case of a shared index configuration
    def query_for_record(id, class_name = nil)
      Ferret::Search::TermQuery.new(:id, id.to_s)
    end


    protected

    # returns a MultiIndex instance operating on a MultiReader
    def multi_index(model_classes)
      model_classes.sort! { |a, b| a.name <=> b.name }
      key = model_classes.inject("") { |s, clazz| s + clazz.name }
      multi_config = aaf_configuration[:ferret].dup
      multi_config.delete :default_field  # we don't want the default field list of *this* class for multi_searching
      ActsAsFerret::multi_indexes[key] ||= MultiIndex.new(model_classes, multi_config)
    end
 
    def close_multi_indexes
      # close combined index readers, just in case
      # this seems to fix a strange test failure that seems to relate to a
      # multi_index looking at an old version of the content_base index.
      ActsAsFerret::multi_indexes.each_pair do |key, index|
        # puts "#{key} -- #{self.name}"
        # TODO only close those where necessary (watch inheritance, where
        # self.name is base class of a class where key is made from)
        index.close #if key =~ /#{self.name}/
      end
      ActsAsFerret::multi_indexes.clear
    end

    def reindex_model(index, model = aaf_configuration[:class_name].constantize)
      # index in batches of 1000 to limit memory consumption (fixes #24)
      # TODO make configurable through options
      batch_size = 1000
      model_count = model.count.to_f
      work_done = 0
      batch_time = 0
      logger.info "reindexing model #{model.name}"
      order = "#{model.primary_key} ASC" # this works around a bug in sqlserver-adapter (where paging only works with an order applied)
      model.transaction do
        0.step(model.count, batch_size) do |i|
          b1 = Time.now.to_f
          model.find(:all, :limit => batch_size, :offset => i, :order => order).each do |rec|
            index << rec.to_doc if rec.ferret_enabled?(true)
          end
          batch_time = Time.now.to_f - b1
          work_done = i.to_f / model_count * 100.0 if model_count > 0
          remaining_time = ( batch_time / batch_size ) * ( model_count - i + batch_size )
          logger.info "reindex model #{model.name} : #{'%.2f' % work_done}% complete : #{'%.2f' % remaining_time} secs to finish"
        end
      end
    end

    # builds a FieldInfos instance for creation of an index containing fields
    # for the given model classes.
    def field_infos(models)
      # default attributes for fields
      fi = Ferret::Index::FieldInfos.new(:store => :no, 
                                         :index => :yes, 
                                         :term_vector => :no,
                                         :boost => 1.0)
      # primary key
      fi.add_field(:id, :store => :yes, :index => :untokenized) 
      # class_name
      if aaf_configuration[:store_class_name]
        fi.add_field(:class_name, :store => :yes, :index => :untokenized) 
      end
      fields = {}
      models.each do |model|
        fields.update(model.aaf_configuration[:ferret_fields])
      end
      fields.each_pair do |field, options|
        fi.add_field(field, { :store => :no, 
                              :index => :yes }.update(options)) 
      end
      return fi
    end

  end

end
