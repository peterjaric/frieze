# Frieze

Frieze is a (mostly silly) shell tool for generating and displaying AI-generated banner images and slogans in your terminal.

## Screenshot

![screenshot](screenshot.png){ width=800 }

## Setup

### Prerequisites

- **ImageMagick** (`magick` or `convert` command)
- **jq**
- **curl**
- **tiv** (TerminalImageViewer for displaying images)
- A (free) [Imagerouter](https://imagerouter.com/) API account and a (free) [Mistral](https://mistral.ai/) API account

If the script is run and a dependency is missing, it will print an error message indicating which command is not found and how to get it.

### Configuration

Included is a file config.env which contains a default configuration.

If using the default configuration, create a folder named `.frieze` in your home directory. In that directory, create a `.env` file and add two variables to it:

```env
IMAGEROUTER_KEY=<your imagerouter key>
MISTRAL_API_KEY=<your mistral api key>
```

## Usage

Run the script with one of the following commands:

- **Generate a new banner image:**

  ```sh
  frieze.sh generate
  ```

  This will create a new AI-generated image and save it to the image folder. The script returns at once, but continues creating the image in the background.

- **Display the latest banner image in your terminal:**

  ```sh
  frieze.sh display
  ```

You can put calls to these commands in for examnple your .zshrc or .bashrc to have a new banner image generated and displayed each time you open a terminal.

## Changing the backing APIs

It is possible to change which AI APIs are used. To change which text generation API is used, create a new script modeled on mistral.sh, but using your preferred API. Then change the TEXT_SCRIPT variable in config.env to point to your new script. Make sure any required KEY variables are set in your .env file.

The same goes for the image generation API - create a new script modeled on imagerouter.sh and change the IMAGE_SCRIPT variable in config.env.

## License

MIT
