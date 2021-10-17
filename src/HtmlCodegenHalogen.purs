module Html.Codegen.Halogen where

import Prelude
import Data.Array (elem, filter, fromFoldable, mapWithIndex, replicate)
import Data.Either (Either(..))
import Data.List (List)
import Data.String (Pattern(..), joinWith, split)
import Effect (Effect)
import Effect.Console (log)
import Effect.Exception (throw)
import Effect.Unsafe (unsafePerformEffect)
import Html.Parser (Element, HtmlAttribute(..), HtmlNode(..), parse)
import Node.Encoding (Encoding(..))
import Node.FS.Sync (readTextFile, writeTextFile)
import Node.Path (FilePath)

renderHalogenCodes :: FilePath -> Effect Unit
renderHalogenCodes filePath = do
  content <- readTextFile UTF8 filePath
  case parse content of
    Left error -> log $ show error
    Right htmlNodes -> log $ renderInitialNode htmlNodes

renderHalogenCodesToFile :: FilePath -> Effect Unit
renderHalogenCodesToFile filePath = do
  content <- readTextFile UTF8 filePath
  case parse content of
    Left error -> log $ show error
    Right htmlNodes -> writeTextFile UTF8 (filePath <> ".purs") $ renderInitialNode htmlNodes

renderHalogenCodesWithIndent :: FilePath -> Effect Unit
renderHalogenCodesWithIndent filePath = do
  content <- readTextFile UTF8 filePath
  case parse content of
    Left error -> log $ show error
    Right htmlNodes -> log $ joinWith "" $ mapWithIndex addPrefix $ split (Pattern ("] [")) $ renderInitialNode htmlNodes

renderHalogenCodesWithIndentToFile :: FilePath -> Effect Unit
renderHalogenCodesWithIndentToFile filePath = do
  content <- readTextFile UTF8 filePath
  case parse content of
    Left error -> log $ show error
    Right htmlNodes -> writeTextFile UTF8 (filePath <> ".purs") $ joinWith "" $ mapWithIndex addPrefix $ split (Pattern ("] [")) $ renderInitialNode htmlNodes

addPrefix :: Int -> String -> String
addPrefix index element = (if index == 0 then "" else "][\n") <> (joinWith "" (replicate index " ")) <> element

renderInitialNode :: List HtmlNode -> String
renderInitialNode htmlNodes = "HH.div_ [ " <> renderHtmlNodes htmlNodes <> " ]"

renderHtmlNodes :: List HtmlNode -> String
renderHtmlNodes htmlNodes = joinWith ", " (filter ((/=) "COMMENT") (map renderHtmlNode $ fromFoldable htmlNodes))

renderHtmlNode :: HtmlNode -> String
renderHtmlNode htmlNode = case htmlNode of
  HtmlElement element -> renderElement element
  HtmlText text -> "HH.text " <> "\"" <> text <> "\""
  HtmlComment comment -> "COMMENT"

renderElement :: Element -> String
renderElement element = renderElementName element.name <> renderHtmlAttributes <> optionalRenderHtmlNodes
  where
  renderHtmlAttributes = case map renderHtmlAttribute $ fromFoldable element.attributes of
    [] -> "_ "
    htmlAttributesList -> " [ " <> joinWith "," htmlAttributesList <> " ] "

  optionalRenderHtmlNodes = if element.name `elem` defaultElementNameLeafs then "" else "[ " <> renderHtmlNodes element.children <> " ]"

renderElementName :: String -> String
renderElementName elementName = if elementName `elem` defaultElementName then "HH." <> elementName else "HH.element (HH.ElemName \"" <> elementName <> "\")"

renderHtmlAttribute :: HtmlAttribute -> String
renderHtmlAttribute (HtmlAttribute k v) = case checkAttributeNameParam (HtmlAttribute k v) of
  ClassParam -> renderClassAttribute v
  CustomParam -> "HP.attr (HH.AttrName \"" <> k <> "\") \"" <> v <> "\""
  FormMethodParam -> case v of
    "get" -> "HP.method (HP.FormMethod HP.GET)"
    "post" -> "HP.method (HP.FormMethod HP.POST)"
    _ -> unsafePerformEffect <<< throw $ "The method must be either get or post"
  PreloadValueParam -> case v of
    "none" -> "HP.preload HP.PreloadNone"
    "auto" -> "HP.preload HP.PreloadAuto"
    "metadata" -> "HP.preload HP.PreloadMetadata"
    _ -> unsafePerformEffect <<< throw $ "The preload must be either none, auto or metadata"
  ScopeValueParam -> case v of
    "row" -> "HP.scope HP.ScopeRow"
    "col" -> "HP.scope HP.ScopeCol"
    "rowgroup" -> "HP.scope HP.ScopeRowGroup"
    "colgroup" -> "HP.scope HP.ScopeColGroup"
    "auto" -> "HP.scope HP.ScopeAuto"
    _ -> unsafePerformEffect <<< throw $ "The scope must be either row, col, rowgroup, colgroup or auto"
  StepValueParam -> case v of
    "any" -> "HP.StepValue HP.Any"
    step -> "HP.StepValue (HP.Step " <> step <> ")"
  StringParam -> "HP." <> k <> " \"" <> v <> "\""
  _ -> "HP." <> k <> " " <> v

