module VagrantVbguest
  module Hosts
    class VirtualBox < Base

      protected

        # Default web URI, where GuestAdditions iso file can be downloaded.
        #
        # @return [String] A URI template containing the versions placeholder.
        def web_path
          "http://download.virtualbox.org/virtualbox/%{version}/VBoxGuestAdditions_%{version}.iso"
        end


        # Finds GuestAdditions iso file on the host system.
        # Returns +nil+ if none found.
        #
        # @return [String] Absolute path to the local GuestAdditions iso file, or +nil+ if not found.
        def local_path
          media_manager_iso || guess_local_iso
        end

      private

        # Helper method which queries the VirtualBox media manager
        # for a +VBoxGuestAdditions.iso+ file.
        # Returns +nil+ if none found.
        #
        # @return [String] Absolute path to the local GuestAdditions iso file, or +nil+ if not found.
        def media_manager_iso
          (m = driver.execute('list', 'dvds').match(/^.+:\s+(.*VBoxGuestAdditions(?:_#{version})?\.iso)$/i)) && m[1]
        end

        # Find the first GuestAdditions iso file which exists on the host system
        #
        # @return [String] Absolute path to the local GuestAdditions iso file, or +nil+ if not found.
        def guess_local_iso
          Array(platform_path).find do |path|
            path && File.exists?(path)
          end
        end

        # Makes an educated guess where the GuestAdditions iso file
        # could be found on the host system depending on the OS.
        # Returns +nil+ if no the file is not in it's place.
        def platform_path
          [:linux, :darwin, :cygwin, :windows].each do |sys|
            return self.send("#{sys}_path") if Vagrant::Util::Platform.respond_to?("#{sys}?") && Vagrant::Util::Platform.send("#{sys}?")
          end
          nil
        end

        # Makes an educated guess where the GuestAdditions iso file
        # on linux based systems
        def linux_path
          paths = ["/usr/share/virtualbox/VBoxGuestAdditions.iso"]
          paths.unshift(File.join(ENV['HOME'], '.VirtualBox', "VBoxGuestAdditions_#{version}.iso")) if ENV['HOME']
          paths
        end

        # Makes an educated guess where the GuestAdditions iso file
        # on Macs
        def darwin_path
          "/Applications/VirtualBox.app/Contents/MacOS/VBoxGuestAdditions.iso"
        end

        # Makes an educated guess where the GuestAdditions iso file
        # on windows systems
        def windows_path
          if (p = ENV["VBOX_INSTALL_PATH"]) && !p.empty?
            File.join(p, "VBoxGuestAdditions.iso")
          elsif (p = ENV["PROGRAM_FILES"] || ENV["ProgramW6432"] || ENV["PROGRAMFILES"]) && !p.empty?
            File.join(p, "/Oracle/VirtualBox/VBoxGuestAdditions.iso")
          end
        end
        alias_method :cygwin_path, :windows_path

        # overwrite the default version string to allow lagacy
        # '$VBOX_VERSION' as a placerholder
        def versionize(path)
          super(path.gsub('$VBOX_VERSION', version))
        end

    end
  end
end
