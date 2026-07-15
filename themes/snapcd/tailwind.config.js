const colors = require('tailwindcss/colors')

const makePrimaryColor =
  l =>
    ({ opacityValue }) => {
      let result = "hsl(var(--primary-hue) var(--primary-saturation) ";
        if (l <= 50) {
          // Interpolate between lower values
          result+= `calc(calc(var(--primary-lightness) / 50) * ${l})`;
        }
        else {
          // Interpolate between higher values
          result+= `calc(var(--primary-lightness) + calc(calc(100% - var(--primary-lightness)) / 50) * ${l - 50})`;
        }

      result += (opacityValue ? ` / ${opacityValue})` : ')');
      return result;
    }

/** @type {import('tailwindcss').Config} */
module.exports = {
  prefix: 'hx-',
  // Tailwind purges any utility class it cannot find in `content`, so this list
  // has to cover every place a class can come from. Two sources, and both are
  // needed:
  //
  //  1. hugo_stats.json — the classes Hugo actually emitted. Hugo writes it to
  //     the root of the site being built, which is two levels up when
  //     `npm run build:css` runs from this theme directory.
  //
  //  2. The layouts themselves. hugo_stats.json only records classes on pages
  //     that were RENDERED, so a shortcode nobody has used yet (callout, icon,
  //     hero-headline …) contributes nothing — and Tailwind purges its styles.
  //     The first person to write {{< callout >}} in a doc would then get an
  //     unstyled box. Scanning the templates directly means a class is kept
  //     because it EXISTS in the markup, not because someone happened to use it.
  content: [
    '../../hugo_stats.json',   // the docs site (build:css runs from themes/snapcd)
    './**/hugo_stats.json',    // the theme standalone (npm run dev:theme)
    './layouts/**/*.html',     // latent markup: shortcodes/partials not yet used
  ],
  safelist: [
    'max-w-screen-xl',
    'max-w-[90rem]',
    'max-w-full'
  ],
  theme: {
    screens: {
      sm: '640px',
      md: '768px',
      lg: '1024px',
      xl: '1280px',
      '2xl': '1536px'
    },
    fontSize: {
      xs: '.75rem',
      sm: '.875rem',
      base: '1rem',
      lg: '1.125rem',
      xl: '1.25rem',
      '2xl': '1.5rem',
      '3xl': '1.875rem',
      '4xl': '2.25rem',
      '5xl': '3rem',
      '6xl': '4rem'
    },
    fontFamily: {
      sans: ['"Geist Sans"', 'system-ui', 'sans-serif'],
      mono: ['"Geist Mono"', 'ui-monospace', 'monospace'],
    },
    letterSpacing: {
      tight: '-0.015em'
    },
    colors: {
      transparent: 'transparent',
      current: 'currentColor',
      black: '#000',
      white: '#fff',
      gray: colors.gray,
      slate: colors.slate,
      neutral: colors.neutral,
      red: colors.red,
      orange: colors.orange,
      blue: colors.blue,
      yellow: colors.yellow,
      primary: {
        50: makePrimaryColor(97),
        100: makePrimaryColor(94),
        200: makePrimaryColor(86),
        300: makePrimaryColor(77),
        400: makePrimaryColor(66),
        500: makePrimaryColor(50),
        600: makePrimaryColor(45),
        700: makePrimaryColor(39),
        750: makePrimaryColor(35),
        800: makePrimaryColor(32),
        900: makePrimaryColor(24)
      }
    },
    extend: {
      colors: {
        dark: '#000000'
      }
    }
  },
  darkMode: ['class', 'html[class~="dark"]']
};
