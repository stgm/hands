require "exception_notification/rails"

ExceptionNotification.configure do |config|
  # Only mail production failures
  config.ignore_if do |exception, options|
    Rails.env.local?
  end

  config.ignore_crawlers %w[Googlebot bingbot]

  config.add_notifier :email, {
    email_prefix: "[hands ERROR] ",
    sender_address: ENV.fetch("MAILER_FROM", %("Proglab Help" <help@proglab.nl>)),
    exception_recipients: ENV.fetch("ERROR_RECIPIENTS", "m.stegeman@uva.nl").split(",")
  }
end
