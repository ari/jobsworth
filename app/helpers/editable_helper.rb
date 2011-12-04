# encoding: UTF-8
module EditableHelper
  def editable_field(object, property, options={})
    name = "#{object.class.to_s.underscore}[#{property}]"
    value = options.delete(:display) || (object.send property)
    update_url = options.delete(:update_url) || url_for(object)

    args = {
      :method => 'PUT', 
      :name => name, 
      :indicator => "#{image_tag 'spinner.gif'}",
      :tooltip => "Click to edit...",
      :ajaxoptions => {
        :dataType => "json",
        :success => %{
          function(result, status) {
          }
        }
      }, 
      :submitdata => {
        :format => "js", 
        :authenticity_token => form_authenticity_token}
    }.merge(options)

    %{
      <span class="jeditable" data-id="#{object.id}" data-name="#{name}" style="#{options[:displayStyle]}">#{value}</span>
      <script type="text/javascript">
        (function( $ ){
          $(function(){
            var args = {data: function(value, settings) {
              // Unescape HTML
              var retval = value
                .replace(/&amp;/gi, '&')
                .replace(/&gt;/gi, '>')
                .replace(/&lt;/gi, '<')
                .replace(/&quot;/gi, "\\\"");
              return retval;
            }};

            $.extend(args, #{args.to_json});

            $(document).ready(function() {
              $(".jeditable[data-id='#{object.id}'][data-name='#{name}']").editable(function(value, settings) {
                 var submitdata = {};
                 submitdata[settings.name] = value;
                 submitdata[settings.id] = $(this).id;

                 /* add extra data to be POST:ed */
                 if ($.isFunction(settings.submitdata)) {
                   $.extend(submitdata, settings.submitdata.apply(self, [self.revert, settings]));
                 } else {
                   $.extend(submitdata, settings.submitdata);
                 }

                 if ('PUT' == settings.method) {
                   submitdata['_method'] = 'put';
                 }

                 /* show the saving indicator */
                 $(this).html(settings.indicator);

                 var self = this;
                 $.post('#{update_url}', submitdata, function(data) {
                   if (settings.type == "select") {
                     $(self).html(JSON.parse(settings.data)[value]);
                   } else {
                     $(self).html(value);
                   }
                 }, 'json')

              }, args);
            })
          });
        })( jQuery );
      </script>
    }.html_safe
  end

end
