require 'set'
require 'nokogiri'
require 'binding_of_callers/pry'
require 'cgi'

module CallerLog

  class Log

    attr_reader :file, :html, :lock

    def initialize file
      file = File.new file, 'a+' unless File === file
      @file = file
      @html = Html.new
      @lock = Mutex.new
    end

    def puts record
      lock.synchronize do
        html.add record
        File.open file, 'w+' do |f|
          f.puts html.to_s
        end
      end
    end

    class Html

      Template = File.expand_path('../template.html', __FILE__)

      attr_reader :base, :threads

      def initialize
        @base = File.open(Template) { |f| Nokogiri::HTML(f) }
        @threads = Set.new
      end

      def add record
        new_thread_fragment
        new_call_fragment record
        new_stack_fragment record
      end

      def new_thread_fragment
        return if threads.include?(id = Thread.current.object_id)
        thread = Nokogiri::HTML::DocumentFragment.parse <<-EOHTML
<li id='thread-#{id}'>
  <input type="checkbox" name=threads value='#{id}' checked='checked'>#{id}</input>
</li>
EOHTML
        base.at_css('.threads') << thread
        threads << id
      end

      def new_call_fragment record
        time = record.time.strftime "%F %T"
        call = Nokogiri::HTML::DocumentFragment.parse <<-EOHTML
<li id='call-#{record.object_id}' class='thread-#{Thread.current.object_id} call'>
  <span class='time'>#{time}</span><span class='class_and_method'>#{record.module}##{record.method_id}</span>
</li>
EOHTML
        base.at_css('.calls') << call
      end

      def new_stack_fragment record
        callers = record.callers.map do |c|
          class_and_method = CGI::escapeHTML "#{c.klass}#{c.call_symbol}#{c.frame_env}"
          "<p><span class='class_and_method'>#{class_and_method}</span><span class='location'>#{c.file}:#{c.line}</span></p>"
        end.join
        stack = "<li class='call-#{record.object_id}'>#{callers}</li>"
        base.at_css('.stacks') << stack
      end

      def to_s
        base.to_s
      end
    end
  end
end
