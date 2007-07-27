xml.instruct! :xml, :version=>"1.0", :encoding=>"UTF-8"

xml.rss "version" => "2.0" do
  xml.channel do
    xml.title "Recent Exceptions#{%( (filtered)) if filtered?} | #{LoggedExceptionsController.application_name}"
    xml.link url_for(:only_path => false, :skip_relative_url_root => false)
    xml.language "en-us"
    xml.ttl "60"

    @exceptions.each do |exc|
      xml.item do
        xml.title "#{exc.exception_class} in #{exc.controller_action} @ #{exc.created_at.rfc822}"
        xml.description exc.message
        xml.pubDate exc.created_at.rfc822
        xml.guid [request.host_with_port, 'exceptions', exc.id.to_s].join(":"), "isPermaLink" => "false"
        xml.link url_for(:action => 'index', :id => exc, :only_path => false, :skip_relative_url_root => false)
      end
    end
  end
end
