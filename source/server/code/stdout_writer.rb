# frozen_string_literal: true

class StdoutWriter

  def write(message)
    return if message.empty?
    message += "\n" if message[-1] != "\n"
    $stdout.write(message)
  end

end
