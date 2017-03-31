require 'caller_log/version'
require 'caller_log/log'
require 'binding_of_callers'
require 'dcr'

module CallerLog
  class << self

    def log *args
      raise ArgumentError,
        "wrong number of arguments (given #{args.count}, expected more than 1)" if args.count < 2
      log_file = args.pop
      objects = Array args

      log = Log.new log_file

      objects.each do |obj|

        callee = calling obj

        obj.instance_methods(false).each do |method_id|
          o_method = ref_old method_id
          obj.send :alias_method, o_method, method_id
          obj.send :define_method, method_id, &-> *para, &blk {
            record =  OpenStruct.new time: Time.now, callee: "#{callee}##{method_id}", callers: binding.of_callers[1..-1]
            log.puts record
            self.send o_method, *para, &blk
          }
        end if obj.is_a? Module

        obj.methods(false).each do |method_id|
          o_method = obj.method method_id
          obj.singleton_class.send :define_method, method_id, &-> *para, &blk {
            record =  OpenStruct.new time: Time.now, callee: "#{callee}.#{method_id}", callers: binding.of_callers[1..-1]
            log.puts record
            o_method.call *para, &blk
          }
        end

      end
    end

    def calling obj
      Module === obj ? "#{obj}" : "<#{obj.class}:#{obj.object_id}>"
    end

    def ref_old method_id
      "#{method_id}_caller_log"
    end
  end

end
