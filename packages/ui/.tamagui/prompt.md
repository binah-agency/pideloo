# Tamagui Configuration

This document provides an overview of the Tamagui configuration for this project.

## Configuration Settings

**IMPORTANT:** These settings affect how you write Tamagui code in this project.

### Default Font: `body`

All text components will use the "body" font family by default.

### Web Container Type: `inline-size`

Enables web-specific container query optimizations.

## Shorthand Properties

These shorthand properties are available for styling:

- `ac` → `alignContent`
- `ai` → `alignItems`
- `als` → `alignSelf`
- `b` → `bottom`
- `bc` → `backgroundColor`
- `br` → `borderRadius`
- `f` → `flex`
- `fb` → `flexBasis`
- `fg` → `flexGrow`
- `fs` → `flexShrink`
- `fw` → `flexWrap`
- `h` → `height`
- `jc` → `justifyContent`
- `m` → `margin`
- `mb` → `marginBottom`
- `ml` → `marginLeft`
- `mr` → `marginRight`
- `mt` → `marginTop`
- `p` → `padding`
- `pb` → `paddingBottom`
- `pl` → `paddingLeft`
- `pos` → `position`
- `pr` → `paddingRight`
- `pt` → `paddingTop`
- `w` → `width`
- `zi` → `zIndex`

## Themes

Themes are organized hierarchically and can be combined:

**Level 1 (Base):**

- dark
- light

**Level 2 (Color Schemes):**

- purple

### Theme Usage

Themes are combined hierarchically. For example, `light_blue_alt1_Button` combines:
- Base: `light`
- Color: `blue`
- Variant: `alt1`
- Component: `Button`

**Basic usage:**

```tsx
// Apply a theme to components
export default () => (
  <Theme name="dark">
    <Button>I'm a dark button</Button>
  </Theme>
)

// Themes nest and combine automatically
export default () => (
  <Theme name="dark">
    <Theme name="blue">
      <Button>Uses dark_blue theme</Button>
    </Theme>
  </Theme>
)
```

**Accessing theme values:**

Components can access theme values using `$` token syntax:

```tsx
<View backgroundColor="$background" color="$color" />
```

**Special props:**

- `inverse`: Automatically swaps light ↔ dark themes
- `reset`: Reverts to grandparent theme

## Tokens

Tokens are design system values that can be referenced using the `$` prefix.

### Space Tokens

- `0`: 0
- `0.5`: 2
- `1`: 4
- `1.5`: 6
- `2`: 8
- `3`: 12
- `4`: 16
- `5`: 20
- `6`: 24
- `8`: 32
- `10`: 40
- `12`: 48
- `16`: 64
- `true`: 16

### Size Tokens

- `0`: 0
- `1`: 4
- `2`: 8
- `3`: 12
- `4`: 16
- `5`: 20
- `6`: 24
- `7`: 28
- `8`: 32
- `10`: 40
- `12`: 48
- `16`: 64
- `true`: 44

### Radius Tokens

- `0`: 0
- `1`: 4
- `2`: 8
- `3`: 12
- `4`: 16
- `8`: 32
- `full`: 9999
- `true`: 12

### Z-Index Tokens

- `0`: 0
- `1`: 100
- `2`: 200
- `3`: 300
- `4`: 400
- `5`: 500
- `modal`: 1000
- `overlay`: 900
- `tooltip`: 1100
- `true`: 0

### Color Tokens

- `background`: #050505
- `black`: #000000
- `border`: #191919
- `brand`: #8262ba
- `dark1`: #050505
- `dark2`: #111111
- `dark3`: #151515
- `dark4`: #191919
- `green`: #34c759
- `purple1`: #120d1d
- `purple7`: #6b4e9a
- `purple8`: #8262ba
- `purple9`: #9d81d4
- `red`: #ff3b30
- `white`: #ffffff
- `yellow`: #ffcc00

### Token Usage

Tokens can be used in component props with the `$` prefix:

