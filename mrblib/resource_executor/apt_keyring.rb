module ::MItamae
  module Plugin
    module ResourceExecutor
      class AptKeyring < ::MItamae::ResourceExecutor::Base
        DownloadError = Class.new(StandardError)
        ImportError = Class.new(StandardError)
        RemoveError = Class.new(StandardError)

        def apply
          if current.exists && desired.exists
            # ignore
          elsif !current.exists && desired.exists
            additional_keyring
          elsif current.exists && !desired.exists
            removal_keyring
          elsif !current.exists && !desired.exists
            # ignore
          end
        end

        private

        @finger = ''

        def set_current_attributes(current, action)
          @finger ||= desired.finger.gsub(' ', '')
          @finger ||= desired.name.gsub(' ', '')

          result = run_command(['apt-key', 'finger', @finger])

          case action
          when :install
            if result.stdout != ''
              current.exists = true
            else
              current.exists = false
            end
          when :remove
            current.exists = false
          end
        end

        def set_desired_attributes(desired, action)
          case action
          when :install
            desired.exists = true
          when :remove
            desired.exists = false
          end
        end

        def additional_keyring
          unless file = search_keyring
            if attributes.uri.kind_of?(String) and attributes.uri.match(/^https?:\/\//)
              file = download_keyring(attributes.uri)
            else
              if attributes.keyserver.kind_of?(String) and attributes.keyserver.match(/^https?:\/\//)
                file = download_keyring("#{attributes.keyserver}/pks/lookup?op=get&options=mr&search=0x#{@finger}")
              else
                file = download_keyring("https://keyserver.ubuntu.com/pks/lookup?op=get&options=mr&search=0x#{@finger}")
              end
            end
          end

          import_keyring(file)

          return
        end

        def removal_keyring
          run_command(['apt-key', 'del', @finger], error: false)
        end

        def search_keyring
          result = nil

          files = [
            File.join(@resource.recipe.dir, 'keyrings', "#{@finger}.asc"),
            File.join(@resource.recipe.dir, 'keyrings', "#{@finger}.gpg"),
            File.join(@resource.recipe.dir, 'keyrings', "#{@finger}.key"),
          ]

          files.each do |file|
            if File.exists?(file)
              result = file
              break
            end
          end

          return result
        end

        def download_keyring(uri)
          result = run_command(['curl', '-fsSL', uri], error: false)

          if result.success?
            File.open("/tmp/apt-key-#{@finger}", 'w+') do |file|
              file.write(result.stdout)
            end
          else
            raise DownloadError, "apt-key download error (uri: #{uri})"
          end

          return "/tmp/apt-key-#{@finger}"
        end

        def import_keyring(path)
          result = run_command(['apt-key', 'add', path], error: false)

          if result.success?
            return
          else
            raise ImportError, "apt-key import error (file path: #{path})"
          end
        end
      end
    end
  end
end
