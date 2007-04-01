module ScheduleHelper

  def event_tip(e)
    if e.is_a? Task
      owners = "No one"
      owners = e.users.collect{|u| u.name}.join(', ') unless e.users.empty?
      "<strong>Summary</strong> #{h(e.name)}<br/><strong>Assigned To</strong> #{h(owners)}<br/><strong>Progress</strong> #{worked_nice(e.worked_minutes)} / #{worked_nice( e.duration )}"
    else
      ""
    end
  end

  def show_calendar(options = {}, &block)
    raise ArgumentError, "No year given"  unless defined? options[:year]
    raise ArgumentError, "No month given" unless defined? options[:month]

    block                        ||= Proc.new {|d| nil}
    options[:table_class       ] ||= "schedule"
    options[:month_name_class  ] ||= "monthName"
    options[:other_month_class ] ||= "otherMonth"
    options[:day_name_class    ] ||= "dayName"
    options[:day_class         ] ||= "scheduleDay"
    options[:abbrev            ] ||= (0..20)

    first = Date.civil(options[:year], options[:month], 1)
    last = Date.civil(options[:year], options[:month], -1)

    if options[:month].to_i == 12
      next_year = options[:year].to_i + 1
      next_month = 1
      prev_month = options[:month].to_i - 1
      prev_year = options[:year].to_i
    elsif options[:month].to_i == 1
      next_year = options[:year].to_i
      next_month = options[:month].to_i + 1
      prev_year = options[:year].to_i - 1
      prev_month = 12
    else
      next_year = prev_year = options[:year].to_i
      next_month = options[:month].to_i + 1
      prev_month = options[:month].to_i - 1
    end

    cal = <<EOF
<table id="schedule" class="#{options[:table_class]}" cellpadding="0" cellspacing="0" border="0" >
  <thead>
   <tr><td width="100%" colspan="7"><div align="center">#{ link_to '<<', :controller => 'schedule', :action => 'list', :year => prev_year, :month => prev_month} #{Date::MONTHNAMES[options[:month]]} #{options[:year]} #{link_to '>>', :controller => 'schedule', :action => 'list', :year => next_year, :month => next_month}</div></td></tr>

   <tr class="#{options[:day_name_class]}">
EOF
    Date::DAYNAMES.each {|d| cal << "                   <th width=\"130px\">#{d[options[:abbrev]]}</th>"}
    cal << "            </tr>
        </thead>
        <tbody>
                <tr style=\"height:100px;\">"
    0.upto(first.wday - 1) {|d| cal << "                        <td class=\"#{options[:other_month_class]}\"></td>"} unless first.wday == 0
    first.upto(last) do |cur|
      cell_text, cell_attrs = block.call(cur)
      cell_text  = "<div align=\"right\" class=\"scheduleDayHeader\">#{cur.mday}</div>#{cell_text}"
      cell_attrs ||= {:class => options[:day_class]}
      cell_attrs[:class] << " weekend" if cur.wday == 6 || cur.wday == 0
      cell_attrs = cell_attrs.map {|k, v| "#{k}=\"#{v}\""}.join(' ')
      cal << "                  <td #{cell_attrs} width=\"130px\">#{cell_text}</td>"
      if cur.wday == 6
        # Find next weeks max height.
        max_height = 100
        1.upto(7) { |i|
          height = 0
          height = options[:events][cur + i].size * 14 + 15 unless options[:events][cur + i].nil?
          max_height = height if height > max_height
        }

        cal << "          </tr>\n         <tr style=\"height:#{max_height}px;\">"
      end
    end
    last.wday.upto(5) {|d| cal << "                   <td class=\"#{options[:other_month_class]}\"></td>"} unless last.wday == 6
    cal << "            </tr>\n </tbody>\n</table>"
  end

end
