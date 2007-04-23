module ActsAsFerret #:nodoc:
        
  # This module defines the acts_as_ferret method and is included into 
  # ActiveRecord::Base
  module ActMethods
          
    
    def reloadable?; false end
    
    # declares a class as ferret-searchable. 
    #
    # ====options:
    # fields:: names all fields to include in the index. If not given,
    #          all attributes of the class will be indexed. You may also give
    #          symbols pointing to instance methods of your model here, i.e. 
    #          to retrieve and index data from a related model. 
    #
    # additional_fields:: names fields to include in the index, in addition 
    #                     to those derived from the db scheme. use if you want 
    #                     to add custom fields derived from methods to the db 
    #                     fields (which will be picked by aaf). This option will 
    #                     be ignored when the fields option is given, in that 
    #                     case additional fields get specified there.
    #
    # index_dir:: declares the directory where to put the index for this class.
    #             The default is RAILS_ROOT/index/RAILS_ENV/CLASSNAME. 
    #             The index directory will be created if it doesn't exist.
    #
    # single_index:: set this to true to let this class use a Ferret
    #                index that is shared by all classes having :single_index set to true.
    #                :store_class_name is set to true implicitly, as well as index_dir, so 
    #                don't bother setting these when using this option. the shared index
    #                will be located in index/<RAILS_ENV>/shared .
    #
    # store_class_name:: to make search across multiple models (with either
    #                    single_index or the multi_search method) useful, set
    #                    this to true. the model class name will be stored in a keyword field 
    #                    named class_name
    #
    # ====ferret_options:
    # or_default:: whether query terms are required by
    #              default (the default, false), or not (true)
    # 
    # analyzer:: the analyzer to use for query parsing (default: nil,
    #            which means the ferret StandardAnalyzer gets used)
    #
    # default_field:: use to set one or more fields that are searched for query terms
    #                 that don't have an explicit field list. This list should *not*
    #                 contain any untokenized fields. If it does, you're asking
    #                 for trouble (i.e. not getting results for queries having
    #                 stop words in them). Aaf by default initializes the default field 
    #                 list to contain all tokenized fields. If you use :single_index => true, 
    #                 you really should set this option specifying your default field
    #                 list (which should be equal in all your classes sharing the index).
    #                 Otherwise you might get incorrect search results and you won't get 
    #                 any lazy loading of stored field data.
    #
    def acts_as_ferret(options={}, ferret_options={})

      # force local mode if running *inside* the Ferret server - somewhere the
      # real indexing has to be done after all :-)
      options.delete(:remote) if ActsAsFerret::Remote::Server.running

      if options[:remote] && options[:remote] !~ /^druby/
        # read server location from config/ferret_server.yml
        options[:remote] = ActsAsFerret::Remote::Config.load("#{RAILS_ROOT}/config/ferret_server.yml")[:uri]
      end


      extend ClassMethods
      extend SharedIndexClassMethods if options[:single_index]

      include InstanceMethods
      include MoreLikeThis::InstanceMethods

      # AR hooks
      after_create  :ferret_create
      after_update  :ferret_update
      after_destroy :ferret_destroy      

      cattr_accessor :aaf_configuration

      # default config
      self.aaf_configuration = { 
        :index_dir => "#{ActsAsFerret::index_dir}/#{self.name.underscore}",
        :store_class_name => false,
        :name => self.table_name,
        :class_name => self.name,
        :single_index => false,
        :ferret => {
          :or_default => false, 
          :handle_parse_errors => true,
          :default_field => nil # will be set later on
          #:max_clauses => 512,
          #:analyzer => Ferret::Analysis::StandardAnalyzer.new,
          # :wild_card_downcase => true
        }
      }

      # merge aaf options with args
      aaf_configuration.update(options) if options.is_a?(Hash)

      # list of indexed fields will be filled later
      aaf_configuration[:ferret_fields] = Hash.new

      # apply appropriate settings for shared index
      if aaf_configuration[:single_index] 
        aaf_configuration[:index_dir] = "#{ActsAsFerret::index_dir}/shared" 
        aaf_configuration[:store_class_name] = true 
      end

      # merge default ferret options with args
      aaf_configuration[:ferret].update(ferret_options) if ferret_options.is_a?(Hash)

      # these properties are somewhat vital to the plugin and shouldn't
      # be overwritten by the user:
      aaf_configuration[:ferret].update(
        :key               => (aaf_configuration[:single_index] ? [:id, :class_name] : :id),
        :path              => aaf_configuration[:index_dir],
        :auto_flush        => true, # slower but more secure in terms of locking problems TODO disable when running in drb mode?
        :create_if_missing => true
      )
      
      if aaf_configuration[:fields]
        add_fields(aaf_configuration[:fields])
      else
        add_fields(self.new.attributes.keys.map { |k| k.to_sym })
        add_fields(aaf_configuration[:additional_fields])
      end

      ActsAsFerret::ensure_directory aaf_configuration[:index_dir] unless options[:remote]

      # now that all fields have been added, we can initialize the default
      # field list to be used by the query parser.
      # It will include all content fields *not* marked as :untokenized.
      # This fixes the otherwise failing CommentTest#test_stopwords. Basically
      # this means that by default only tokenized fields (which is the default)
      # will be searched. If you want to search inside the contents of an
      # untokenized field, you'll have to explicitly specify it in your query.
      #
      # Unfortunately this is not very useful with a shared index (see
      # http://projects.jkraemer.net/acts_as_ferret/ticket/85)
      # You should consider specifying the default field list to search for as
      # part of the ferret_options hash in your call to acts_as_ferret.
      aaf_configuration[:ferret][:default_field] ||= if aaf_configuration[:single_index]
        logger.warn "You really should set the acts_as_ferret :default_field option when using a shared index!"
        '*'
      else
        aaf_configuration[:ferret_fields].keys.select do |f| 
          aaf_configuration[:ferret_fields][f][:index] != :untokenized
        end
      end
      logger.info "default field list: #{aaf_configuration[:ferret][:default_field].inspect}"
    end


    protected
    
    # helper that defines a method that adds the given field to a ferret 
    # document instance
    def define_to_field_method(field, options = {})
      options.reverse_merge!( :store       => :no, 
                              :highlight   => :yes, 
                              :index       => :yes, 
                              :term_vector => :with_positions_offsets,
                              :boost       => 1.0 )
      aaf_configuration[:ferret_fields][field] = options
      define_method("#{field}_to_ferret".to_sym) do
        begin
          val = content_for_field_name(field)
        rescue
          logger.warn("Error retrieving value for field #{field}: #{$!}")
          val = ''
        end
        logger.debug("Adding field #{field} with value '#{val}' to index")
        val
      end
    end

    def add_fields(field_config)
      if field_config.respond_to?(:each_pair)
        field_config.each_pair do |key,val|
          define_to_field_method(key,val)                  
        end
      elsif field_config.respond_to?(:each)
        field_config.each do |field| 
          define_to_field_method(field)
        end                
      end
    end

  end

end
