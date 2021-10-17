# purescript-html-codegen-halogen [![GitHub](https://img.shields.io/github/license/ongyiren1994/purescript-html-codegen-halogen)](https://github.com/ongyiren1994/purescript-html-codegen-halogen/blob/master/LICENSE) [<img src="https://pursuit.purescript.org/packages/purescript-html-codegen-halogen/badge" alt="purescript-html-codegen-halogen on Pursuit"> </img>](https://pursuit.purescript.org/packages/purescript-html-codegen-halogen)

## Usage

This library allows user to convert minified html to halogen codes to speed up the development.
Below is an usage example
```
PSCi, version 0.14.0
Type :? for help

import Prelude

> import Html.Codegen.Halogen
> renderHalogenCodes "example.html"
HH.div_ [ HH.h1_ [ HH.text "This is a heading" ], HH.p_ [ HH.text "This is a paragraph." ], HH.text "
" ]

>
```

## Download and Installation

Install

```bash
bower install https://github.com/ongyiren1994/purescript-html-codegen-halogen.git
```
</br>

## Documentation

Module documentation is [published on Pursuit](http://pursuit.purescript.org/packages/purescript-html-codegen-halogen).
</br></br>

## License

Check [LICENSE](LICENSE) file for more information.