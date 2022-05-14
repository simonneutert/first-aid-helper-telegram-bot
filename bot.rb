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

# PLEASE use `.yml` for your lang dictionaries
def select_lang(*k)
  dictionary = YAML.load_file(lang_filepath + "#{LANG}.yml")
  key_strings = k.map(&:to_s)
  dictionary.dig(LANG, *key_strings)
end

def interpolate_template(yaml_content, method_as_binding)
  ERB.new(yaml_content).result(method_as_binding)
end

def message_start(bot, message)
  name = message.from.first_name
  text = interpolate_template(select_lang(:messages, :start), binding)
  bot.api.send_message(chat_id: message.chat.id,
                       text:,
                       parse_mode: 'HTML',
                       disable_notification: true)

  check_consciousnes(bot, message)
end

def stabilize_message(bot, message)
  bot.api.send_message(chat_id: message.from.id,
                       text: select_lang(:messages, :stabilize),
                       parse_mode: 'HTML',
                       disable_web_page_preview: true)
end

def finish_with_calling_help(bot, message)
  name = message.from.first_name
  text = interpolate_template(select_lang(:messages, :finish), binding)

  bot.api.send_message(chat_id: message.from.id,
                       text:,
                       parse_mode: 'HTML',
                       disable_web_page_preview: true)
end

def buttons_consciousnes
  button_yes = select_lang(:buttons, :consciousness, :ok)
  button_no = select_lang(:buttons, :consciousness, :not_ok)
  [Telegram::Bot::Types::InlineKeyboardButton.new(text: button_yes,
                                                  callback_data: 'con_yes'),
   Telegram::Bot::Types::InlineKeyboardButton.new(text: button_no,
                                                  callback_data: 'con_no')]
end

def check_consciousnes(bot, message)
  markup = Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: buttons_consciousnes)
  text = select_lang(:messages, :consciousness)
  bot.api.send_message(chat_id: message.chat.id,
                       disable_web_page_preview: true,
                       text:,
                       parse_mode: 'HTML',
                       reply_markup: markup)
end

def message_stop(bot, message)
  name = message.from.first_name
  text = interpolate_template(select_lang(:messages, :stop), binding)
  bot.api.send_message(chat_id: message.from.id, text:)
end

def stabilize(bot, message)
  stabilize_message(bot, message)
  finish_with_calling_help(bot, message)
end

def buttons_breathing
  button_yes = select_lang(:buttons, :breathing, :ok)
  button_no = select_lang(:buttons, :breathing, :not_ok)
  [Telegram::Bot::Types::InlineKeyboardButton.new(text: button_yes,
                                                  callback_data: 'breathing_yes'),
   Telegram::Bot::Types::InlineKeyboardButton.new(text: button_no,
                                                  callback_data: 'breathing_no')]
end

def check_breathing(bot, message)
  markup = Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: buttons_breathing)
  text = select_lang(:messages, :breathing_check)
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
        bot.api.send_photo(chat_id: message.from.id, photo: Faraday::UploadIO.new((lang_filepath + '/steps.jpg'), 'image/jpeg'),
                           caption: 'Copyright: https://www.drk.de/fileadmin/_processed_/9/9/csm_auffinden-einer-person_7de371f707.jpg')
        finish_with_calling_help(bot, message)
      when 'con_no'
        bot.api.send_photo(chat_id: message.from.id,
                           photo: Faraday::UploadIO.new((lang_filepath + '/steps.jpg'),
                                                        'image/jpeg'))
        check_breathing(bot, message)
      when 'breathing_yes'
        stabilize(bot, message)
      when 'breathing_no'
        text = select_lang(:messages, :unconscious_not_breathing)
        bot.api.send_message(chat_id: message.from.id,
                             disable_web_page_preview: true,
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
