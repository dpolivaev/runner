# frozen_string_literal: true
require_relative 'time_out_runner'

class Runner

  def initialize(externals)
    @externals = externals
  end

  def alive?
    { 'alive?' => true }
  end

  def ready?
    { 'ready?' => true }
  end

  def sha
    { 'sha' => ENV['SHA'] }
  end

  def run_cyber_dojo_sh(image_name, id, files, max_seconds)
    manifest = { image_name:image_name, max_seconds:max_seconds };
    TimeOutRunner.new(@externals, id, files, manifest).run_cyber_dojo_sh
  end

end
