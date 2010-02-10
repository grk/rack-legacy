module Rack
  module Legacy
    class Cgi

      # Will setup a new instance of the Cgi middleware executing
      # programs located in the given public_dir
      #
      #   use Rack::Legacy::Cgi, 'cgi-bin'
      def initialize(app, public_dir)
        @app = app
        @public_dir = public_dir
      end

      # Middleware, so if it looks like we can run it then do so.
      # Otherwise send it on for someone else to handle.
      def call(env)
        if valid? env['PATH_INFO']
          run env, full_path(env['PATH_INFO'])
        else
          @app.call env
        end
      end
  
      # Check to ensure the path exists and it is a child of the
      # public directory.
      def valid?(path)
        full_path(path).start_with?(::File.expand_path @public_dir) &&
        ::File.exist?(full_path(path))
      end
  
      protected

      # Returns the path with the public_dir pre-pended and with the
      # paths expanded (so we can check for security issues)
      def full_path(path)
        ::File.expand_path ::File.join(@public_dir, path)
      end

      # Will run the given path with the given environment
      def run(env, path)
        status = 200
        headers = {}
        body = ''

        IO.popen('-') do |io|
          if io.nil?  # Child
            env.each {|k, v| ENV[k] = v if v.respond_to? :to_str}
            exec path
          else        # Parent
            while (line = io.readline.chomp) != ""
              key, value = line.split /\s*\:\s*/
              headers[key] = value
            end
            body = io.read
          end
        end
  
        [status, headers, body]
      end
    end
  end
end