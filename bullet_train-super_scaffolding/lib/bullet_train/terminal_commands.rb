module TerminalCommands
  def self.open_file_or_link(file_or_link, options = {})
    command = if macosx?
      "open"
    elsif linux?
      "xdg-open"
    end
    `#{command} #{file_or_link}`
  end

  def self.os
    Gem::Platform.local.os
  end

  def self.macosx?
    os == macosx
  end

  def self.linux?
    os == linux
  end

  def self.can_open?
    (TerminalCommands.macosx? && `which open`.present?) ||
      (TerminalCommands.linux? && `which xdg-open`.present?)
  end

  def self.macosx
    "darwin"
  end

  def self.linux
    "linux"
  end
end
