require 'erb'
require 'yaml'
require 'dotenv/load'
require 'telegram/bot'

token = ENV.delete('TELEGRAM_TOKEN')
raise 'NO TOKEN GIVEN' unless token

LANG = begin
  ENV.fetch('BOT_LANG')
rescue StandardError
  'de' # default language is german
end

def lang_filepath
  "./i18n/#{LANG}/"
end

def i18n_files
  Dir['./i18n/**/*.yml']
end

def i18n_dictionary
  i18n = {}
  i18n_files.each do |d|
    i18n.merge! YAML.load_file(d)
  end
  i18n
end

DICTIONARY = i18n_dictionary

# PLEASE use `.yml` for your lang dictionaries
def i18n_yaml(*k)
  key_strings ||= k.map(&:to_s)
  DICTIONARY.dig(LANG, *key_strings)
end

def i18n_messages(*k)
  i18n_keys = [:messages, *k]
  i18n_yaml(*i18n_keys)
end

def i18n_buttons(*k)
  i18n_keys = [:buttons, *k]
  i18n_yaml(*i18n_keys)
end

def interpolate_template(yaml_content, method_as_binding)
  ERB.new(yaml_content).result(method_as_binding)
end

def message_start(bot, message)
  name = message.from.first_name
  text = interpolate_template(i18n_messages(:start), binding)
  bot.api.send_message(chat_id: message.chat.id,
                       text:,
                       parse_mode: 'HTML',
                       disable_notification: true)
  # start with checking the consciousness
  check_consciousness(bot, message)
end

def stabilize_message(bot, message)
  text = i18n_messages(:stabilize)
  bot.api.send_message(chat_id: message.from.id,
                       text:,
                       parse_mode: 'HTML',
                       disable_web_page_preview: true)
end

def finish_with_calling_help(bot, message)
  name = message.from.first_name
  text = interpolate_template(i18n_messages(:finish), binding)
  bot.api.send_message(chat_id: message.from.id,
                       text:,
                       parse_mode: 'HTML',
                       disable_web_page_preview: true)
end

def buttons_consciousnes
  button_yes = i18n_buttons(:consciousness, :ok)
  button_no = i18n_buttons(:consciousness, :not_ok)
  [Telegram::Bot::Types::InlineKeyboardButton.new(text: button_yes,
                                                  callback_data: 'con_yes'),
   Telegram::Bot::Types::InlineKeyboardButton.new(text: button_no,
                                                  callback_data: 'con_no')]
end

def check_consciousness(bot, message)
  markup = Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: buttons_consciousnes)
  text = i18n_messages(:consciousness)
  bot.api.send_message(chat_id: message.chat.id,
                       disable_web_page_preview: true,
                       text:,
                       parse_mode: 'HTML',
                       reply_markup: markup)
end

def message_stop(bot, message)
  name = message.from.first_name
  text = interpolate_template(i18n_messages(:stop), binding)
  bot.api.send_message(chat_id: message.from.id, text:)
end

def stabilize(bot, message)
  stabilize_message(bot, message)
  finish_with_calling_help(bot, message)
end

def buttons_breathing
  button_yes = i18n_buttons(:breathing, :ok)
  button_no = i18n_buttons(:breathing, :not_ok)
  [Telegram::Bot::Types::InlineKeyboardButton.new(text: button_yes,
                                                  callback_data: 'breathing_yes'),
   Telegram::Bot::Types::InlineKeyboardButton.new(text: button_no,
                                                  callback_data: 'breathing_no')]
end

def check_breathing(bot, message)
  markup = Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: buttons_breathing)
  text = i18n_messages(:breathing_check)
  bot.api.send_message(chat_id: message.from.id,
                       disable_web_page_preview: true,
                       text:,
                       parse_mode: 'HTML',
                       reply_markup: markup)
end

Telegram::Bot::Client.run(token) do |bot|
  bot.listen do |message|
    case message
    when Telegram::Bot::Types::CallbackQuery
      # Here you can handle your callbacks from inline buttons
      case message.data
      when 'con_yes'
        bot.api.send_photo(chat_id: message.from.id,
                           photo: Faraday::UploadIO.new((lang_filepath + '/steps.jpg'), 'image/jpeg'),
                           caption: 'Copyright: https://www.drk.de/fileadmin/_processed_/9/9/csm_auffinden-einer-person_7de371f707.jpg')

        # thankfully the injured is conscious
        finish_with_calling_help(bot, message)
      when 'con_no'
        bot.api.send_photo(chat_id: message.from.id,
                           photo: Faraday::UploadIO.new((lang_filepath + '/steps.jpg'), 'image/jpeg'),
                           caption: 'Copyright: https://www.drk.de/fileadmin/_processed_/9/9/csm_auffinden-einer-person_7de371f707.jpg')
        check_breathing(bot, message)
      when 'breathing_yes'
        stabilize(bot, message)
      when 'breathing_no'
        text = i18n_messages(:unconscious_not_breathing)
        bot.api.send_message(chat_id: message.from.id,
                             disable_web_page_preview: true,
                             parse_mode: 'HTML',
                             text:)

        text = i18n_messages(:unconscious_not_breathing_hint)
        bot.api.send_message(chat_id: message.from.id,
                             disable_web_page_preview: false,
                             parse_mode: 'HTML',
                             text:)
      end
    when Telegram::Bot::Types::Message
      # Here you can handle your callbacks from messages
      case message.text
      when '/start'
        message_start(bot, message)
      when '/stop'
        message_stop(bot, message)
      end
    end
  end
end
