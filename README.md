# RedeemerRichEditHTML
Delphi units to convert between HTML and Delphi's TRichEdit

Can also convert HTML to plain text, with optional use of Unicode's _Mathematical Alphanumeric Symbols_ block for displaying a limited set of characters[^1] in bold and/or italic (all three in sans-serif only)

## Supported tags
The units are mainly supposed to be able to read and write their own HTML code, offering a low-overhead way of storing formatted text in a database.

Supported/used tags are:
* `<b>`
* `<i>`
* `<u>`
* `<s>`
* `<span>` (for color via the `style` attribute)[^2][^3]
* `<ul>`
* `<li>`[^4]

### Unsupported features of TRichEdit
Not all features offered by the TRichEdit shipped with Delphi are currently supported by this project. This is because they weren't needed or even considered counterproductive for the application for which these units were originally created. This affects the following features of TRichEdit:
* Support for font size was intentionally omitted to not have to deal with screen scaling.
* Support for fonts was omitted to prevent users from creating markup that's overly fancy.
* Support for alignment, tab stops or indents was not included because it was not needed.
* Additions to `TTextAttributes` in more recent versions of Delphi, because this was originally created with Delphi 2010.

You are - of course - welcome to add (optional) support for these features.

## Supported HTML
HTML output is without any doctype, headers or surrounding tags.

The units support all HTML entities (including those where the trailing semicolon is optional) for HTML input. Unsupported HTML tags are discarded. `style` is parsed completely, with properties other than `color` being discarded. Non-XML HTML is supported.

## Usage
All relevant methods are in `RedeemerRichEditHTML`:
- **`procedure`** `HTMLToRichEdit`
  - Arguments:
    - `HTML: string`: HTML code to be converted.
    - `RichEdit: TRichEdit`: Target TRichEdit control to receive the output. Clearing it is the first thing this method does before adding any content from the provided `HTML` argument.
- **`function`** `RichEditToHTML`
  - Argument:
    - `RichEdit: TRichEdit`: Source TRichEdit control to be used as input. Content is left untouched, but the cursor is moved.
  - Returned `string`: The HTML code of the source RichEdit's content.
- **`function`** `HTMLToPlaintext`
  - Arguments:
    - `HTML: string`: HTML code to be converted.
    - `UseUnicodeForStyle: Boolean`: Pass `True` to use the Unicode block _Mathematical Alphanumeric Symbols_ for bold and/or italic sans-serif text. Note that Unicode expressly [does not recommended](https://www.unicode.org/versions/Unicode13.0.0/ch22.pdf#G15993) the symbols to be used like that - but it might still look nice depending on what you are doing. Only a limited set of characters is available.[^1]
  - Returned `string`: Plain text representation of the HTML code provided via the `HTML` argument. Converts `<br>` into newlines. Other tags are ignored, except for `<b>` and `<i>` if the `UseUnicodeForStyle` option is used.

## Requirements
This is supposed to compile with Delphi 2009 and up. It does not require any units that do not come with Delphi's default installation.

## Other notes
Code may contain traces of German, swears and irony.

## Copyright
Copyright © 2011, 2017-2021 Janni "Redeemer" K.

[^1]: Characters included in said Unicode block for the three styles supported by this method:
      | Format                     | Digits                   | Latin basic alphabet | Greek basic alphabet | Nabla symbol
      | -------------------------- | ------------------------ | -------------------- | -------------------- | ------------
      | **sans-serif bold**        | ✔️                       | ✔️                  | ✔️                   | ✔️
      | **sans-serif italic**      | ❌ left untouched        | ✔️                  | ❌ left untouched    | ❌ left untouched
      | **sans-serif bold italic** | ⚠️ fallback to bold only | ✔️                  | ✔️                   | ✔️
[^2]: Supports nesting `<span>` tags.
[^3]: Supports all named colors, including `rebeccapurple`.
[^4]: Supports multiline `<li>`, created by pressing <kbd>Shift</kbd>+<kbd>Enter</kbd> in your `TRichEdit`, which Windows internally handles as `#11` (for Vertical Tab). Does not support nesting. Does support unclosed `<li>` tags.
