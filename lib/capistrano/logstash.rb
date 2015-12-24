# encoding: utf-8

require "capistrano/logstash/version"
require "capistrano"
require "redis"

class LogstashInterface
  def initialize(action)
    @redis_key = fetch(:logstash_redis_key, "capistrano_logstash")

    @attributes = {
      action: action,
      application: fetch(:application),
      revision: fetch(:current_revision),
      user: fetch(:local_user),
      repo: fetch(:repo_url),
      branch: fetch(:branch),
      stage: fetch(:stage)
    }
  end

  def notify
    begin
      unless redis_client.rpush(@redis_key, @attributes.to_json)
        raise "could not send event to redis"
      end
    rescue ::Redis::InheritedError
      redis_client.client.connect
      retry
    end
  end

private

  def redis_client
    @redis_client ||= Redis.new(
      host: fetch(:logtash_redis_url, "127.0.0.1"),
      password: fetch(:logtash_redis_password),
      port: fetch(:logstash_redis_port, 6379),
      timeout: 1
    )
  end
end

namespace :deploy do
  desc "Post an event to Logstash"
  task :notify_logstash, :action do |_, args|
    action = args[:action]
    LogstashInterface.new(action).notify
    info("#{action.capitalize} event posted to logstash")
  end

  after "deploy_finished", "notify_logstash_deploy" do
    invoke("deploy:notify_logstash", "deploy")
  end
  after "deploy_finished", "notify_logstash_rollback" do
    invoke("deploy:notify_logstash", "rollback")
  end
end
