module RexPort
  class Child
    attr_reader :pid, :reader, :writer, :error_reader, :child_config

    def initialize(pid, reader, writer, error_reader, child_config)
      @pid = pid
      @reader = reader
      @writer = writer
      @error_reader = error_reader
      @child_config = child_config
    end

    def request(message)
      tell(message)
      listen
    end

    def kill!
      @writer.close
      @reader.close
      @error_reader.close
      begin
        Process.kill(9, @pid)
        Process.waitpid(@pid)
      rescue Errno::ECHILD, Errno::ESRCH
      end
    end

    protected

    def tell(message)
      packet_size = [message.bytesize].pack("l>*")
      @writer.write(packet_size)
      @writer.write(message)
      @writer.flush
    end

    def listen
      readable = IO.select([@reader, @error_reader], [], [@error_reader], @child_config.timeout)
      unless readable
        reconnect!
        raise Errors::ResponseTimeoutError, "process timeout!"
      end

      first_readable_array = readable.detect { |item| !item.empty? }
      if first_readable_array.first.fileno == @error_reader.fileno
        read = first_readable_array.first.read_nonblock(2**24)
        STDERR.puts read
        reconnect!
        raise Errors::ResponseReadError, read
      end

      packet_response_size = @reader.read(4)
      read_size = packet_response_size.unpack("L>*")
      read_buff = @reader.read(read_size.first)
      check_result = check_process_death("run")
      unless check_result.empty?
        reconnect!
        raise Errors::ResponseReadError, "process crashed:\n#{check_result.last}"
      end
      read_buff
    end

    def check_process_death(stage = "boot")
      pid_status = nil
      begin
        pid_status = Process.waitpid(@pid, Process::WNOHANG)
        return [] unless pid_status
      rescue Errno::ECHILD
        pid_status = -1
      end
      read_death_data = @error_reader.read_nonblock(2**16)
      [pid_status, read_death_data]
    end

    def reconnect!
      kill!
      @pid, @reader, @writer, @error_writer = @child_config.boot!
    end
  end
end
