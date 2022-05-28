require 'erb'
require 'yaml'
require 'dotenv/load'
require 'telegram/bot'

token = ENV.delete('TELEGRAM_TOKEN')
raise 'NO TOKEN GIVEN' unless token

# LOAD LANGUAGE FILES

LANG = begin
  ENV.fetch('BOT_LANG')
rescue KeyError => e
  puts e
  puts 'Please set BOT_LANG key!'
  # default language is German
  'de'
end

def lang_filepath
  "./i18n/#{LANG}/"
end

def i18n_files
  Dir['./i18n/**/*.yml']
end

def i18n_dictionary
  i18n = {}
  i18n_files.each { |f| i18n.merge! YAML.load_file(f) }
  i18n
end

DICTIONARY = i18n_dictionary

# TEMPLATING

def i18n_yaml(*k)
  # PLEASE use `.yml` for your lang dictionaries
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

# MESSAGING

# send silent
def message_start(bot, message)
  bot.api.send_message(
    chat_id: message.chat.id,
    text: interpolate_template(i18n_messages(:start), binding),
    parse_mode: 'HTML',
    disable_notification: true
  )
  # start with checking the consciousness
  check_consciousness(bot, message)
end

def message_stop(bot, message)
  bot.api.send_message(
    chat_id: message.from.id,
    text: interpolate_template(i18n_messages(:stop), binding)
  )
end

# CONSCIOUSNESS

def conscious_instructions(bot, message)
  bot.api.send_photo(
    chat_id: message.from.id,
    photo: Faraday::UploadIO.new((lang_filepath + '/steps.jpg'), 'image/jpeg'),
    caption: 'Copyright: https://www.drk.de/fileadmin/_processed_/9/9/csm_auffinden-einer-person_7de371f707.jpg'
  )
end

def unconscious_instructions(bot, message)
  bot.api.send_photo(
    chat_id: message.from.id,
    photo: Faraday::UploadIO.new((lang_filepath + '/steps.jpg'), 'image/jpeg'),
    caption: 'Copyright: https://www.drk.de/fileadmin/_processed_/9/9/csm_auffinden-einer-person_7de371f707.jpg'
  )
end

# STABILIZING

def stabilize(bot, message)
  stabilize_message(bot, message)
  finish_with_calling_help(bot, message)
end

def stabilize_message(bot, message)
  # send with web preview disabled
  bot.api.send_message(
    chat_id: message.from.id,
    text: i18n_messages(:stabilize),
    parse_mode: 'HTML',
    disable_web_page_preview: true
  )
end

# CALL HELP / Instructions / Questions

def finish_with_calling_help(bot, message)
  # send with web preview disabled
  bot.api.send_message(
    chat_id: message.from.id,
    text: interpolate_template(i18n_messages(:finish), binding),
    parse_mode: 'HTML',
    disable_web_page_preview: true
  )
end

# CONSCIOUSNESS

def buttons_consciousness
  [Telegram::Bot::Types::InlineKeyboardButton.new(text: i18n_buttons(:consciousness, :ok),
                                                  callback_data: 'consciousness_yes'),
   Telegram::Bot::Types::InlineKeyboardButton.new(text: i18n_buttons(:consciousness, :not_ok),
                                                  callback_data: 'consciousness_no')]
end

def check_consciousness(bot, message)
  bot.api.send_message(
    chat_id: message.chat.id,
    disable_web_page_preview: true,
    text: i18n_messages(:consciousness),
    parse_mode: 'HTML',
    reply_markup: Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: buttons_consciousness)
  )
end

def unconscious_not_breathing_instructions(bot, message)
  bot.api.send_message(
    chat_id: message.from.id,
    disable_web_page_preview: true,
    parse_mode: 'HTML',
    text: i18n_messages(:unconscious_not_breathing)
  )
end

def unconscious_not_breathing_hint(bot, message)
  bot.api.send_message(
    chat_id: message.from.id,
    disable_web_page_preview: false,
    parse_mode: 'HTML',
    text: i18n_messages(:unconscious_not_breathing_hint)
  )
end

# BREATHING

def buttons_breathing
  [Telegram::Bot::Types::InlineKeyboardButton.new(text: i18n_buttons(:breathing, :ok),
                                                  callback_data: 'breathing_yes'),
   Telegram::Bot::Types::InlineKeyboardButton.new(text: i18n_buttons(:breathing, :not_ok),
                                                  callback_data: 'breathing_no')]
end

def check_breathing(bot, message)
  bot.api.send_message(
    chat_id: message.from.id,
    disable_web_page_preview: true,
    text: i18n_messages(:breathing_check),
    parse_mode: 'HTML',
    reply_markup: Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: buttons_breathing)
  )
end

# MAIN

Telegram::Bot::Client.run(token) do |bot|
  bot.listen do |message|
    case message
    when Telegram::Bot::Types::CallbackQuery
      # Here you can handle your callbacks from inline buttons
      case message.data
      when 'consciousness_yes'
        conscious_instructions(bot, message)
        finish_with_calling_help(bot, message)
      when 'consciousness_no'
        unconscious_instructions(bot, message)
        check_breathing(bot, message)
      when 'breathing_yes'
        stabilize(bot, message)
      when 'breathing_no'
        unconscious_not_breathing_instructions(bot, message)
        unconscious_not_breathing_hint(bot, message)
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