```tsx
// Space tokens - for margin, padding, gap
<View padding="$4" gap="$2" margin="$3" />

// Size tokens - for width, height, dimensions
<View width="$10" height="$6" />

// Color tokens - for colors and backgrounds
<View backgroundColor="$blue5" color="$gray12" />

// Radius tokens - for border-radius
<View borderRadius="$4" />
```

## Media Queries

Available responsive breakpoints:

- **gtLg**: {"minWidth":1281}
- **gtMd**: {"minWidth":1021}
- **gtSm**: {"minWidth":801}
- **gtXl**: {"minWidth":1651}
- **gtXs**: {"minWidth":661}
- **lg**: {"maxWidth":1280}
- **md**: {"maxWidth":1020}
- **sm**: {"maxWidth":800}
- **xl**: {"maxWidth":1650}
- **xs**: {"maxWidth":660}
- **xxs**: {"maxWidth":390}

### Media Query Usage

Media queries can be used as style props or with the `useMedia` hook:

```tsx
// As style props (prefix with $)
<View width="100%" $gtLg={{ width: "50%" }} />

// Using the useMedia hook
const media = useMedia()
if (media.gtLg) {
  // Render for this breakpoint
}
```

## Fonts

Available font families:

- body

## Animations

Available animation presets:

- 0ms
- 100ms
- 200ms
- 250ms
- 300ms
- 30ms
- 400ms
- 500ms
- 50ms
- 75ms
- bouncy
- kindaBouncy
- lazy
- medium
- quick
- quickLessBouncy
- quicker
- quickerLessBouncy
- quickest
- quickestLessBouncy
- slow
- slowest
- superBouncy
- superLazy
- tooltip

## Components

The following components are available:

- AlertDialogAction
- AlertDialogCancel
- AlertDialogDescription
- AlertDialogDestructive
- AlertDialogOverlay
- AlertDialogTitle
- AlertDialogTrigger
- Anchor
- Article
- Aside
- AvatarFallback
  - AvatarFallback.Frame
- AvatarFrame
- Button
- Card
  - Card.Background
  - Card.Footer
  - Card.Frame
  - Card.Header
- Checkbox
  - Checkbox.Frame
  - Checkbox.IndicatorFrame
- Circle
- CollapsibleContent
  - CollapsibleContent.Frame
- CollapsibleTrigger
  - CollapsibleTrigger.Frame
- DialogClose
- DialogContent
- DialogDescription
- DialogOverlay
  - DialogOverlay.Frame
- DialogPortalFrame
- DialogTitle
- DialogTrigger
- Em
- EnsureFlexed
- Fieldset
- Footer
- Form
  - Form.Frame
  - Form.Trigger
- Frame
- Group
  - Group.Frame
- H1
- H2
- H3
- H4
- H5
- H6
- Handle
- Header
- Heading
- Image
- Input
- Label
  - Label.Frame
- ListItem
- Main
- Nav
- Overlay
- Paragraph
- PopoverArrow
- PopoverContent
- PopperAnchor
- PopperArrowFrame
- PopperContentFrame
- Progress
  - Progress.Frame
  - Progress.Indicator
  - Progress.IndicatorFrame
- RadioGroup
  - RadioGroup.Frame
  - RadioGroup.IndicatorFrame
  - RadioGroup.ItemFrame
- ScrollView
- Section
- SelectGroupFrame
- SelectIcon
- SelectSeparator
- Separator
- SizableStack
- SizableText
- SliderActiveFrame
- SliderFrame
- SliderThumb
  - SliderThumb.Frame
- SliderTrackFrame
- Spacer
- Span
- Spinner
- Square
- Strong
- Switch
  - Switch.Frame
  - Switch.Thumb
- Tabs
- Text
  - Text.Area
- ThemeableStack
- Thumb
- Toast
- View
- View
- VisuallyHidden
- XGroup
- XStack
- YGroup
- YStack
- ZStack

