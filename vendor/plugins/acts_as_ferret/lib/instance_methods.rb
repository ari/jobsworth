module FerretMixin
  module Acts #:nodoc:
    module ARFerret #:nodoc:

      module InstanceMethods
        include MoreLikeThis

          # Returns an array of strings with the matches highlighted. The +query+ can
          # either a query String or a Ferret::Search::Query object.
          # 
          # === Options
          #
          # field::            field to take the content from. This field has 
          #                    to have it's content stored in the index 
          #                    (:store => :yes in your call to aaf). If not
          #                    given, all stored fields are searched, and the
          #                    highlighted content found in all of them is returned.
          #                    set :highlight => :no in the field options to
          #                    avoid highlighting of contents from a :stored field.
          # excerpt_length::   Default: 150. Length of excerpt to show. Highlighted
          #                    terms will be in the centre of the excerpt.
          # num_excerpts::     Default: 2. Number of excerpts to return.
          # pre_tag::          Default: "<em>". Tag to place to the left of the
          #                    match.  
          # post_tag::         Default: "</em>". This tag should close the
          #                    +:pre_tag+.
          # ellipsis::         Default: "...". This is the string that is appended
          #                    at the beginning and end of excerpts (unless the
          #                    excerpt hits the start or end of the field. You'll
          #                    probably want to change this so a Unicode elipsis
          #                    character.
        def highlight(query, options = {})
          options = { :num_excerpts => 2, :pre_tag => '<em>', :post_tag => '</em>' }.update(options)
          i = self.class.ferret_index
          highlights = []
          i.synchronize do
            doc_num = self.document_number
            if options[:field]
              highlights << i.highlight(query, doc_num, options)
            else
              fields_for_ferret.each_pair do |field, config|
                next if config[:store] == :no || config[:highlight] == :no
                options[:field] = field
                highlights << i.highlight(query, doc_num, options)
              end
            end
          end
          return highlights.compact.flatten[0..options[:num_excerpts]-1]
        end
        
        # re-eneable ferret indexing after a call to #disable_ferret
        def ferret_enable; @ferret_disabled = nil end
       
        # returns true if ferret indexing is enabled
        def ferret_enabled?; @ferret_disabled.nil? end

        # Disable Ferret for a specified amount of time. ::once will disable
        # Ferret for the next call to #save (this is the default), ::always will 
        # do so for all subsequent calls.
        # To manually trigger reindexing of a record, you can call #ferret_update 
        # directly. 
        #
        # When given a block, this will be executed without any ferret indexing of 
        # this object taking place. The optional argument in this case can be used 
        # to indicate if the object should be indexed after executing the block
        # (::index_when_finished). Automatic Ferret indexing of this object will be 
        # turned on after the block has been executed.
        def disable_ferret(option = :once)
          if block_given?
            @ferret_disabled = :always
            yield
            ferret_enable
            ferret_update if option == :index_when_finished
          elsif [:once, :always].include?(option)
            @ferret_disabled = option
          else
            raise ArgumentError.new("Invalid Argument #{option}")
          end
        end

        # add to index
        def ferret_create
          if ferret_enabled?
            logger.debug "ferret_create/update: #{self.class.name} : #{self.id}"
            self.class.ferret_index << self.to_doc
          else
            ferret_enable if @ferret_disabled == :once
          end
          @ferret_enabled = true
          true # signal success to AR
        end
        alias :ferret_update :ferret_create
        

        # remove from index
        def ferret_destroy
          logger.debug "ferret_destroy: #{self.class.name} : #{self.id}"
          begin
            self.class.ferret_index.query_delete(query_for_self)
          rescue
            logger.warn("Could not find indexed value for this object: #{$!}")
          end
          true # signal success to AR
        end
        
        # convert instance to ferret document
        def to_doc
          logger.debug "creating doc for class: #{self.class.name}, id: #{self.id}"
          # Churn through the complete Active Record and add it to the Ferret document
          doc = Ferret::Document.new
          # store the id of each item
          doc[:id] = self.id

          # store the class name if configured to do so
          if configuration[:store_class_name]
            doc[:class_name] = self.class.name
          end
          # iterate through the fields and add them to the document
          #if fields_for_ferret
            # have user defined fields
          fields_for_ferret.each_pair do |field, config|
            doc[field] = self.send("#{field}_to_ferret") unless config[:ignore]
          end
          return doc
        end

        # returns the ferret document number this record has.
        def document_number
          hits = self.class.ferret_index.search(query_for_self)
          return hits.hits.first.doc if hits.total_hits == 1
          raise "cannot determine document number from primary key: #{self}"
        end

        protected

        # build a ferret query matching only this record
        def query_for_self
          query = Ferret::Search::TermQuery.new(:id, self.id.to_s)
          if self.class.configuration[:single_index]
            bq = Ferret::Search::BooleanQuery.new
            bq.add_query(query, :must)
            bq.add_query(Ferret::Search::TermQuery.new(:class_name, self.class.name), :must)
            return bq
          end
          return query
        end

      end

    end
  end
end