renderClassAttribute :: String -> String
renderClassAttribute classes = case (filter ((/=) "") (split (Pattern " ") classes)) of
  [] -> "HP.classes []"
  [ x ] -> "HP.class_ (HH.ClassName \"" <> x <> "\")"
  x -> "HP.classes (map HH.ClassName [ " <> (joinWith ", " $ map (\y -> "\"" <> y <> "\"") x) <> " ])"

-- | Some are commented out as it requires Type Constructors from other modules
data AttributeNameParam
  = ClassParam
  | FormMethodParam
  -- | RefLabelParam
  -- | MediaTypeParam
  -- | TypeValueParam
  -- | InputAcceptTypeParam
  | PreloadValueParam
  | ScopeValueParam
  | StepValueParam
  | StringParam
  | BooleanParam
  | NumberParam
  | IntParam
  | CustomParam

checkAttributeNameParam :: HtmlAttribute -> AttributeNameParam
checkAttributeNameParam (HtmlAttribute k v) =
  if k == "class" then
    ClassParam
  else if k == "method" then
    FormMethodParam
  else if k == "preload" then
    PreloadValueParam
  else if k == "scope" then
    ScopeValueParam
  else if k == "step" then
    StepValueParam
  else if k `elem` defaultAttributeNameStringParams then
    StringParam
  else if k `elem` defaultAttributeNameBooleanParams then
    BooleanParam
  else if k `elem` defaultAttributeNameNumberParams then
    NumberParam
  else if k `elem` defaultAttributeNameIntParams then IntParam else CustomParam

defaultElementName :: Array String
defaultElementName =
  [ "a"
  , "abbr"
  , "address"
  , "area"
  , "article"
  , "aside"
  , "audio"
  , "b"
  , "base"
  , "bdi"
  , "bdo"
  , "quoteblock"
  , "body"
  , "br"
  , "button"
  , "canvas"
  , "caption"
  , "cite"
  , "code"
  , "col"
  , "colgroup"
  , "command"
  , "datalist"
  , "dd"
  , "del"
  , "details"
  , "dfn"
  , "dialog"
  , "div"
  , "dl"
  , "dt"
  , "em"
  , "embed"
  , "fieldset"
  , "figcaption"
  , "figure"
  , "footer"
  , "form"
  , "h1"
  , "h2"
  , "h3"
  , "h4"
  , "h5"
  , "h6"
  , "head"
  , "header"
  , "hr"
  , "html"
  , "i"
  , "iframe"
  , "img"
  , "input"
  , "ins"
  , "kbd"
  , "label"
  , "legend"
  , "li"
  , "link"
  , "main"
  , "map"
  , "mark"
  , "menu"
  , "menuitem"
  , "meta"
  , "meter"
  , "nav"
  , "noscript"
  , "object"
  , "ol"
  , "optGroup"
  , "option"
  , "output"
  , "p"
  , "param"
  , "pre"
  , "progress"
  , "q"
  , "rp"
  , "rt"
  , "ruby"
  , "smap"
  , "script"
  , "section"
  , "select"
  , "small"
  , "span"
  , "strong"
  , "style"
  , "sub"
  , "summary"
  , "sup"
  , "table"
  , "tbody"
  , "td"
  , "tfoot"
  , "th"
  , "thead"
  , "time"
  , "title"
  , "tr"
  , "u"
  , "ul"
  , "var"
  , "video"
  ]

defaultElementNameLeafs :: Array String
defaultElementNameLeafs =
  [ "area"
  , "base"
  , "br"
  , "canvas"
  , "col"
  , "command"
  , "hr"
  , "iframe"
  , "img"
  , "input"
  , "link"
  , "meta"
  , "param"
  , "source"
  , "texarea"
  , "track"
  , "wbr"
  ]

defaultAttributeNameStringParams :: Array String
defaultAttributeNameStringParams =
  [ "alt"
  , "charset"
  , "for"
  , "href"
  , "id"
  , "name"
  , "rel"
  , "src"
  , "style"
  , "target"
  , "title"
  , "download"
  , "action"
  , "value"
  , "placeholder"
  , "list"
  , "pattern"
  , "poster"
  ]

defaultAttributeNameBooleanParams :: Array String
defaultAttributeNameBooleanParams =
  [ "noValidate"
  , "disabled"
  , "enabled"
  , "required"
  , "readOnly"
  , "spellcheck"
  , "checked"
  , "selected"
  , "autocomplete"
  , "autofocus"
  , "multiple"
  , "autoplay"
  , "controls"
  , "loop"
  , "muted"
  , "draggable"
  ]

-- | Commented out because the values might be string in javascript
defaultAttributeNameNumberParams :: Array String
defaultAttributeNameNumberParams =
  [ --   "min"
    -- , "max"
  ]

-- | Commented out because the values might be string in javascript
defaultAttributeNameIntParams :: Array String
defaultAttributeNameIntParams =
  [ --   "cols"
    -- , "rows"
    -- , "colSpan"
    -- , "rowSpan"
    -- , "height"
    -- , "width"
    -- , "selectedIndex"
    -- , "tabIndex"
  ]
