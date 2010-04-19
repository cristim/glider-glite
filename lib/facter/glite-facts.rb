# java_location.rb
require "pathname"

Facter.add("java_location") do
    setcode do
        if File.exist?("/usr/bin/java")
            Pathname.new("/usr/bin/java").realpath.to_s.gsub("bin\/java","").chomp
        end
    end
end

Facter.add("torque_version") do
    setcode do
        %x{/bin/rpm -qa torque}.chomp
    end
end

Facter.add("mpich_location") do
    setcode do
        `/bin/rpm -ql mpich | head -1`.chomp
    end
end


Facter.add("mpich_version") do
    setcode do
    Facter.loadfacts()
        Facter.value('mpich_location').dup.gsub(/^.*-/,"").chomp
    end
end

