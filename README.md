# First Aid Interactive Tutorial Bot for telegram

this is a very simple first aid teaching bot. It is easily extendable for other languages.

The bot primarily aims to be a sort of refresh tutorial. But could be used as a guide in a situation of emergency, too.

It is interactive with buttons, following the medical predefined path of action.

## Environment / Setup

Please [setup a telegram bot](https://core.telegram.org/bots) for you to test. Then provide the given key via ENV (see below).

- Ruby v3.1
- `$ bundle install`
- setup Environment variables
  - Create a `.env` in your clone project and check out `.env.sample` for what keys you need to set.
  - Copy the bots API key to the `.env`
- developers using VSCode can run the tool via debug

### Dependencies/Gems

- [dotenv](https://github.com/bkeepers/dotenv)
- [telegram-bot-ruby](https://github.com/atipugin/telegram-bot-ruby)

## Roadmap

- [ ] provide a really nice Readme
- [ ] clean up code base
- [ ] get feedback from German Red Cross
- [ ] better breathing instructions
- [ ] more languages
  - [x] German (de)
  - [x] English (en)
  - [ ] italiano (it)
  - [ ] French (fr)
  - [ ] Spanish (es)
  - [ ] Portuguese (pt)
  - [ ] many more...
