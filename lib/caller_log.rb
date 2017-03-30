require 'caller_log/version'
require 'caller_log/log'
require 'binding_of_callers'
require 'dcr'

module CallerLog
  class << self

    def instance *args
      raise ArgumentError,
        "wrong number of arguments (given #{args.count}, expected more than 1)" if args.count < 2
      log_file = args.pop
      modules = Array args

      log = Log.new log_file

      modules.each do |mod|
        mod.instance_methods(false).each do |method_id|
          Dcr.instance mod, method_id do |method, *para, &blk|
            record =  OpenStruct.new time: Time.now, module: mod, method_id: method_id, callers: binding.of_callers[2..-1]
            log.puts record
            method.call *para, &blk
          end
        end
      end
    end
  end

end
