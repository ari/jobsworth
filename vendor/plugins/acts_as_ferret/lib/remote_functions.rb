module ActsAsFerret
  module RemoteFunctions

    private

    def yield_results(total_hits, results)
      results.each do |result|
        yield result[:model], result[:id], result[:score], result[:data]
      end
      total_hits
    end


    def handle_drb_error(return_value_in_case_of_error = false)
      yield
    rescue DRb::DRbConnError => e
      logger.error "DRb connection error: #{e}"
      logger.warn e.backtrace.join("\n")
      raise e if ActsAsFerret::raise_drb_errors?
      return_value_in_case_of_error
    end
  end
end
